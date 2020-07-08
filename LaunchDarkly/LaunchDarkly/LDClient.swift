//
//  LDClient.swift
//  LaunchDarkly
//
//  Copyright © 2017 Catamorphic Co. All rights reserved.
//

import Foundation

enum LDClientRunMode {
    case foreground, background
}

/**
 The LDClient is the heart of the SDK, providing client apps running iOS, watchOS, macOS, or tvOS access to LaunchDarkly services. This singleton provides the ability to set a configuration (LDConfig) that controls how the LDClient talks to LaunchDarkly servers, and a user (LDUser) that provides finer control on the feature flag values delivered to LDClient. Once the LDClient has started, it connects to LaunchDarkly's servers to get the feature flag values you set in the Dashboard.
## Usage
### Startup
 1. To customize, configure a `LDConfig` and `LDUser`. The `config` is required, the `user` is optional. Both give you additional control over the feature flags delivered to the LDClient. See `LDConfig` & `LDUser` for more details.
    - The mobileKey set into the `LDConfig` comes from your LaunchDarkly Account settings. If you have multiple projects be sure to choose the correct Mobile key.
 2. Call `LDClient.start(config: user: completion:)`
    - If you do not pass in a LDUser, LDCLient will create a default for you.
    - The optional completion closure allows the LDClient to notify your app when it received flag values.
 3. Because LDClient instances are stored statically, you do not have to keep a reference to it in your code. Get the primary instances with `LDClient.get()`

### Getting Feature Flags
 Once the LDClient has started, it makes your feature flags available using the `variation` and `variationDetail` methods. A `variation` is a specific flag value. For example a boolean feature flag has 2 variations, `true` and `false`. You can create feature flags with more than 2 variations using other feature flag types. See `LDFlagValue` for the available types.
 ````
 let boolFlag = LDClient.get()?.variation(forKey: "my-bool-flag", fallback: false)
 ````
 If you need to know more information about why a given value is returned, use `variationDetail`.

 See `variation(forKey: fallback:)` or `variationDetail(forKey: fallback:)` for details

### Observing Feature Flags
 You might need to know when a feature flag value changes. This is not required, you can check the flag's value when you need it.

 If you want to know when a feature flag value changes, you can check the flag's value. You can also use one of several `observe` methods to have the LDClient notify you when a change occurs. There are several options--you can set up notificiations based on when a specific flag changes, when any flag in a collection changes, or when a flag doesn't change.
 ````
 LDClient.get()?.observe("flag-key", owner: self, observer: { [weak self] (changedFlag) in
    self?.updateFlag(key: "flag-key", changedFlag: changedFlag)
 }
 ````
 The `changedFlag` passed in to the closure contains the old and new value of the flag.
 */
// swiftlint:disable type_body_length
// swiftlint:disable file_length
public class LDClient {

    // MARK: - State Controls and Indicators
    
    private static var instances: [String: LDClient]? = nil
    
    /**
     Reports the online/offline state of the LDClient.

     When online, the SDK communicates with LaunchDarkly servers for feature flag values and event reporting.

     When offline, the SDK does not attempt to communicate with LaunchDarkly servers. Client apps can request feature flag values and set/change feature flag observers while offline. The SDK will collect events while offline.

     Use `setOnline(_: completion:)` to change the online/offline state.
    */
    public private(set) var isOnline: Bool {
        get {
            isOnlineQueue.sync {
                _isOnline
            }
        }
        set {
            isOnlineQueue.sync {
                let oldValue = _isOnline
                _isOnline = newValue
                flagSynchronizer.isOnline = _isOnline
                eventReporter.isOnline = _isOnline
                diagnosticReporter.isOnline = _isOnline
                if _isOnline != oldValue {
                    connectionInformation = ConnectionInformation.onlineSetCheck(connectionInformation: connectionInformation, ldClient: self, config: config, online: _isOnline)
                }
            }
        }
    }

    private var _isOnline = false
    private var isOnlineQueue = DispatchQueue(label: "com.launchdarkly.LDClient.isOnlineQueue")

    // Stores ConnectionInformation in UserDefaults on change
    var connectionInformation: ConnectionInformation {
        didSet {
            Log.debug(connectionInformation.description)
            ConnectionInformationStore.storeConnectionInformation(connectionInformation: connectionInformation)
            if connectionInformation.currentConnectionMode != oldValue.currentConnectionMode {
                flagChangeNotifier.notifyConnectionModeChangedObservers(connectionMode: connectionInformation.currentConnectionMode)
            }
        }
    }

    // Returns an object containing information about successful and/or failed polling or streaming connections to LaunchDarkly
    public func getConnectionInformation() -> ConnectionInformation { connectionInformation }

    /**
     Set the LDClient online/offline.

     When online, the SDK communicates with LaunchDarkly servers for feature flag values and event reporting.

     When offline, the SDK does not attempt to communicate with LaunchDarkly servers. Client apps can request feature flag values and set/change feature flag observers while offline. The SDK will collect events while offline.

     The SDK protects itself from multiple rapid calls to setOnline(true) by enforcing an increasing delay (called *throttling*) each time setOnline(true) is called within a short time. The first time, the call proceeds normally. For each subsequent call the delay is enforced, and if waiting, increased to a maximum delay. When the delay has elapsed, the `setOnline(true)` will proceed, assuming that the client app has not called `setOnline(false)` during the delay. Therefore a call to setOnline(true) may not immediately result in the LDClient going online. Client app developers should consider this situation abnormal, and take steps to prevent the client app from making multiple rapid setOnline(true) calls. Calls to setOnline(false) are not throttled. Note that calls to `start(config: user: completion:)`, and setting the `config` or `user` can also call `setOnline(true)` under certain conditions. After the delay, the SDK resets and the client app can make a susequent call to setOnline(true) without being throttled.

     Client apps can set a completion closure called when the setOnline call completes. For unthrottled `setOnline(true)` and all `setOnline(false)` calls, the SDK will call the closure immediately on completion of this method. For throttled `setOnline(true)` calls, the SDK will call the closure after the throttling delay at the completion of the setOnline method.

     The SDK will not go online if the client has not been started, or the `mobileKey` is empty. For macOS, the SDK will not go online in the background unless `enableBackgroundUpdates` is true.

     Use `isOnline` to get the online/offline state.

     - parameter goOnline:    Desired online/offline mode for the LDClient
     - parameter completion:  Completion closure called when setOnline completes (Optional)
     */
    public func setOnline(_ goOnline: Bool, completion: (() -> Void)? = nil) {
        let dispatch = DispatchGroup()
        LDClient.instances?.forEach { _, instance in
            dispatch.enter()
            instance.internalSetOnline(goOnline, completion: dispatch.leave)
        }
        if let completion = completion {
            dispatch.notify(queue: DispatchQueue.global(), execute: completion)
        }
    }

    private func internalSetOnline(_ goOnline: Bool, completion: (() -> Void)? = nil) {
        internalSetOnlineQueue.sync {
            guard goOnline, self.canGoOnline
                else {
                    //go offline, which is not throttled
                    self.go(online: false, reasonOnlineUnavailable: self.reasonOnlineUnavailable(goOnline: goOnline), completion: completion)
                    return
            }

            self.throttler.runThrottled {
                //since going online was throttled, check the last called setOnline value and whether we can go online
                self.go(online: goOnline && self.canGoOnline, reasonOnlineUnavailable: self.reasonOnlineUnavailable(goOnline: goOnline), completion: completion)
            }
        }
    }

