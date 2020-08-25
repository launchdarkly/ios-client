//
//  LDConfigSpec.swift
//  LaunchDarklyTests
//
//  Copyright © 2017 Catamorphic Co. All rights reserved.
//

import Foundation
import XCTest

@testable import LaunchDarkly

final class LDConfigSpec: XCTestCase {
    struct Constants {
        fileprivate static let alternateMockUrl = URL(string: "https://dummy.alternate.com")!
        fileprivate static let eventCapacity = 10
        fileprivate static let connectionTimeout: TimeInterval = 0.01
        fileprivate static let eventFlushInterval: TimeInterval = 0.01
        fileprivate static let flagPollingInterval: TimeInterval = 0.01
        fileprivate static let backgroundFlagPollingInterval: TimeInterval = 0.01

        fileprivate static let streamingMode = LDStreamingMode.polling
        fileprivate static let enableBackgroundUpdates = true
        fileprivate static let startOnline = false

        fileprivate static let allUserAttributesPrivate = true
        fileprivate static let privateUserAttributes: [String] = ["dummy"]

        fileprivate static let useReport = true

        fileprivate static let inlineUserInEvents = true

        fileprivate static let debugMode = true
        fileprivate static let evaluationReasons = true
        fileprivate static let maxCachedUsers = -1
        fileprivate static let diagnosticOptOut = true
        fileprivate static let diagnosticRecordingInterval: TimeInterval = 600.0
        fileprivate static let wrapperName = "ReactNative"
        fileprivate static let wrapperVersion = "0.1.0"
        fileprivate static let additionalHeaders = ["Proxy-Authorization": "creds"]
    }

    let testFields: [(String, Any, (inout LDConfig, Any?) -> Void)] =
        [("mobile key", LDConfig.Constants.alternateMobileKey, { c, v in c.mobileKey = v as! String }),
         ("base URL", Constants.alternateMockUrl, { c, v in c.baseUrl = v as! URL }),
         ("event URL", Constants.alternateMockUrl, { c, v in c.eventsUrl = v as! URL }),
         ("stream URL", Constants.alternateMockUrl, { c, v in c.streamUrl = v as! URL }),
         ("event capacity", Constants.eventCapacity, { c, v in c.eventCapacity = v as! Int }),
         ("connection timeout", Constants.connectionTimeout, { c, v in c.connectionTimeout = v as! TimeInterval }),
         ("event flush interval", Constants.eventFlushInterval, { c, v in c.eventFlushInterval = v as! TimeInterval }),
         ("poll interval", Constants.flagPollingInterval, { c, v in c.flagPollingInterval = v as! TimeInterval }),
         ("background poll interval", Constants.backgroundFlagPollingInterval, { c, v in c.backgroundFlagPollingInterval = v as! TimeInterval }),
         ("streaming mode", Constants.streamingMode, { c, v in c.streamingMode = v as! LDStreamingMode }),
         ("enable background updates", Constants.enableBackgroundUpdates, { c, v in c.enableBackgroundUpdates = v as! Bool }),
         ("start online", Constants.startOnline, { c, v in c.startOnline = v as! Bool }),
         ("debug mode", Constants.debugMode, { c, v in c.isDebugMode = v as! Bool }),
         ("all user attributes private", Constants.allUserAttributesPrivate, { c, v in c.allUserAttributesPrivate = v as! Bool }),
         ("private user attributes", Constants.privateUserAttributes, { c, v in c.privateUserAttributes = (v as! [String])}),
         ("use report", Constants.useReport, { c, v in c.useReport = v as! Bool }),
         ("inline user in events", Constants.inlineUserInEvents, { c, v in c.inlineUserInEvents = v as! Bool }),
         ("evaluation reasons", Constants.evaluationReasons, { c, v in c.evaluationReasons = v as! Bool }),
         ("max cached users", Constants.maxCachedUsers, { c, v in c.maxCachedUsers = v as! Int }),
         ("diagnostic opt out", Constants.diagnosticOptOut, { c, v in c.diagnosticOptOut = v as! Bool }),
         ("diagnostic recording interval", Constants.diagnosticRecordingInterval, { c, v in c.diagnosticRecordingInterval = v as! TimeInterval }),
         ("wrapper name", Constants.wrapperName, { c, v in c.wrapperName = v as! String? }),
         ("wrapper version", Constants.wrapperVersion, { c, v in c.wrapperVersion = v as! String? }),
         ("additional headers", Constants.additionalHeaders, { c, v in c.additionalHeaders = v as! [String: String]})]

