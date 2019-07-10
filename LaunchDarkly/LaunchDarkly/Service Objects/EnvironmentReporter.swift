//
//  EnvironmentReporter.swift
//  LaunchDarkly
//
//  Created by Mark Pokorny on 3/27/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(OSX)
import AppKit
#elseif os(tvOS)
import UIKit
#endif

enum OperatingSystem: String {
    case iOS, watchOS, macOS, tvOS

    static var allOperatingSystems: [OperatingSystem] {
        return [.iOS, .watchOS, .macOS, .tvOS]
    }
    
    var isBackgroundEnabled: Bool {
        return OperatingSystem.backgroundEnabledOperatingSystems.contains(self)
    }
    static var backgroundEnabledOperatingSystems: [OperatingSystem] {
        return [.macOS]
    }

    var isStreamingEnabled: Bool {
        return OperatingSystem.streamingEnabledOperatingSystems.contains(self)
    }
    static var streamingEnabledOperatingSystems: [OperatingSystem] {
        return [.iOS, .macOS, .tvOS]
    }
}

//sourcery: autoMockable
protocol EnvironmentReporting {
    //sourcery: defaultMockValue = true
    var isDebugBuild: Bool { get }
    //sourcery: defaultMockValue = Constants.deviceModel
    var deviceModel: String { get }
    //sourcery: defaultMockValue = Constants.systemVersion
    var systemVersion: String { get }
    //sourcery: defaultMockValue = Constants.systemName
    var systemName: String { get }
    //sourcery: defaultMockValue = .iOS
    var operatingSystem: OperatingSystem { get }
    // the code generator is not generating the default, not sure why not //sourcery: defaultMockValue = .UIApplicationDidEnterBackground
    var backgroundNotification: Notification.Name? { get }
    // the code generator is not generating the default, not sure why not //sourcery: defaultMockValue = .UIApplicationWillEnterForeground
    var foregroundNotification: Notification.Name? { get }
    //sourcery: defaultMockValue = Constants.vendorUUID
    var vendorUUID: String? { get }
    //sourcery: defaultMockValue = Constants.sdkVersion
    var sdkVersion: String { get }
    //sourcery: defaultMockValue = true
    var shouldThrottleOnlineCalls: Bool { get }
}

struct EnvironmentReporter: EnvironmentReporting {
    #if DEBUG
    var isDebugBuild: Bool {
        return true
    }
    #else
    var isDebugBuild: Bool {
        return false
    }
    #endif

    struct Constants {
        fileprivate static let simulatorModelIdentifier = "SIMULATOR_MODEL_IDENTIFIER"
    }

    var deviceModel: String {
        #if os(OSX)
        return Sysctl.model
        #else
        //Obtaining the device model from https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model answer by Jens Schwarzer
        if let simulatorModelIdentifier = ProcessInfo().environment[Constants.simulatorModelIdentifier] {
            return simulatorModelIdentifier
        }
        //the physical device code here is not automatically testable. Manual testing on physical devices is required.
        var systemInfo = utsname()
        _ = uname(&systemInfo)
        guard let deviceModel = String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)
        else {
            return deviceType
        }
        return deviceModel.trimmingCharacters(in: .controlCharacters)
        #endif
    }

    #if os(iOS)
    var deviceType: String {
        return UIDevice.current.model
    }
    var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    var systemName: String {
        return UIDevice.current.systemName
    }
    var operatingSystem: OperatingSystem {
        return .iOS
    }
    var backgroundNotification: Notification.Name? {
        return UIApplication.didEnterBackgroundNotification
    }
    var foregroundNotification: Notification.Name? {
        return UIApplication.willEnterForegroundNotification
    }
    var vendorUUID: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    #elseif os(watchOS)
    var deviceType: String {
        return WKInterfaceDevice.current().model
    }
    var systemVersion: String {
        return WKInterfaceDevice.current().systemVersion
    }
    var systemName: String {
        return WKInterfaceDevice.current().systemName
    }
    var operatingSystem: OperatingSystem {
        return .watchOS
    }
    var backgroundNotification: Notification.Name? {
        return nil
    }
    var foregroundNotification: Notification.Name? {
        return nil
    }
    var vendorUUID: String? {
        return nil
    }
    #elseif os(OSX)
    var deviceType: String {
        return Sysctl.modelWithoutVersion
    }
    var systemVersion: String {
        return ProcessInfo.processInfo.operatingSystemVersion.compactVersionString
    }
    var systemName: String {
        return "macOS"
    }
    var operatingSystem: OperatingSystem {
        return .macOS
    }
    var backgroundNotification: Notification.Name? {
        return NSApplication.willResignActiveNotification
    }
    var foregroundNotification: Notification.Name? {
        return NSApplication.didBecomeActiveNotification
    }
    var vendorUUID: String? {
        return nil
    }
    #elseif os(tvOS)
    var deviceType: String {
        return UIDevice.current.model
    }
    var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    var systemName: String {
        return UIDevice.current.systemName
    }
    var operatingSystem: OperatingSystem {
        return .tvOS
    }
    var backgroundNotification: Notification.Name? {
        return UIApplication.didEnterBackgroundNotification
    }
    var foregroundNotification: Notification.Name? {
        return UIApplication.willEnterForegroundNotification
    }
    var vendorUUID: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    #endif

    #if INTEGRATION_HARNESS
    var shouldThrottleOnlineCalls: Bool {
        return !isDebugBuild
    }
    #else
    var shouldThrottleOnlineCalls: Bool {
        return true
    }
    #endif

    var sdkVersion: String {
        return Bundle(for: LDClient.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.x"
    }
}

#if os(OSX)
extension OperatingSystemVersion {
    var compactVersionString: String {
        return "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}

extension Sysctl {
    static var modelWithoutVersion: String {
        //swiftlint:disable:next force_try
        let modelRegex = try! NSRegularExpression(pattern: "([A-Za-z]+)\\d{1,2},\\d")
        let model = Sysctl.model    //e.g. "MacPro4,1"
        return modelRegex.firstCaptureGroup(in: model, options: [], range: model.range) ?? "mac"
    }
}

private extension String {
    func substring(_ range: NSRange) -> String? {
        guard range.location >= 0 && range.location < self.count,
            range.location + range.length >= 0 && range.location + range.length < self.count
        else {
            return nil
        }
        let startIndex = index(self.startIndex, offsetBy: range.location)
        let endIndex = index(self.startIndex, offsetBy: range.length)
        return String(self[startIndex..<endIndex])
    }

    var range: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}

private extension NSRegularExpression {
    func firstCaptureGroup(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange) -> String? {
        guard let match = self.firstMatch(in: string, options: [], range: string.range),
            let group = string.substring(match.range(at: 1))
        else {
            return nil
        }
        return group
    }
}
#endif