    private let internalSetOnlineQueue: DispatchQueue = DispatchQueue(label: "InternalSetOnlineQueue")
    
    private func go(online goOnline: Bool, reasonOnlineUnavailable: String, completion:(() -> Void)?) {
        let owner = "SetOnlineOwner" as AnyObject
        if completion != nil && !goOnline {
            completion?()
        } else if completion != nil {
            observeAll(owner: owner) { _ in
                completion?()
                self.stopObserving(owner: owner)
            }
            observeFlagsUnchanged(owner: owner) {
                completion?()
                self.stopObserving(owner: owner)
            }
        }
        isOnline = goOnline
        Log.debug(typeName(and: "setOnline", appending: ": ") + (reasonOnlineUnavailable.isEmpty ? "\(self.isOnline)." : "true aborted.") + reasonOnlineUnavailable)
    }

    private var canGoOnline: Bool {
        return hasStarted && isInSupportedRunMode && !config.mobileKey.isEmpty
    }

    var isInSupportedRunMode: Bool {
        return runMode == .foreground || config.enableBackgroundUpdates
    }

    private func reasonOnlineUnavailable(goOnline: Bool) -> String {
        if !goOnline {
            return ""
        }
        if !hasStarted {
            return " LDClient not started."
        }
        if !isInSupportedRunMode {
            return " LDConfig background updates not enabled."
        }
        if config.mobileKey.isEmpty {
            return " Mobile Key is empty."
        }
        return ""
    }