    func testInitDefault() {
        let config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey)
        XCTAssertEqual(config.mobileKey, LDConfig.Constants.mockMobileKey)
        XCTAssertEqual(config.baseUrl, LDConfig.Defaults.baseUrl)
        XCTAssertEqual(config.eventsUrl, LDConfig.Defaults.eventsUrl)
        XCTAssertEqual(config.streamUrl, LDConfig.Defaults.streamUrl)
        XCTAssertEqual(config.eventCapacity, LDConfig.Defaults.eventCapacity)
        XCTAssertEqual(config.connectionTimeout, LDConfig.Defaults.connectionTimeout)
        XCTAssertEqual(config.eventFlushInterval, LDConfig.Defaults.eventFlushInterval)
        XCTAssertEqual(config.flagPollingInterval, LDConfig.Defaults.flagPollingInterval)
        XCTAssertEqual(config.backgroundFlagPollingInterval, LDConfig.Defaults.backgroundFlagPollingInterval)
        XCTAssertEqual(config.streamingMode, LDConfig.Defaults.streamingMode)
        XCTAssertEqual(config.enableBackgroundUpdates, LDConfig.Defaults.enableBackgroundUpdates)
        XCTAssertEqual(config.startOnline, LDConfig.Defaults.startOnline)
        XCTAssertEqual(config.allUserAttributesPrivate, LDConfig.Defaults.allUserAttributesPrivate)
        XCTAssertEqual(config.privateUserAttributes, nil)
        XCTAssertEqual(config.useReport, LDConfig.Defaults.useReport)
        XCTAssertEqual(config.inlineUserInEvents, LDConfig.Defaults.inlineUserInEvents)
        XCTAssertEqual(config.isDebugMode, LDConfig.Defaults.debugMode)
        XCTAssertEqual(config.evaluationReasons, LDConfig.Defaults.evaluationReasons)
        XCTAssertEqual(config.maxCachedUsers, LDConfig.Defaults.maxCachedUsers)
        XCTAssertEqual(config.diagnosticOptOut, LDConfig.Defaults.diagnosticOptOut)
        XCTAssertEqual(config.diagnosticRecordingInterval, LDConfig.Defaults.diagnosticRecordingInterval)
        XCTAssertEqual(config.wrapperName, LDConfig.Defaults.wrapperName)
        XCTAssertEqual(config.wrapperVersion, LDConfig.Defaults.wrapperVersion)
        XCTAssertEqual(config.additionalHeaders, LDConfig.Defaults.additionalHeaders)
    }

    func testInitUpdate() {
        OperatingSystem.allOperatingSystems.forEach { os in
            let environmentReporter = EnvironmentReportingMock()
            environmentReporter.operatingSystem = os
            var config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmentReporter)
            testFields.forEach { _, otherVal, setter in
                setter(&config, otherVal)
            }
            XCTAssertEqual(config.mobileKey, LDConfig.Constants.alternateMobileKey, "\(os)")
            XCTAssertEqual(config.baseUrl, Constants.alternateMockUrl, "\(os)")
            XCTAssertEqual(config.eventsUrl, Constants.alternateMockUrl, "\(os)")
            XCTAssertEqual(config.streamUrl, Constants.alternateMockUrl, "\(os)")
            XCTAssertEqual(config.eventCapacity, Constants.eventCapacity, "\(os)")
            XCTAssertEqual(config.connectionTimeout, Constants.connectionTimeout, "\(os)")
            XCTAssertEqual(config.eventFlushInterval, Constants.eventFlushInterval, "\(os)")
            XCTAssertEqual(config.flagPollingInterval, Constants.flagPollingInterval, "\(os)")
            XCTAssertEqual(config.backgroundFlagPollingInterval, Constants.backgroundFlagPollingInterval, "\(os)")
            XCTAssertEqual(config.streamingMode, Constants.streamingMode, "\(os)")
            XCTAssertEqual(config.enableBackgroundUpdates, os.isBackgroundEnabled, "\(os)")
            XCTAssertEqual(config.startOnline, Constants.startOnline, "\(os)")
            XCTAssertEqual(config.allUserAttributesPrivate, Constants.allUserAttributesPrivate, "\(os)")
            XCTAssertEqual(config.privateUserAttributes, Constants.privateUserAttributes, "\(os)")
            XCTAssertEqual(config.useReport, Constants.useReport, "\(os)")
            XCTAssertEqual(config.inlineUserInEvents, Constants.inlineUserInEvents, "\(os)")
            XCTAssertEqual(config.isDebugMode, Constants.debugMode, "\(os)")
            XCTAssertEqual(config.evaluationReasons, Constants.evaluationReasons, "\(os)")
            XCTAssertEqual(config.maxCachedUsers, Constants.maxCachedUsers, "\(os)")
            XCTAssertEqual(config.diagnosticOptOut, Constants.diagnosticOptOut, "\(os)")
            XCTAssertEqual(config.diagnosticRecordingInterval, Constants.diagnosticRecordingInterval, "\(os)")
            XCTAssertEqual(config.wrapperName, Constants.wrapperName, "\(os)")
            XCTAssertEqual(config.wrapperVersion, Constants.wrapperVersion, "\(os)")
            XCTAssertEqual(config.additionalHeaders, Constants.additionalHeaders, "\(os)")
        }
    }

    func testMinimaInitDebug() {
        let environmentReporter = EnvironmentReportingMock()
        environmentReporter.isDebugBuild = true
        let config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmentReporter)
        XCTAssertEqual(config.minima.flagPollingInterval, LDConfig.Minima.Debug.flagPollingInterval)
        XCTAssertEqual(config.minima.backgroundFlagPollingInterval, LDConfig.Minima.Debug.backgroundFlagPollingInterval)
        XCTAssertEqual(config.minima.diagnosticRecordingInterval, LDConfig.Minima.Debug.diagnosticRecordingInterval)
    }

    func testMinimaInitRelease() {
        let environmentReporter = EnvironmentReportingMock()
        environmentReporter.isDebugBuild = false
        let config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmentReporter)
        XCTAssertEqual(config.minima.flagPollingInterval, LDConfig.Minima.Production.flagPollingInterval)
        XCTAssertEqual(config.minima.backgroundFlagPollingInterval, LDConfig.Minima.Production.backgroundFlagPollingInterval)
        XCTAssertEqual(config.minima.diagnosticRecordingInterval, LDConfig.Minima.Production.diagnosticRecordingInterval)
    }

    func testFlagPollingInterval() {
        [false, true].forEach { debugMode in
            let environmentReporter = EnvironmentReportingMock()
            environmentReporter.isDebugBuild = debugMode
            var config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmentReporter)
            // polling interval above minimum.
            var interval = config.minima.flagPollingInterval + 0.001
            config.flagPollingInterval = interval
            XCTAssertEqual(config.flagPollingInterval(runMode: .foreground), interval, "debugMode: \(debugMode)")
            // polling interval at minimum
            interval = config.minima.flagPollingInterval
            config.flagPollingInterval = interval
            XCTAssertEqual(config.flagPollingInterval(runMode: .foreground), interval, "debugMode: \(debugMode)")
            // polling interval below minimum
            interval = config.minima.flagPollingInterval - 0.001
            config.flagPollingInterval = interval
            XCTAssertEqual(config.flagPollingInterval(runMode: .foreground), config.minima.flagPollingInterval, "debugMode: \(debugMode)")
            // background polling interval above minimum.
            interval = config.minima.backgroundFlagPollingInterval + 0.001
            config.backgroundFlagPollingInterval = interval
            XCTAssertEqual(config.flagPollingInterval(runMode: .background), interval, "debugMode: \(debugMode)")
            // background polling interval at minimum
            interval = config.minima.backgroundFlagPollingInterval
            config.backgroundFlagPollingInterval = interval
            XCTAssertEqual(config.flagPollingInterval(runMode: .background), interval, "debugMode: \(debugMode)")
            // background polling interval below minimum
            interval = config.minima.backgroundFlagPollingInterval - 0.001
            config.backgroundFlagPollingInterval = interval
            XCTAssertEqual(config.flagPollingInterval(runMode: .background), config.minima.backgroundFlagPollingInterval, "debugMode: \(debugMode)")
        }
    }

    func testDiagnosticReportingInterval() {
        var config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: EnvironmentReportingMock())
        // set below minimum value
        config.diagnosticRecordingInterval = config.minima.diagnosticRecordingInterval - 0.001
        XCTAssertEqual(config.diagnosticRecordingInterval, config.minima.diagnosticRecordingInterval)
        // set above minimum value
        config.diagnosticRecordingInterval = config.minima.diagnosticRecordingInterval + 0.001
        XCTAssertEqual(config.diagnosticRecordingInterval, config.minima.diagnosticRecordingInterval + 0.001)
    }

    func testEquals() {
        let environmentReporter = EnvironmentReportingMock()
        //must use a background enabled OS to test inequality of background enabled
        environmentReporter.operatingSystem = OperatingSystem.backgroundEnabledOperatingSystems.first!
        let defaultConfig = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmentReporter)
        // same config
        symmetricAssertEqual(defaultConfig, defaultConfig)
        // equivalent config
        symmetricAssertEqual(defaultConfig, LDConfig(mobileKey: LDConfig.Constants.mockMobileKey))
        // different mobile key
        symmetricAssertNotEqual(defaultConfig, LDConfig(mobileKey: LDConfig.Constants.alternateMobileKey))
        testFields.forEach { name, otherVal, setter in
            var otherConfig = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmentReporter)
            setter(&otherConfig, otherVal)
            symmetricAssertNotEqual(defaultConfig, otherConfig, "\(name) differs")
        }
    }

    func testIsReportRetryStatusCode() {
        HTTPURLResponse.StatusCodes.all.forEach { statusCode in
            XCTAssertEqual(LDConfig.isReportRetryStatusCode(statusCode),
                           LDConfig.reportRetryStatusCodes.contains(statusCode),
                           "statusCode: \(statusCode)")
        }
    }

    func testAllowStreamingModeSpec() {
        for operatingSystem in OperatingSystem.allOperatingSystems {
            let environmenReporter = EnvironmentReportingMock()
            environmenReporter.operatingSystem = operatingSystem
            let config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmenReporter)
            XCTAssertEqual(config.allowStreamingMode, operatingSystem.isStreamingEnabled)
        }
    }

    func testAllowBackgroundUpdatesSpec() {
        for operatingSystem in OperatingSystem.allOperatingSystems {
            let environmenReporter = EnvironmentReportingMock()
            environmenReporter.operatingSystem = operatingSystem
            var config = LDConfig(mobileKey: LDConfig.Constants.mockMobileKey, environmentReporter: environmenReporter)
            config.enableBackgroundUpdates = true
            XCTAssertEqual(config.enableBackgroundUpdates, operatingSystem.isBackgroundEnabled)
        }
    }
}