    /**
     The LDConfig that configures the LDClient. See `LDConfig` for details about what can be configured.

     Normally, the client app should set desired values into a LDConfig and pass that into `start(config: user: completion:)`. If the client does not pass a LDConfig to the LDClient, the LDClient creates a LDConfig using all default values.

     The client app can change the LDConfig by getting the `config`, adjusting the values, and setting it into the LDClient.

     When a new config is set, the LDClient goes offline and reconfigures using the new config. If the client was online when the new config was set, it goes online again, subject to a throttling delay if in force (see `setOnline(_: completion:)` for details). To change both the `config` and `user`, set the LDClient offline, set both properties, then set the LDClient online.
    */
    public private(set) var config: LDConfig {
        didSet {
            guard config != oldValue
            else {
                Log.debug(typeName(and: #function) + "aborted. New config matches old config")
                return
            }

            Log.level = environmentReporter.isDebugBuild && config.isDebugMode ? .debug : .noLogging
            Log.debug(typeName(and: #function) + "new config set")
            let wasOnline = isOnline
            internalSetOnline(false)
            cacheConverter.convertCacheData(for: user, and: config)
            if let cachedFlags = flagCache.retrieveFeatureFlags(forUserWithKey: user.key, andMobileKey: config.mobileKey), !cachedFlags.isEmpty {
                user.flagStore.replaceStore(newFlags: cachedFlags, completion: nil)
            }

            service = serviceFactory.makeDarklyServiceProvider(config: config, user: user)
            eventReporter.config = config

            internalSetOnline(wasOnline)
        }
    }

    public func setAllUserAttributesPrivate(_ allUserAttributesPrivate: Bool) {
        LDClient.instances?.forEach { $1.internalSetAllUserAttributesPrivate(allUserAttributesPrivate)}
    }

    private func internalSetAllUserAttributesPrivate(_ allUserAttributesPrivate: Bool) {
        self.config.allUserAttributesPrivate = allUserAttributesPrivate
    }
    
    private(set) var user: LDUser
    
    /**
     The LDUser set into the LDClient may affect the set of feature flags returned by the LaunchDarkly server, and ties event tracking to the user. See `LDUser` for details about what information can be retained.
     
     Normally, the client app should create and set the LDUser and pass that into `start(config: user: completion:)`.
     
     The client app can change the LDUser by getting the `user`, adjusting the values, and passing it to the LDClient method identify. This allows client apps to collect information over time from the user and update as information is collected. Client apps should follow [Apple's Privacy Policy](apple.com/legal/privacy) when collecting user information. If the client app does not create a LDUser, LDClient creates an anonymous default user, which can affect the feature flags delivered to the LDClient.
     
     When a new user is set, the LDClient goes offline and sets the new user. If the client was online when the new user was set, it goes online again, subject to a throttling delay if in force (see `setOnline(_: completion:)` for details). To change both the `config` and `user`, set the LDClient offline, set both properties, then set the LDClient online. A completion may be passed to the identify method to allow a client app to know when fresh flag values for the new user are ready.
     
     This operation is not thread safe. You may want to use a DispatchQueue if calling `identify` from multiple threads.
     
     - parameter user: The LDUser set with the desired user.
     - parameter completion: Closure called when the embedded `setOnlineIdentify` call completes, subject to throttling delays. (Optional)
    */
    public func identify(user: LDUser, completion: (() -> Void)? = nil) {
        let dispatch = DispatchGroup()
        LDClient.instances?.forEach { _, instance in
            dispatch.enter()
            instance.internalIdentify(newUser: user, completion: dispatch.leave)
        }
        if let completion = completion {
            dispatch.notify(queue: DispatchQueue.global(), execute: completion)
        }
    }

    func internalIdentify(newUser: LDUser, testing: Bool = false, completion: (() -> Void)? = nil) {
        internalIdentifyQueue.sync {
            var internalUser = newUser
            if !testing {
                internalUser.flagStore = FlagStore(featureFlagDictionary: newUser.flagStore.featureFlags)
            }
            self.user = internalUser
            Log.debug(self.typeName(and: #function) + "new user set with key: " + self.user.key )
            let wasOnline = self.isOnline
            self.internalSetOnline(false)

            cacheConverter.convertCacheData(for: user, and: config)
            if let cachedFlags = self.flagCache.retrieveFeatureFlags(forUserWithKey: self.user.key, andMobileKey: self.config.mobileKey), !cachedFlags.isEmpty {
                self.user.flagStore.replaceStore(newFlags: cachedFlags, completion: nil)
            }
            self.service = self.serviceFactory.makeDarklyServiceProvider(config: self.config, user: self.user)
            self.service.clearFlagResponseCache()

            if self.hasStarted {
                self.eventReporter.record(Event.identifyEvent(user: self.user))
            }

            self.internalSetOnline(wasOnline, completion: completion)
        }
    }
    
    private let internalIdentifyQueue: DispatchQueue = DispatchQueue(label: "InternalIdentifyQueue")

    private(set) var service: DarklyServiceProvider {
        didSet {
            Log.debug(typeName(and: #function) + "new service set")
            eventReporter.service = service
            diagnosticReporter.service = service
            flagSynchronizer = serviceFactory.makeFlagSynchronizer(streamingMode: ConnectionInformation.effectiveStreamingMode(config: config, ldClient: self),
                                                                   pollingInterval: config.flagPollingInterval(runMode: runMode),
                                                                   useReport: config.useReport,
                                                                   service: service,
                                                                   onSyncComplete: onFlagSyncComplete)
        }
    }

    /**
     Stops the LDClient. Stopping the client means the LDClient goes offline and stops recording events. LDClient will no longer provide feature flag values, only returning fallback values.

     There is almost no reason to stop the LDClient. Normally, set the LDClient offline to stop communication with the LaunchDarkly servers. Stop the LDClient to stop recording events. There is no need to stop the LDClient prior to suspending, moving to the background, or terminating the app. The SDK will respond to these events as the system requires and as configured in LDConfig.
    */
    public func close() {
        LDClient.instances?.forEach { $1.internalClose() }
        LDClient.instances = nil
    }
    
    private func internalClose() {
        Log.debug(typeName(and: #function, appending: "- ") + "stopping")
        internalFlush()
        internalSetOnline(false)
        hasStarted = false
        Log.debug(typeName(and: #function, appending: "- ") + "stopped")
    }
    
    /**
     Returns the singleton instance.
     
     - returns: The primary LDClient instance.
     */
    public static func get() -> LDClient? {
        guard let internalInstances = LDClient.instances else {
            Log.debug("LDClient.get() was called before init()!")
            return nil
        }
        return internalInstances[LDConfig.Defaults.primaryEnvironmentName]
    }
    
    /**
     Returns all environment names.
     
     - returns: All environment names as an Array of Strings.
    */
    public static func getEnvironmentNames() -> [String]? {
        guard let internalInstances = LDClient.instances else {
            Log.debug("LDClient.getEnvironmentNames() was called before init()!")
            return nil
        }
        return Array(internalInstances.keys)
    }
    
    /**
     Returns an instance of LDClient for the given environment name.
     
     - parameter keyName: An environment name provided in LDConfig.secondaryMobileKeys during initialization.
     
     - returns: An LDClient instance if one exists and `start(config: user: completion:)` has been called.
     */
    public static func getForMobileKey(keyName: String) -> LDClient? {
        return LDClient.instances?[keyName]
    }
    
    // MARK: Feature Flag values
    
    /* FF Value Requests
     Conceptual Model
     The LDClient is the focal point for flag value requests. It should appear to the app that the client contains a store of [key: value] pairs where the keys are all strings and the values any of the supported LD flag types (Bool, Int, Double, String, Array, Dictionary).
     When asked for a variation value, the LDClient provides either the value, or the value along with an explanation.
    */
    
    /**
     Returns the variation for the given feature flag. If the flag does not exist, cannot be cast to the correct return type, or the LDClient is not started, returns the fallback value. Use this method when the fallback value is a non-Optional type. See `variation` with the Optional return value when the fallback value can be nil.

     A *variation* is a specific flag value. For example a boolean feature flag has 2 variations, *true* and *false*. You can create feature flags with more than 2 variations using other feature flag types. See `LDFlagValue` for the available types.

     The LDClient must be started in order to return feature flag values. If the LDClient is not started, it will always return the fallback value. The LDClient must be online to keep the feature flag values up-to-date.

     When online, the LDClient has two modes for maintaining feature flag values: *streaming* and *polling*. The client app requests the mode by setting the `config.streamingMode`, see `LDConfig` for details.
     - In streaming mode, the LDClient opens a long-running connection to LaunchDarkly's streaming server (called *clientstream*). When a flag value changes on the server, the clientstream notifies the SDK to update the value. Streaming mode is not available on watchOS. On iOS and tvOS, the client app must be running in the foreground to connect to clientstream. On macOS the client app may run in either foreground or background to connect to clientstream. If streaming mode is not available, the SDK reverts to polling mode.
     - In polling mode, the LDClient requests feature flags from LaunchDarkly's app server at regular intervals defined in the LDConfig. When a flag value changes on the server, the LDClient will learn of the change the next time the SDK requests feature flags.

     When offline, LDClient closes the clientstream connection and no longer requests feature flags. The LDClient will return feature flag values (assuming the LDClient was started), which may not match the values set on the LaunchDarkly server.

     A call to `variation` records events reported later. Recorded events allow clients to analyze usage and assist in debugging issues.

     ### Usage
     ````
     let boolFeatureFlagValue = LDClient.get()!.variation(forKey: "bool-flag-key", fallback: false) //boolFeatureFlagValue is a Bool
     ````
     **Important** The fallback value tells the SDK the type of the feature flag. In several cases, the feature flag type cannot be determined by the values sent from the server. It is possible to provide a fallback value with a type that does not match the feature flag value's type. The SDK will attempt to convert the feature flag's value into the type of the fallback value in the variation request. If that cast fails, the SDK will not be able to determine the correct return type, and will always return the fallback value.

     Pay close attention to the type of the fallback value for collections. If the fallback collection type is more restrictive than the feature flag, the sdk will return the fallback even though the feature flag is present because it cannot convert the feature flag into the type requested via the fallback value. For example, if the feature flag has the type `[String: Any]`, but the fallback has the type `[String: Int]`, the sdk will not be able to convert the flags into the requested type, and will return the fallback value.

     To avoid this, make sure the fallback type matches the expected feature flag type. Either specify the fallback value type to be the feature flag type, or cast the fallback value to the feature flag type prior to making the variation request. In the above example, either specify that the fallback value's type is [String: Any]:
     ````
     let fallbackValue: [String: Any] = ["a": 1, "b": 2]     //dictionary type would be [String: Int] without the type specifier
     ````
     or cast the fallback value into the feature flag type prior to calling variation:
     ````
     let dictionaryFlagValue = LDClient.get()!.variation(forKey: "dictionary-key", fallback: ["a": 1, "b": 2] as [String: Any])
     ````

     - parameter forKey: The LDFlagKey for the requested feature flag.
     - parameter fallback: The fallback value to return if the feature flag key does not exist.

     - returns: The requested feature flag value, or the fallback if the flag is missing or cannot be cast to the fallback type, or the client is not started
    */
    /// - Tag: variationWithFallback
    public func variation<T: LDFlagValueConvertible>(forKey flagKey: LDFlagKey, fallback: T) -> T {
        //the fallback cast to 'as T?' directs the call to the Optional-returning variation method
        variation(forKey: flagKey, fallback: fallback as T?) ?? fallback
    }
    
    /**
     Returns the EvaluationDetail for the given feature flag. EvaluationDetail gives you more insight into why your variation contains the specified value. If the flag does not exist, cannot be cast to the correct return type, or the LDClient is not started, returns EvaluationDetail with the fallback value. Use this method when the fallback value is a non-Optional type. See `variationDetail` with the Optional return value when the fallback value can be nil. See [variationWithFallback](x-source-tag://variationWithFallback)
     
     - parameter forKey: The LDFlagKey for the requested feature flag.
     - parameter fallback: The fallback value to return if the feature flag key does not exist.
     
     - returns: EvaluationDetail which wraps the requested feature flag value, or the fallback, which variation was served, and the evaluation reason.
     */
    public func variationDetail<T: LDFlagValueConvertible>(forKey flagKey: LDFlagKey, fallback: T) -> EvaluationDetail<T> {
        let featureFlag = user.flagStore.featureFlag(for: flagKey)
        let reason = checkErrorKinds(featureFlag: featureFlag) ?? featureFlag?.reason
        let value = variationInternal(forKey: flagKey, fallback: fallback, includeReason: true)
        return EvaluationDetail(value: value ?? fallback, variationIndex: featureFlag?.variation, reason: reason)
    }
    
    private func checkErrorKinds(featureFlag: FeatureFlag?) -> Dictionary<String, Any>? {
        if !hasStarted {
            return ["kind": "ERROR", "errorKind": "CLIENT_NOT_READY"]
        } else if featureFlag == nil {
            return ["kind": "ERROR", "errorKind": "FLAG_NOT_FOUND"]
        } else {
            return nil
        }
    }

    /**
     Returns the variation for the given feature flag. If the flag does not exist, cannot be cast to the correct return type, or the LDClient is not started, returns the fallback value, which may be `nil`. Use this method when the fallback value is an Optional type. See `variation` with the non-Optional return value when the fallback value cannot be nil.

     A *variation* is a specific flag value. For example a boolean feature flag has 2 variations, *true* and *false*. You can create feature flags with more than 2 variations using other feature flag types. See `LDFlagValue` for the available types.

     The LDClient must be started in order to return feature flag values. If the LDClient is not started, it will always return the fallback value. The LDClient must be online to keep the feature flag values up-to-date.

     When online, the LDClient has two modes for maintaining feature flag values: *streaming* and *polling*. The client app requests the mode by setting the `config.streamingMode`, see `LDConfig` for details.
     - In streaming mode, the LDClient opens a long-running connection to LaunchDarkly's streaming server (called *clientstream*). When a flag value changes on the server, the clientstream notifies the SDK to update the value. Streaming mode is not available on watchOS. On iOS and tvOS, the client app must be running in the foreground to connect to clientstream. On macOS the client app may run in either foreground or background to connect to clientstream. If streaming mode is not available, the SDK reverts to polling mode.
     - In polling mode, the LDClient requests feature flags from LaunchDarkly's app server at regular intervals defined in the LDConfig. When a flag value changes on the server, the LDClient will learn of the change the next time the SDK requests feature flags.

     When offline, LDClient closes the clientstream connection and no longer requests feature flags. The LDClient will return feature flag values (assuming the LDClient was started), which may not match the values set on the LaunchDarkly server.

     A call to `variation` records events reported later. Recorded events allow clients to analyze usage and assist in debugging issues.

     ### Usage
     ````
     let boolFeatureFlagValue: Bool? = LDClient.get()!.variation(forKey: "bool-flag-key", fallback: nil) //boolFeatureFlagValue is a Bool?
     ````
     **Important** The fallback value tells the SDK the type of the feature flag. In several cases, the feature flag type cannot be determined by the values sent from the server. It is possible to provide a fallback value with a type that does not match the feature flag value's type. The SDK will attempt to convert the feature flag's value into the type of the fallback value in the variation request. If that cast fails, the SDK will not be able to determine the correct return type, and will always return the fallback value.

     When specifying `nil` as the fallback value, the compiler must also know the type of the optional. Without this information, the compiler will give the error "'nil' requires a contextual type". There are several ways to provide this information, by setting the type on the item holding the return value, by casting the return value to the desired type, or by casting `nil` to the desired type. We recommend following the above example and setting the type on the return value item.

     For this method, the fallback value is defaulted to `nil`, allowing the call site to omit the fallback value.

     Pay close attention to the type of the fallback value for collections. If the fallback collection type is more restrictive than the feature flag, the sdk will return the fallback even though the feature flag is present because it cannot convert the feature flag into the type requested via the fallback value. For example, if the feature flag has the type `[String: Any]`, but the fallback has the type `[String: Int]`, the sdk will not be able to convert the flags into the requested type, and will return the fallback value.

     To avoid this, make sure the fallback type matches the expected feature flag type. Either specify the fallback value type to be the feature flag type, or cast the fallback value to the feature flag type prior to making the variation request. In the above example, either specify that the fallback value's type is [String: Any]:
     ````
     let fallbackValue: [String: Any]? = ["a": 1, "b": 2]     //dictionary type would be [String: Int] without the type specifier
     ````
     or cast the fallback value into the feature flag type prior to calling variation:
     ````
     let dictionaryFlagValue = LDClient.get()!.variation(forKey: "dictionary-key", fallback: ["a": 1, "b": 2] as [String: Any]?)
     ````

     - parameter forKey: The LDFlagKey for the requested feature flag.
     - parameter fallback: The fallback value to return if the feature flag key does not exist. If omitted, the fallback value is `nil`. (Optional)

     - returns: The requested feature flag value, or the fallback if the flag is missing or cannot be cast to the fallback type, or the client is not started
     */
    /// - Tag: variationWithoutFallback
    public func variation<T: LDFlagValueConvertible>(forKey flagKey: LDFlagKey, fallback: T? = nil) -> T? {
        variationInternal(forKey: flagKey, fallback: fallback, includeReason: false)
    }
    
    /**
     Returns the EvaluationDetail for the given feature flag. EvaluationDetail gives you more insight into why your variation contains the specified value. If the flag does not exist, cannot be cast to the correct return type, or the LDClient is not started, returns EvaluationDetail with the fallback value, which may be `nil`. Use this method when the fallback value is a Optional type. See [variationWithoutFallback](x-source-tag://variationWithoutFallback)
     
     - parameter forKey: The LDFlagKey for the requested feature flag.
     - parameter fallback: The fallback value to return if the feature flag key does not exist. If omitted, the fallback value is `nil`. (Optional)
     
     - returns: EvaluationDetail which wraps the requested feature flag value, or the fallback, which variation was served, and the evaluation reason.
     */
    public func variationDetail<T: LDFlagValueConvertible>(forKey flagKey: LDFlagKey, fallback: T? = nil) -> EvaluationDetail<T?> {
        let featureFlag = user.flagStore.featureFlag(for: flagKey)
        let reason = checkErrorKinds(featureFlag: featureFlag) ?? featureFlag?.reason
        let value = variationInternal(forKey: flagKey, fallback: fallback, includeReason: true)
        return EvaluationDetail(value: value, variationIndex: featureFlag?.variation, reason: reason)
    }
    
    internal func variationInternal<T: LDFlagValueConvertible>(forKey flagKey: LDFlagKey, fallback: T) -> T {
        //Because the fallback is wrapped into an Optional, the nil coalescing right side should never be called
        variationInternal(forKey: flagKey, fallback: fallback as T?, includeReason: false) ?? fallback
    }
    
    internal func variationInternal<T: LDFlagValueConvertible>(forKey flagKey: LDFlagKey, fallback: T? = nil, includeReason: Bool? = false) -> T? {
        guard hasStarted
        else {
            Log.debug(typeName(and: #function) + "returning fallback: \(fallback.stringValue)." + " LDClient not started.")
            return fallback
        }
        let featureFlag = user.flagStore.featureFlag(for: flagKey)
        let value = (featureFlag?.value as? T) ?? fallback
        let failedConversionMessage = self.failedConversionMessage(featureFlag: featureFlag, fallback: fallback)
        Log.debug(typeName(and: #function) + "flagKey: \(flagKey), value: \(value.stringValue), fallback: \(fallback.stringValue), featureFlag: \(featureFlag.stringValue), reason: \(featureFlag?.reason?.description ?? "No evaluation reason")."
            + "\(failedConversionMessage)")
        eventReporter.recordFlagEvaluationEvents(flagKey: flagKey, value: value, defaultValue: fallback, featureFlag: featureFlag, user: user, includeReason: includeReason ?? false)
        return value
    }

    private func failedConversionMessage<T>(featureFlag: FeatureFlag?, fallback: T?) -> String {
        if featureFlag == nil {
            return " Feature flag not found."
        }
        if featureFlag?.value is T {
            return ""
        }
        return " LDClient was unable to convert the feature flag to the requested type (\(T.self))."
            + (isCollection(fallback) ? " The fallback value type is a collection. Make sure the element of the fallback value's type is not too restrictive for the actual feature flag type." : "")
    }
    
    private func isCollection<T>(_ object: T) -> Bool {
        let collectionsTypes = ["Set", "Array", "Dictionary"]
        let typeString = String(describing: type(of: object))

        for type in collectionsTypes {
            if typeString.contains(type) { return true }
        }
        return false
    }

    /**
     Returns a dictionary with the flag keys and their values. If the LDClient is not started, returns nil.

     The dictionary will not contain feature flags from the server with null values.

     LDClient will not provide any source or change information, only flag keys and flag values. The client app should convert the feature flag value into the desired type.
    */
    public var allFlags: [LDFlagKey: Any]? {
        guard hasStarted
        else {
            return nil
        }
        return user.flagStore.featureFlags.allFlagValues
    }

    // MARK: Feature Flag Updates
    
    /* FF Change Notification
     Conceptual Model
     LDClient keeps a list of two types of closure observers, either Flag Change Observers or Flags Unchanged Observers.
     There are 3 types of Flag Change Observers, Individual Flag Change Observers, Flag Collection Change Observers, and All Flags Change Observers. LDClient executes Individual Flag observers when it detects a change to a single flag being observed. LDClient executes Flag Collection Change Observers one time when it detects a change to any flag in the observed flag collection. LDClient executes All Flags observers one time when it detects a change to any flag. The Individual Flag Change Observer has closure that takes a LDChangedFlag input parameter which communicates the flag's old & new value. Flag Collection and All Flags Observers will have a closure that takes a dictionary of [LDFlagKey: LDChangeFlag] that communicates all of the changed flags.
     An app registers an Individual Flag observer using observe(key:, owner:, handler:). An app registers a Flag Collection Observer using observe(keys: owner: handler), An app registers an All Flags observer using observeAll(owner:, handler:). An app can register multiple closures for each type by calling these methods multiple times. When the value of a flag changes, LDClient calls each registered closure 1 time.
     Flags Unchanged Observers allow the LDClient to communicate to the app when it receives flags from the LD server that doesn't change any values from what the LDClient had already. For example, at launch the LDClient restores cached flag values before requesting flags from the LD server. If there has been no change to the flag values, the LDClient will execute the Flags Unchanged Observers that the app has registered. An app registers a Flags Unchanged Observer using observeFlagsUnchanged(owner: handler:).
     LDClient will automatically remove observers when the owner is nil. This means an app does not need to stop observing flags, the LDClient will remove the observer after it has gone out of scope. An app can stop observers explicitly using stopObserver(owner:).
     LDClient executes observers on the main thread.
    */
    
    /**
     Sets a handler for the specified flag key executed on the specified owner. If the flag's value changes, executes the handler, passing in the `changedFlag` containing the old and new flag values. See `LDChangedFlag` for details.

     The SDK retains only weak references to the owner, which allows the client app to freely destroy observer owners without issues. Client apps should use a capture list specifying `[weak self]` inside handlers to avoid retain cycles causing a memory leak.

     The SDK executes handlers on the main thread.

     LDChangedFlag does not know the type of oldValue or newValue. The client app should cast the value into the type needed. See `variation(forKey: fallback:)` for details about the SDK and feature flag types.

     SeeAlso: `LDChangedFlag` and `stopObserving(owner:)`

     ### Usage
     ````
     LDClient.get()?.observe("flag-key", owner: self) { [weak self] (changedFlag) in
        if let newValue = changedFlag.newValue as? Bool {
            //do something with the newValue
        }
     ````

     - parameter key: The LDFlagKey for the flag to observe.
     - parameter owner: The LDObserverOwner which will execute the handler. The SDK retains a weak reference to the owner.
     - parameter handler: The closure the SDK will execute when the feature flag changes.
    */
    public func observe(key: LDFlagKey, owner: LDObserverOwner, handler: @escaping LDFlagChangeHandler) {
        Log.debug(typeName(and: #function) + "flagKey: \(key), owner: \(String(describing: owner))")
        flagChangeNotifier.addFlagChangeObserver(FlagChangeObserver(key: key, owner: owner, flagChangeHandler: handler))
    }
    
    /**
     Sets a handler for the specified flag keys executed on the specified owner. If any observed flag's value changes, executes the handler 1 time, passing in a dictionary of [LDFlagKey: LDChangedFlag] containing the old and new flag values. See `LDChangedFlag` for details.

     The SDK retains only weak references to owner, which allows the client app to freely destroy observer owners without issues. Client apps should use a capture list specifying `[weak self]` inside handlers to avoid retain cycles causing a memory leak.

     The SDK executes handlers on the main thread.

     LDChangedFlag does not know the type of oldValue or newValue. The client app should cast the value into the type needed. See `variation(forKey: fallback:)` for details about the SDK and feature flag types.

     SeeAlso: `LDChangedFlag` and `stopObserving(owner:)`

     ### Usage
     ````
     LDClient.get()?.observe(flagKeys, owner: self) { [weak self] (changedFlags) in     // changedFlags is a [LDFlagKey: LDChangedFlag]
        //There will be an LDChangedFlag entry in changedFlags for each changed flag. The closure will only be called once regardless of how many flags changed.
        if let someChangedFlag = changedFlags["some-flag-key"] {    // someChangedFlag is a LDChangedFlag
            //do something with someChangedFlag
         }
     }
     ````

     - parameter keys: An array of LDFlagKeys for the flags to observe.
     - parameter owner: The LDObserverOwner which will execute the handler. The SDK retains a weak reference to the owner.
     - parameter handler: The LDFlagCollectionChangeHandler the SDK will execute 1 time when any of the observed feature flags change.
     */
    public func observe(keys: [LDFlagKey], owner: LDObserverOwner, handler: @escaping LDFlagCollectionChangeHandler) {
        Log.debug(typeName(and: #function) + "flagKeys: \(keys), owner: \(String(describing: owner))")
        flagChangeNotifier.addFlagChangeObserver(FlagChangeObserver(keys: keys, owner: owner, flagCollectionChangeHandler: handler))
    }

    /**
     Sets a handler for all flag keys executed on the specified owner. If any flag's value changes, executes the handler 1 time, passing in a dictionary of [LDFlagKey: LDChangedFlag] containing the old and new flag values. See `LDChangedFlag` for details.

     The SDK retains only weak references to owner, which allows the client app to freely destroy observer owners without issues. Client apps should use a capture list specifying `[weak self]` inside handlers to avoid retain cycles causing a memory leak.

     The SDK executes handlers on the main thread.

     LDChangedFlag does not know the type of oldValue or newValue. The client app should cast the value into the type needed. See `variation(forKey: fallback:)` for details about the SDK and feature flag types.

     SeeAlso: `LDChangedFlag` and `stopObserving(owner:)`

     ### Usage
     ````
     LDClient.get()?.observeAll(owner: self) { [weak self] (changedFlags) in     // changedFlags is a [LDFlagKey: LDChangedFlag]
        //There will be an LDChangedFlag entry in changedFlags for each changed flag. The closure will only be called once regardless of how many flags changed.
        if let someChangedFlag = changedFlags["some-flag-key"] {    // someChangedFlag is a LDChangedFlag
            //do something with someChangedFlag
        }
     }
     ````

     - parameter owner: The LDObserverOwner which will execute the handler. The SDK retains a weak reference to the owner.
     - parameter handler: The LDFlagCollectionChangeHandler the SDK will execute 1 time when any of the observed feature flags change.
     */
    public func observeAll(owner: LDObserverOwner, handler: @escaping LDFlagCollectionChangeHandler) {
        Log.debug(typeName(and: #function) + " owner: \(String(describing: owner))")
        flagChangeNotifier.addFlagChangeObserver(FlagChangeObserver(keys: LDFlagKey.anyKey, owner: owner, flagCollectionChangeHandler: handler))
    }
    
    /**
     Sets a handler executed when a flag update leaves the flags unchanged from their previous values.

     This handler can only ever be called when the LDClient is polling.

     The SDK retains only weak references to owner, which allows the client app to freely destroy observer owners without issues. Client apps should use a capture list specifying `[weak self]` inside handlers to avoid retain cycles causing a memory leak.

     The SDK executes handlers on the main thread.

     SeeAlso: `stopObserving(owner:)`

     ### Usage
     ````
     LDClient.get()?.observeFlagsUnchanged(owner: self) { [weak self] in
         // Do something after an update was received that did not update any flag values.
         //The closure will be called once on the main thread after the update.
     }
     ````

     - parameter owner: The LDObserverOwner which will execute the handler. The SDK retains a weak reference to the owner.
     - parameter handler: The LDFlagsUnchangedHandler the SDK will execute 1 time when a flag request completes with no flags changed.
     */
    public func observeFlagsUnchanged(owner: LDObserverOwner, handler: @escaping LDFlagsUnchangedHandler) {
        Log.debug(typeName(and: #function) + " owner: \(String(describing: owner))")
        flagChangeNotifier.addFlagsUnchangedObserver(FlagsUnchangedObserver(owner: owner, flagsUnchangedHandler: handler))
    }
    
    /**
     Sets a handler executed when ConnectionInformation.currentConnectionMode changes.
     
     The SDK retains only weak references to owner, which allows the client app to freely destroy change owners without issues. Client apps should use a capture list specifying `[weak self]` inside handlers to avoid retain cycles causing a memory leak.
     
     The SDK executes handlers on the main thread.
     
     SeeAlso: `stopObserving(owner:)`
     
     ### Usage
     ````
     LDClient.get()?.observeCurrentConnectionMode(owner: self) { [weak self] in
        //do something after ConnectionMode was updated.
     }
     ````
     
     - parameter owner: The LDObserverOwner which will execute the handler. The SDK retains a weak reference to the owner.
     - parameter handler: The LDConnectionModeChangedHandler the SDK will execute 1 time when ConnectionInformation.currentConnectionMode is changed.
     */
    public func observeCurrentConnectionMode(owner: LDObserverOwner, handler: @escaping LDConnectionModeChangedHandler) {
        Log.debug(typeName(and: #function) + " owner: \(String(describing: owner))")
        flagChangeNotifier.addConnectionModeChangedObserver(ConnectionModeChangedObserver(owner: owner, connectionModeChangedHandler: handler))
    }

    /**
     Removes all observers for the given owner, including the flagsUnchangedObserver

     The client app does not have to call this method. If the client app deinits a LDFlagChangeOwner, the SDK will automatically remove its handlers without ever calling them again.

     - parameter owner: The LDFlagChangeOwner owning the handlers to remove, whether a flag change handler or flags unchanged handler.
    */
    public func stopObserving(owner: LDObserverOwner) {
        Log.debug(typeName(and: #function) + " owner: \(String(describing: owner))")
        flagChangeNotifier.removeObserver(owner: owner)
        errorNotifier.removeObservers(for: owner)
    }

    private(set) var errorNotifier: ErrorNotifying

    public func observeError(owner: LDObserverOwner, handler: @escaping LDErrorHandler) {
        Log.debug(typeName(and: #function) + " owner: \(String(describing: owner))")
        errorNotifier.addErrorObserver(ErrorObserver(owner: owner, errorHandler: handler))
    }

    private func onFlagSyncComplete(result: FlagSyncResult) {
        Log.debug(typeName(and: #function) + "result: \(result)")
        switch result {
        case let .success(flagDictionary, streamingEvent):
            let oldFlags = user.flagStore.featureFlags
            connectionInformation = ConnectionInformation.checkEstablishingStreaming(connectionInformation: connectionInformation)
            switch streamingEvent {
            case nil, .ping?, .put?:
                user.flagStore.replaceStore(newFlags: flagDictionary) {
                    self.updateCacheAndReportChanges(user: self.user, oldFlags: oldFlags)
                }
            case .patch?:
                user.flagStore.updateStore(updateDictionary: flagDictionary) {
                    self.updateCacheAndReportChanges(user: self.user, oldFlags: oldFlags)
                }
            case .delete?:
                user.flagStore.deleteFlag(deleteDictionary: flagDictionary) {
                    self.updateCacheAndReportChanges(user: self.user, oldFlags: oldFlags)
                }
            }
        case .error(let synchronizingError):
            process(synchronizingError, logPrefix: typeName(and: #function, appending: ": "))
        }
    }

    private func process(_ synchronizingError: SynchronizingError, logPrefix: String) {
        if synchronizingError.isClientUnauthorized {
            Log.debug(logPrefix + "LDClient is unauthorized")
            internalSetOnline(false)
        }
        connectionInformation = ConnectionInformation.synchronizingErrorCheck(synchronizingError: synchronizingError, connectionInformation: connectionInformation)
        DispatchQueue.main.async {
            self.errorNotifier.notifyObservers(of: synchronizingError)
        }
    }

    private func updateCacheAndReportChanges(user: LDUser,
                                             oldFlags: [LDFlagKey: FeatureFlag]) {
        flagCache.storeFeatureFlags(user.flagStore.featureFlags, forUser: user, andMobileKey: config.mobileKey, lastUpdated: Date(), storeMode: .async)
        flagChangeNotifier.notifyObservers(user: user, oldFlags: oldFlags)
    }

    // MARK: - Events

    /* Event tracking
     Conceptual model
     The LDClient appears to keep an event store that it transmits periodically to LD. An app sends an event and optional data by calling trackEvent(key:, data:) supplying at least the key.
     */

    /**
     Adds a custom event to the LDClient event store. A client app can set a tracking event to allow client customized data analysis. Once an app has called `trackEvent`, the app cannot remove the event from the event store.

     LDClient periodically transmits events to LaunchDarkly based on the frequency set in LDConfig.eventFlushInterval. The LDClient must be started and online. Ths SDK stores events tracked while the LDClient is offline, but started.

     Once the SDK's event store is full, the SDK discards events until they can be reported to LaunchDarkly. Configure the size of the event store using `eventCapacity` on the `config`. See `LDConfig` for details.

     ### Usage
     ````
     let appEventData = ["some-custom-key: "some-custom-value", "another-custom-key": 7]
     LDClient.get()?.trackEvent(key: "app-event-key", data: appEventData)
     ````

     - parameter key: The key for the event. The SDK does nothing with the key, which can be any string the client app sends
     - parameter data: The data for the event. The SDK does nothing with the data, which can be any valid JSON item the client app sends. (Optional)
     - parameter metricValue: A numeric value used by the LaunchDarkly experimentation feature in numeric custom metrics. Can be omitted if this event is used by only non-numeric metrics. This field will also be returned as part of the custom event for Data Export. (Optional)

     - throws: JSONSerialization.JSONError.invalidJsonObject if the data is not a valid JSON item
    */
    public func trackEvent(key: String, data: Any? = nil, metricValue: Double? = nil) throws {
        guard hasStarted
        else {
            Log.debug(typeName(and: #function) + "aborted. LDClient not started")
            return
        }
        let event = try Event.customEvent(key: key, user: user, data: data, metricValue: metricValue)
        Log.debug(typeName(and: #function) + "event: \(event), data: \(String(describing: data)), metricValue: \(String(describing: metricValue))")
        eventReporter.record(event)
    }

    /**
    Report events to LaunchDarkly servers. While online, the LDClient automatically reports events on the `LDConfig.eventFlushInterval`, and whenever the client app moves to the background. There should normally not be a need to call reportEvents.
    */
    public func flush() {
        LDClient.instances?.forEach { $1.internalFlush() }
    }
    
    private func internalFlush() {
        eventReporter.flush(completion: nil)
    }

    private func onEventSyncComplete(result: EventSyncResult) {
        Log.debug(typeName(and: #function) + "result: \(result)")
        switch result {
        case .success:
            break   //EventReporter handles removing events from the event store, so there's nothing to do here. It's here in case we want to do something in the future.
        case .error(let synchronizingError):
            process(synchronizingError, logPrefix: typeName(and: #function, appending: ": "))
        }
    }
    
    @objc private func didCloseEventSource() {
        Log.debug(typeName(and: #function))
        self.connectionInformation = ConnectionInformation.lastSuccessfulConnectionCheck(connectionInformation: self.connectionInformation)
    }

    // MARK: - Foreground / Background notification

    @objc private func didEnterBackground() {
        Log.debug(typeName(and: #function))
        Thread.performOnMain {
            runMode = .background
        }
    }

    @objc private func willEnterForeground() {
        Log.debug(typeName(and: #function))
        Thread.performOnMain {
            runMode = .foreground
        }
    }
    
    /**
     Starts the LDClient using the passed in `config` & `user`. Call this before requesting feature flag values. The LDClient will not go online until you call this method.
     Starting the LDClient means setting the `config` & `user`, setting the client online if `config.startOnline` is true (the default setting), and starting event recording. The client app must start the LDClient before it will report feature flag values. If a client does not call init, the LDClient will only report fallback values, and no events will be recorded.
     If the init call omits the `user`, the LDClient uses the previously set `user`, or the default `user` if it was never set.
     If theinit call includes the optional `completion` closure, LDClient calls the `completion` closure when `setOnline(_: completion:)` embedded in the init method completes. This method listens for flag updates so the completion will only return once an update has occurred. The start call is subject to throttling delays, therefore the `completion` closure call may be delayed.
     Subsequent calls to this method cause the LDClient to throw an error. Normally there should only be one call to init. To change `config` or `user`, set them directly on LDClient.
     - parameter configuration: The LDConfig that contains the desired configuration. (Required)
     - parameter startUser: The LDUser set with the desired user. If omitted, LDClient retains the previously set user, or default if one was never set. (Optional)
     - parameter completion: Closure called when the embedded `setOnline` call completes, subject to throttling delays. (Optional)
    */
    public static func start(config: LDConfig, startUser: LDUser? = nil, completion: (() -> Void)? = nil) {
        Log.debug("LDClient starting")
        if instances != nil {
            Log.debug("LDClient.start() was called more than once!")
            return
        }

        HTTPHeaders.removeFlagRequestEtags()
        
        let anonymousUser = LDUser(environmentReporter: EnvironmentReporter())
        let internalUser = startUser ?? anonymousUser
        
        LDClient.instances = [:]
        let cache = UserEnvironmentFlagCache(withKeyedValueCache: ClientServiceFactory().makeKeyedValueCache(), maxCachedUsers: config.maxCachedUsers)
        let flagChangeNotifier = FlagChangeNotifier()
        var mobileKeys = config.secondaryMobileKeys ?? [:]
        var internalCount = 0
        let completionCheck = {
            internalCount += 1
            if internalCount > mobileKeys.count {
                Log.debug("All LDClients finished starting")
                completion?()
            }
        }
        mobileKeys[LDConfig.Defaults.primaryEnvironmentName] = config.mobileKey
        for (name, mobileKey) in mobileKeys {
            var internalConfig = config
            internalConfig.mobileKey = mobileKey
            let instance = LDClient(configuration: internalConfig, startUser: internalUser, newCache: cache, flagNotifier: flagChangeNotifier, completion: completionCheck)
            LDClient.instances?[name] = instance
        }
        completionCheck()
    }

    public static func start(config: LDConfig, startUser: LDUser? = nil, startWaitSeconds: TimeInterval, completion: ((_ timedOut: Bool) -> Void)? = nil) {
        var completed = true
        let internalCompletedQueue: DispatchQueue = DispatchQueue(label: "TimeOutQueue")
        if !config.startOnline {
            start(config: config, startUser: startUser)
            completion?(completed)
        } else {
            let startTime = Date().timeIntervalSince1970
            start(config: config, startUser: startUser) {
                internalCompletedQueue.async {
                    if startTime + startWaitSeconds > Date().timeIntervalSince1970 && completed {
                        completed = false
                        completion?(completed)
                    }
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + startWaitSeconds) {
                internalCompletedQueue.async {
                    if completed {
                        completion?(completed)
                    }
                }
            }
        }
    }
    
    // MARK: - Private
    private(set) var serviceFactory: ClientServiceCreating = ClientServiceFactory()

    private(set) var runMode: LDClientRunMode = .foreground {
        didSet {
            guard runMode != oldValue
            else {
                Log.debug(typeName(and: #function) + " aborted. Old runMode equals new runMode.")
                return
            }
            Log.debug(typeName(and: #function, appending: ": ") + "\(runMode)")

            let willSetSynchronizerOnline = isOnline && isInSupportedRunMode
            //The only time the flag synchronizer configuration WILL match is if the client sets flag polling with the polling interval set to the background polling interval.
            //if it does match, keeping the synchronizer precludes an extra flag request
            if !flagSynchronizerConfigMatchesConfigAndRunMode {
                flagSynchronizer.isOnline = false
                let streamingModeVar = ConnectionInformation.effectiveStreamingMode(config: config, ldClient: self)
                connectionInformation = ConnectionInformation.backgroundBehavior(connectionInformation: connectionInformation, streamingMode: streamingModeVar, goOnline: willSetSynchronizerOnline)
                flagSynchronizer = serviceFactory.makeFlagSynchronizer(streamingMode: streamingModeVar,
                                                                       pollingInterval: config.flagPollingInterval(runMode: runMode),
                                                                       useReport: config.useReport,
                                                                       service: service,
                                                                       onSyncComplete: onFlagSyncComplete)
            }
            flagSynchronizer.isOnline = willSetSynchronizerOnline
            diagnosticReporter.runMode = runMode
        }
    }
    
    private var flagSynchronizerConfigMatchesConfigAndRunMode: Bool {
        return flagSynchronizer.streamingMode == ConnectionInformation.effectiveStreamingMode(config: config, ldClient: self)
            && (flagSynchronizer.streamingMode == .streaming
                || flagSynchronizer.streamingMode == .polling && flagSynchronizer.pollingInterval == config.flagPollingInterval(runMode: runMode))
    }

    private(set) var flagCache: FeatureFlagCaching
    private(set) var cacheConverter: CacheConverting
    private(set) var flagSynchronizer: LDFlagSynchronizing
    var flagChangeNotifier: FlagChangeNotifying
    private(set) var eventReporter: EventReporting
    private(set) var environmentReporter: EnvironmentReporting
    private(set) var throttler: Throttling
    private(set) var diagnosticReporter: DiagnosticReporting

    private(set) var hasStarted: Bool {
        get { hasStartedQueue.sync { _hasStarted } }
        set { hasStartedQueue.sync { _hasStarted = newValue } }
    }
    private var _hasStarted = true
    private var hasStartedQueue = DispatchQueue(label: "com.launchdarkly.LDClient.hasStartedQueue")
    
    private init(serviceFactory: ClientServiceCreating? = nil, configuration: LDConfig, startUser: LDUser?, newCache: FeatureFlagCaching, flagNotifier: FlagChangeNotifying, testing: Bool = false, completion: (() -> Void)? = nil) {
        if let serviceFactory = serviceFactory {
            self.serviceFactory = serviceFactory
        }
        environmentReporter = self.serviceFactory.makeEnvironmentReporter()
        flagCache = newCache
        LDUserWrapper.configureKeyedArchiversToHandleVersion2_3_0AndOlderUserCacheFormat()
        cacheConverter = self.serviceFactory.makeCacheConverter(maxCachedUsers: configuration.maxCachedUsers)
        flagChangeNotifier = flagNotifier
        throttler = self.serviceFactory.makeThrottler(maxDelay: Throttler.Constants.defaultDelay, environmentReporter: environmentReporter)

        config = configuration
        let anonymousUser = LDUser(environmentReporter: environmentReporter)
        user = startUser ?? anonymousUser
        service = self.serviceFactory.makeDarklyServiceProvider(config: config, user: user)
        diagnosticReporter = self.serviceFactory.makeDiagnosticReporter(service: service, runMode: runMode)
        eventReporter = self.serviceFactory.makeEventReporter(config: config, service: service)
        errorNotifier = self.serviceFactory.makeErrorNotifier()
        connectionInformation = self.serviceFactory.makeConnectionInformation()
        flagSynchronizer = self.serviceFactory.makeFlagSynchronizer(streamingMode: config.allowStreamingMode ? config.streamingMode : .polling,
                                                                    pollingInterval: config.flagPollingInterval(runMode: runMode),
                                                                    useReport: config.useReport,
                                                                    service: service)
        
        if let backgroundNotification = environmentReporter.backgroundNotification {
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: backgroundNotification, object: nil)
        }
        if let foregroundNotification = environmentReporter.foregroundNotification {
            NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: foregroundNotification, object: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didCloseEventSource), name: Notification.Name(FlagSynchronizer.Constants.didCloseEventSourceName), object: nil)

        eventReporter = self.serviceFactory.makeEventReporter(config: config, service: service, onSyncComplete: onEventSyncComplete)
        flagSynchronizer = self.serviceFactory.makeFlagSynchronizer(streamingMode: config.allowStreamingMode ? config.streamingMode : .polling,
                                                                    pollingInterval: config.flagPollingInterval(runMode: runMode),
                                                                    useReport: config.useReport,
                                                                    service: service,
                                                                    onSyncComplete: onFlagSyncComplete)

        Log.level = environmentReporter.isDebugBuild && config.isDebugMode ? .debug : .noLogging
        cacheConverter.convertCacheData(for: user, and: config)
        if let cachedFlags = flagCache.retrieveFeatureFlags(forUserWithKey: user.key, andMobileKey: config.mobileKey), !cachedFlags.isEmpty {
            user.flagStore.replaceStore(newFlags: cachedFlags, completion: nil)
        }

        eventReporter.record(Event.identifyEvent(user: user))
        self.connectionInformation = ConnectionInformation.uncacheConnectionInformation(config: config, ldClient: self, clientServiceFactory: self.serviceFactory)

        internalSetOnline(configuration.startOnline) {
            Log.debug("LDClient started")
            completion?()
        }
    }
}

extension LDClient: TypeIdentifying { }

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

private extension Optional {
    var stringValue: String {
        guard let value = self
        else {
            return "<nil>"
        }
        return "\(value)"
    }
}

#if DEBUG
    extension LDClient {
        static func start(serviceFactory: ClientServiceCreating, config: LDConfig, startUser: LDUser? = nil, flagCache: FeatureFlagCaching, flagNotifier: FlagChangeNotifier, completion: (() -> Void)? = nil) {
            Log.debug("LDClient starting for tests")
            get()?.close()
            
            let anonymousUser = LDUser(environmentReporter: EnvironmentReporter())
            let internalUser = startUser ?? anonymousUser
            
            LDClient.instances = [:]
            var mobileKeys = config.secondaryMobileKeys ?? [:]
            var internalCount = 0
            let completionCheck = {
                internalCount += 1
                if internalCount > mobileKeys.count {
                    Log.debug("All LDClients finished starting for tests")
                    completion?()
                }
            }
            mobileKeys[LDConfig.Defaults.primaryEnvironmentName] = config.mobileKey
            for (name, mobileKey) in mobileKeys {
                var internalConfig = config
                internalConfig.mobileKey = mobileKey
                let instance = LDClient(serviceFactory: serviceFactory, configuration: internalConfig, startUser: internalUser, newCache: flagCache, flagNotifier: flagNotifier, completion: completionCheck)
                LDClient.instances?[name] = instance
            }
            completionCheck()
        }
        
        static func start(serviceFactory: ClientServiceCreating, config: LDConfig, startUser: LDUser? = nil, startWaitSeconds: TimeInterval, flagCache: FeatureFlagCaching, flagNotifier: FlagChangeNotifier, completion: ((_ timedOut: Bool) -> Void)? = nil) {
            var completed = true
            let internalCompletedQueue: DispatchQueue = DispatchQueue(label: "TimeOutQueue")
            if !config.startOnline {
                start(serviceFactory: serviceFactory, config: config, startUser: startUser, flagCache: flagCache, flagNotifier: flagNotifier)
                completion?(completed)
            } else {
                let startTime = Date().timeIntervalSince1970
                start(serviceFactory: serviceFactory, config: config, startUser: startUser, flagCache: flagCache, flagNotifier: flagNotifier) {
                    internalCompletedQueue.async {
                        if startTime + startWaitSeconds > Date().timeIntervalSince1970 && completed {
                            completed = false
                            completion?(completed)
                        }
                    }
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + startWaitSeconds) {
                    internalCompletedQueue.async {
                        if completed {
                            completion?(completed)
                        }
                    }
                }
            }
        }
        
        func setRunMode(_ runMode: LDClientRunMode) {
            self.runMode = runMode
        }

        func setHasStarted(_ hasStarted: Bool) {
            self.hasStarted = hasStarted
        }

        func setService(_ service: DarklyServiceProvider) {
            self.service = service
        }
    }
#endif
