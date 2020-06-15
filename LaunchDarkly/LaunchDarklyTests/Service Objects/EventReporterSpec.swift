//
//  EventReporterSpec.swift
//  LaunchDarklyTests
//
//  Copyright © 2017 Catamorphic Co. All rights reserved.
//

import Quick
import Nimble
import XCTest
@testable import LaunchDarkly

final class EventReporterSpec: QuickSpec {
    struct Constants {
        static let eventFlushInterval: TimeInterval = 10.0
        static let eventFlushIntervalHalfSecond: TimeInterval = 0.5
        static let defaultValue = false
    }

    struct TestContext {
        var eventReporter: EventReporter!
        var config: LDConfig!
        var user: LDUser!
        var serviceMock: DarklyServiceMock!
        var events: [Event]!
        var eventKeys: [String]! { events.compactMap { $0.key } }
        var eventKinds: [Event.Kind]! { events.compactMap { $0.kind } }
        var lastEventResponseDate: Date?
        var flagKey: LDFlagKey!
        var eventTrackingContext: EventTrackingContext!
        var featureFlag: FeatureFlag!
        var featureFlagWithReason: FeatureFlag!
        var featureFlagWithReasonAndTrackReason: FeatureFlag!
        var eventStubResponseDate: Date?
        var flagRequestTracker: FlagRequestTracker?
        var reportersTracker: FlagRequestTracker? { eventReporter.flagRequestTracker }
        var flagRequestCount: Int
        var syncResult: EventSyncResult? = nil

        init(eventCount: Int = 0,
             eventFlushInterval: TimeInterval? = nil,
             flagRequestCount: Int = 1,
             lastEventResponseDate: Date? = nil,
             stubResponseSuccess: Bool = true,
             stubResponseOnly: Bool = false,
             stubResponseErrorOnly: Bool = false,
             eventStubResponseDate: Date? = nil,
             trackEvents: Bool? = true,
             debugEventsUntilDate: Date? = nil,
             flagRequestTracker: FlagRequestTracker? = nil,
             onSyncComplete: EventSyncCompleteClosure? = nil) {

            config = LDConfig.stub
            config.eventCapacity = Event.Kind.allKinds.count
            config.eventFlushInterval = eventFlushInterval ?? Constants.eventFlushInterval

            user = LDUser.stub()

            self.eventStubResponseDate = eventStubResponseDate?.adjustedForHttpUrlHeaderUse
            serviceMock = DarklyServiceMock()
            serviceMock.stubEventResponse(success: stubResponseSuccess, responseOnly: stubResponseOnly, errorOnly: stubResponseErrorOnly, responseDate: self.eventStubResponseDate)

            events = (0..<eventCount).map { [user] in Event.stub(Event.eventKind(for: $0), with: user!) }

            self.lastEventResponseDate = lastEventResponseDate?.adjustedForHttpUrlHeaderUse
            self.flagRequestTracker = flagRequestTracker
            eventReporter = EventReporter(config: config,
                                          service: serviceMock,
                                          events: events,
                                          lastEventResponseDate: self.lastEventResponseDate,
                                          flagRequestTracker: flagRequestTracker,
                                          onSyncComplete: onSyncComplete)

            flagKey = UUID().uuidString
            if let trackEvents = trackEvents {
                eventTrackingContext = EventTrackingContext(trackEvents: trackEvents)
            }
            if let debugEventsUntilDate = debugEventsUntilDate {
                eventTrackingContext = EventTrackingContext(trackEvents: self.eventTrackingContext?.trackEvents ?? false, debugEventsUntilDate: debugEventsUntilDate)
            }
            featureFlag = DarklyServiceMock.Constants.stubFeatureFlag(for: DarklyServiceMock.FlagKeys.bool, eventTrackingContext: eventTrackingContext)
            featureFlagWithReason = DarklyServiceMock.Constants.stubFeatureFlag(for: DarklyServiceMock.FlagKeys.bool, eventTrackingContext: eventTrackingContext, includeEvaluationReason: true)
            featureFlagWithReasonAndTrackReason = DarklyServiceMock.Constants.stubFeatureFlag(for: DarklyServiceMock.FlagKeys.bool, eventTrackingContext: eventTrackingContext, includeEvaluationReason: true, includeTrackReason: true)
            self.flagRequestCount = flagRequestCount
        }

        mutating func recordEvents(_ eventCount: Int, completion: CompletionClosure? = nil) {
            for _ in 0..<eventCount {
                let event = Event.stub(Event.eventKind(for: events.count), with: user)
                events.append(event)
                eventReporter.record(event)
            }
            completion?()
        }

        mutating func addEvents(_ eventCount: Int) {
            events += (events.count..<eventCount + events.count).map { Event.stub(Event.eventKind(for: $0), with: user) }
            eventReporter?.add(events)
        }

        func flagCounter(for key: LDFlagKey) -> FlagCounter? {
            reportersTracker?.flagCounters[key]
        }

        func flagValueCounter(for key: LDFlagKey, and featureFlag: FeatureFlag?) -> FlagValueCounter? {
            flagCounter(for: key)?.flagValueCounters.flagValueCounter(for: featureFlag)
        }
    }

    override func spec() {
        initSpec()
        isOnlineSpec()
        changeConfigSpec()
        recordEventSpec()
        recordFlagEvaluationEventsSpec()
        reportEventsSpec()
        reportTimerSpec()
        eventKeysSpec()
    }

    private func initSpec() {
        describe("init") {
            var testContext: TestContext!
            beforeEach {
                testContext = TestContext()

                testContext.eventReporter = EventReporter(config: testContext.config, service: testContext.serviceMock) { _ in }
            }
            it("starts offline without reporting events") {
                expect(testContext.eventReporter.config) == testContext.config
                expect(testContext.eventReporter.service) === testContext.serviceMock
                expect(testContext.eventReporter.isOnline) == false
                expect(testContext.eventReporter.isReportingActive) == false
                expect(testContext.eventReporter.testOnSyncComplete).toNot(beNil())
                expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
            }
        }
    }

    private func isOnlineSpec() {
        describe("isOnline") {
            var testContext: TestContext!
            beforeEach {
                testContext = TestContext()
            }
            afterEach {
                testContext.eventReporter.isOnline = false
            }
            context("online to offline") {
                beforeEach {
                    testContext.eventReporter.isOnline = true

                    testContext.eventReporter.isOnline = false
                }
                it("goes offline and stops reporting") {
                    expect(testContext.eventReporter.isOnline) == false
                    expect(testContext.eventReporter.isReportingActive) == false
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                }
            }
            context("offline to online") {
                context("with events") {
                    beforeEach {
                        testContext = TestContext(eventCount: Event.Kind.allKinds.count)

                        testContext.eventReporter.isOnline = true
                    }
                    it("goes online and starts reporting") {
                        expect(testContext.eventReporter.isOnline) == true
                        expect(testContext.eventReporter.isReportingActive) == true
                        expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    }
                }
                context("without events") {
                    beforeEach {
                        testContext = TestContext()

                        testContext.eventReporter.isOnline = true
                    }
                    it("goes online and starts reporting") {
                        expect(testContext.eventReporter.isOnline) == true
                        expect(testContext.eventReporter.isReportingActive) == true
                        expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    }
                }
            }
            context("online to online") {
                beforeEach {
                    testContext = TestContext()
                    testContext.eventReporter.isOnline = true

                    testContext.eventReporter.isOnline = true
                }
                it("stays online and continues reporting") {
                    expect(testContext.eventReporter.isOnline) == true
                    expect(testContext.eventReporter.isReportingActive) == true
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                }
            }
            context("offline to offline") {
                beforeEach {
                    testContext = TestContext(eventCount: Event.Kind.allKinds.count)

                    testContext.eventReporter.isOnline = false
                }
                it("stays offline and does not start reporting") {
                    expect(testContext.eventReporter.isOnline) == false
                    expect(testContext.eventReporter.isReportingActive) == false
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    expect(testContext.eventReporter.eventStoreKeys) == testContext.eventKeys
                }
            }
        }
    }

    private func changeConfigSpec() {
        describe("change config") {
            var config: LDConfig!
            var testContext: TestContext!
            beforeEach {
                testContext = TestContext()
                config = LDConfig.stub
                config.streamingMode = .polling //using this to verify the config was changed...could be any value different from the setup
            }
            context("while offline") {
                beforeEach {
                    testContext.eventReporter.config = config
                }
                it("changes the config") {
                    expect(testContext.eventReporter.isOnline) == false
                    expect(testContext.eventReporter.isReportingActive) == false
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    expect(testContext.eventReporter.config.streamingMode) == config.streamingMode
                }
            }
            context("while online") {
                beforeEach {
                    testContext.eventReporter.isOnline = true

                    testContext.eventReporter.config = config
                }
                it("takes the reporter offline and changes the config") {
                    expect(testContext.eventReporter.isOnline) == false
                    expect(testContext.eventReporter.isReportingActive) == false
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    expect(testContext.eventReporter.config) == config
                }
            }
        }
    }

    private func recordEventSpec() {
        describe("recordEvent") {
            var testContext: TestContext!
            context("event store empty") {
                beforeEach {
                    testContext = TestContext()

                    waitUntil { done in
                        testContext.recordEvents(Event.Kind.allKinds.count, completion: done) // Stub events, call testContext.eventReporter.recordEvent, and keeps them in testContext.events
                    }
                }
                it("records events up to event capacity") {
                    expect(testContext.eventReporter.isOnline) == false
                    expect(testContext.eventReporter.isReportingActive) == false
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    expect(testContext.eventReporter.eventStoreKeys) == testContext.eventKeys
                }
            }
            context("event store full") {
                var extraEvent: Event!
                beforeEach {
                    testContext = TestContext(eventCount: Event.Kind.allKinds.count)
                    extraEvent = Event.stub(.feature, with: testContext.user)

                    testContext.eventReporter.record(extraEvent)
                }
                it("doesn't record any more events") {
                    expect(testContext.eventReporter.isOnline) == false
                    expect(testContext.eventReporter.isReportingActive) == false
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    expect(testContext.eventReporter.eventStoreKeys) == testContext.eventKeys
                    expect(testContext.eventReporter.eventStoreKeys.contains(extraEvent.key!)) == false
                }
            }
        }
    }

    private func reportEventsSpec() {
        describe("reportEvents") {
            var testContext: TestContext!
            var eventStubResponseDate: Date!
            beforeEach {
                eventStubResponseDate = Date().addingTimeInterval(-TimeInterval(3))
            }
            afterEach {
                testContext.eventReporter.isOnline = false
            }
            context("online") {
                context("success") {
                    context("with events and tracked requests") {
                        beforeEach {
                            //The EventReporter will try to report events if it's started online with events. By starting online without events, then adding them, we "beat the timer" by reporting them right away
                            waitUntil { syncComplete in
                                testContext = TestContext(eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                                    testContext.syncResult = result
                                    syncComplete()
                                })
                                testContext.eventReporter.isOnline = true
                                testContext.addEvents(Event.Kind.nonSummaryKinds.count)
                                testContext.flagRequestTracker = FlagRequestTracker.stub()
                                testContext.eventReporter.setFlagRequestTracker(testContext.flagRequestTracker!)
                                testContext.eventReporter.flush(completion: nil)
                            }
                        }
                        it("reports events and a summary event") {
                            expect(testContext.eventReporter.isOnline) == true
                            expect(testContext.eventReporter.isReportingActive) == true
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 1
                            expect(testContext.serviceMock.publishedEventDictionaries?.count) == Event.Kind.nonSummaryKinds.count + 1
                            expect(testContext.serviceMock.publishedEventDictionaryKeys) == testContext.eventKeys //summary events have no key, this verifies non-summary events
                            expect(testContext.serviceMock.publishedEventDictionaryKinds?.contains(.summary)) == true
                            expect(testContext.eventReporter.eventStore.isEmpty) == true
                            expect(testContext.eventReporter.lastEventResponseDate) == testContext.eventStubResponseDate
                            expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == false
                            guard case let .success(result) = testContext.syncResult
                            else {
                                fail("Expected event dictionaries in sync result")
                                return
                            }
                            expect(result == testContext.serviceMock.publishedEventDictionaries!).to(beTrue())
                        }

                    }
                    context("with events only") {
                        beforeEach {
                            //The EventReporter will try to report events if it's started online with events. By starting online without events, then adding them, we "beat the timer" by reporting them right away
                            waitUntil { syncComplete in
                                testContext = TestContext(eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                                    testContext.syncResult = result
                                    syncComplete()
                                })
                                testContext.eventReporter.isOnline = true
                                testContext.addEvents(Event.Kind.nonSummaryKinds.count)
                                testContext.eventReporter.flush(completion: nil)
                            }
                        }
                        it("reports events without a summary event") {
                            expect(testContext.eventReporter.isOnline) == true
                            expect(testContext.eventReporter.isReportingActive) == true
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 1
                            expect(testContext.serviceMock.publishedEventDictionaries?.count) == Event.Kind.nonSummaryKinds.count
                            expect(testContext.serviceMock.publishedEventDictionaryKeys) == testContext.eventKeys //summary events have no key, this verifies non-summary events
                            expect(testContext.serviceMock.publishedEventDictionaryKinds?.contains(.summary)) == false
                            expect(testContext.eventReporter.eventStore.isEmpty) == true
                            expect(testContext.eventReporter.lastEventResponseDate) == testContext.eventStubResponseDate
                            expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == false
                            guard case let .success(result) = testContext.syncResult
                            else {
                                fail("Expected event dictionaries in sync result")
                                return
                            }
                            expect(result == testContext.serviceMock.publishedEventDictionaries!).to(beTrue())
                        }
                    }
                    context("with tracked requests only") {
                        beforeEach {
                            //The EventReporter will try to report events if it's started online with events. By starting online without events, then adding them, we "beat the timer" by reporting them right away
                            waitUntil { syncComplete in
                                testContext = TestContext(eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                                    testContext.syncResult = result
                                    syncComplete()
                                })
                                testContext.eventReporter.isOnline = true
                                testContext.flagRequestTracker = FlagRequestTracker.stub()
                                testContext.eventReporter.setFlagRequestTracker(testContext.flagRequestTracker!)
                                testContext.eventReporter.flush(completion: nil)
                            }
                        }
                        it("reports only a summary event") {
                            expect(testContext.eventReporter.isOnline) == true
                            expect(testContext.eventReporter.isReportingActive) == true
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 1
                            expect(testContext.serviceMock.publishedEventDictionaries?.count) == 1
                            expect(testContext.serviceMock.publishedEventDictionaryKinds?.contains(.summary)) == true
                            expect(testContext.eventReporter.eventStore.isEmpty) == true
                            expect(testContext.eventReporter.lastEventResponseDate) == testContext.eventStubResponseDate
                            expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == false
                            guard case let .success(result) = testContext.syncResult
                            else {
                                fail("Expected event dictionaries in sync result")
                                return
                            }
                            expect(result == testContext.serviceMock.publishedEventDictionaries!).to(beTrue())
                        }
                    }
                    context("without events or tracked requests") {
                        beforeEach {
                            waitUntil { syncComplete in
                                testContext = TestContext(eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                                    testContext.syncResult = result
                                    syncComplete()
                                })
                                testContext.eventReporter.isOnline = true
                                testContext.eventReporter.flush(completion: nil)
                            }
                        }
                        it("does not report events") {
                            expect(testContext.eventReporter.isOnline) == true
                            expect(testContext.eventReporter.isReportingActive) == true
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                            expect(testContext.eventReporter.eventStore.isEmpty) == true
                            expect(testContext.eventReporter.lastEventResponseDate).to(beNil())
                            expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == false
                            guard case let .success(result) = testContext.syncResult
                            else {
                                fail("Expected event dictionaries in sync result")
                                return
                            }
                            expect(result == [[String: Any]]()).to(beTrue())
                        }
                    }
                }
                context("failure") {
                    context("server error") {
                        beforeEach {
                            waitUntil(timeout: 10) { syncComplete in
                                testContext = TestContext(stubResponseSuccess: false, eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                                    testContext.syncResult = result
                                    syncComplete()
                                })
                                testContext.eventReporter.isOnline = true
                                testContext.addEvents(Event.Kind.nonSummaryKinds.count)
                                testContext.flagRequestTracker = FlagRequestTracker.stub()
                                testContext.eventReporter.setFlagRequestTracker(testContext.flagRequestTracker!)
                                testContext.eventReporter.flush(completion: nil)
                            }
                        }
                        it("drops events after the failure") {
                            expect(testContext.eventReporter.isOnline) == true
                            expect(testContext.eventReporter.isReportingActive) == true
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 2 //1 retry attempt
                            expect(testContext.eventReporter.eventStoreKeys) == []
                            expect(testContext.eventReporter.eventStoreKinds.contains(.summary)) == false
                            expect(testContext.serviceMock.publishedEventDictionaryKeys) == testContext.eventKeys
                            expect(testContext.serviceMock.publishedEventDictionaryKinds?.contains(.summary)) == true
                            expect(testContext.eventReporter.lastEventResponseDate).to(beNil())
                            expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == false
                            guard case let .error(.request(error)) = testContext.syncResult
                            else {
                                fail("Expected error result for event send")
                                return
                            }
                            expect(error as NSError?) == DarklyServiceMock.Constants.error
                        }
                    }
                    context("response only") {
                        beforeEach {
                            waitUntil(timeout: 10) { syncComplete in
                                testContext = TestContext(stubResponseSuccess: false, stubResponseOnly: true, eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                                    testContext.syncResult = result
                                    syncComplete()
                                })
                                testContext.eventReporter.isOnline = true
                                testContext.addEvents(Event.Kind.nonSummaryKinds.count)
                                testContext.flagRequestTracker = FlagRequestTracker.stub()
                                testContext.eventReporter.setFlagRequestTracker(testContext.flagRequestTracker!)
                                testContext.eventReporter.flush(completion: nil)
                            }
                        }
                        it("drops events after the failure") {
                            expect(testContext.eventReporter.isOnline) == true
                            expect(testContext.eventReporter.isReportingActive) == true
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 2 //1 retry attempt
                            expect(testContext.eventReporter.eventStoreKeys) == []
                            expect(testContext.eventReporter.eventStoreKinds.contains(.summary)) == false
                            expect(testContext.serviceMock.publishedEventDictionaryKeys) == testContext.eventKeys
                            expect(testContext.serviceMock.publishedEventDictionaryKinds?.contains(.summary)) == true
                            expect(testContext.eventReporter.lastEventResponseDate).to(beNil())
                            expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == false
                            let expectedError = testContext.serviceMock.errorEventHTTPURLResponse
                            guard case let .error(.response(error)) = testContext.syncResult
                            else {
                                fail("Expected error result for event send")
                                return
                            }
                            let httpError = error as? HTTPURLResponse
                            expect(httpError?.url) == expectedError?.url
                            expect(httpError?.statusCode) == expectedError?.statusCode
                        }
                    }
                    context("error only") {
                        beforeEach {
                            waitUntil(timeout: 10) { syncComplete in
                                testContext = TestContext(stubResponseSuccess: false, stubResponseErrorOnly: true, eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                                    testContext.syncResult = result
                                    syncComplete()
                                })
                                testContext.eventReporter.isOnline = true
                                testContext.addEvents(Event.Kind.nonSummaryKinds.count)
                                testContext.flagRequestTracker = FlagRequestTracker.stub()
                                testContext.eventReporter.setFlagRequestTracker(testContext.flagRequestTracker!)
                                testContext.eventReporter.flush(completion: nil)
                            }
                        }
                        it("drops events events after the failure") {
                            expect(testContext.eventReporter.isOnline) == true
                            expect(testContext.eventReporter.isReportingActive) == true
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 2 //1 retry attempt
                            expect(testContext.eventReporter.eventStoreKeys) == []
                            expect(testContext.eventReporter.eventStoreKinds.contains(.summary)) == false
                            expect(testContext.serviceMock.publishedEventDictionaryKeys) == testContext.eventKeys
                            expect(testContext.serviceMock.publishedEventDictionaryKinds?.contains(.summary)) == true
                            expect(testContext.eventReporter.lastEventResponseDate).to(beNil())
                            expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == false
                            guard case let .error(.request(error)) = testContext.syncResult
                            else {
                                fail("Expected error result for event send")
                                return
                            }
                            expect(error as NSError?) == DarklyServiceMock.Constants.error
                        }
                    }
                }
            }
            context("offline") {
                beforeEach {
                    waitUntil { syncComplete in
                        testContext = TestContext(eventStubResponseDate: eventStubResponseDate, onSyncComplete: { result in
                            testContext.syncResult = result
                            syncComplete()
                        })
                        testContext.addEvents(Event.Kind.nonSummaryKinds.count)
                        testContext.flagRequestTracker = FlagRequestTracker.stub()
                        testContext.eventReporter.setFlagRequestTracker(testContext.flagRequestTracker!)
                        testContext.eventReporter.flush(completion: nil)
                    }
                }
                it("doesn't report events") {
                    expect(testContext.eventReporter.isOnline) == false
                    expect(testContext.eventReporter.isReportingActive) == false
                    expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                    expect(testContext.eventReporter.eventStoreKeys) == testContext.eventKeys
                    expect(testContext.eventReporter.eventStoreKinds.contains(.summary)) == false
                    expect(testContext.eventReporter.lastEventResponseDate).to(beNil())
                    expect(testContext.eventReporter.flagRequestTracker.hasLoggedRequests) == true
                    guard case .error(.isOffline) = testContext.syncResult
                    else {
                        fail("Expected error .isOffline result for event send")
                        return
                    }
                }
            }
        }
    }

    private func recordFlagEvaluationEventsSpec() {
        describe("recordFlagEvaluationEvents") {
            recordFeatureAndDebugEventsSpec()
            trackFlagRequestSpec()
        }
    }

    private func recordFeatureAndDebugEventsSpec() {
        var testContext: TestContext!
        context("record feature and debug events") {
            context("when trackEvents is on and a reason is present") {
                beforeEach {
                    testContext = TestContext(trackEvents: true)
                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey,
                                                                         value: testContext.featureFlag.value!,
                                                                         defaultValue: Constants.defaultValue,
                                                                         featureFlag: testContext.featureFlagWithReason,
                                                                         user: testContext.user,
                                                                         includeReason: true)
                }
                it("records a feature event") {
                    expect(testContext.eventReporter.eventStore.count) == 1
                    expect(testContext.eventReporter.eventStoreKeys.contains(testContext.flagKey)).to(beTrue())
                    expect(testContext.eventReporter.eventStoreKinds.contains(.feature)).to(beTrue())
                }
                it("tracks the flag request") {
                    let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                    expect(flagValueCounter).toNot(beNil())
                    expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                    expect(flagValueCounter?.featureFlag) == testContext.featureFlagWithReason
                    expect(flagValueCounter?.isKnown) == true
                    expect(flagValueCounter?.count) == 1
                }
            }
            context("when a reason is present and reason is false but trackReason is true") {
                beforeEach {
                    testContext = TestContext(trackEvents: true)
                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey,
                                                                         value: testContext.featureFlag.value!,
                                                                         defaultValue: Constants.defaultValue,
                                                                         featureFlag: testContext.featureFlagWithReasonAndTrackReason,
                                                                         user: testContext.user,
                                                                         includeReason: false)
                }
                it("records a feature event") {
                    expect(testContext.eventReporter.eventStore.count) == 1
                    expect(testContext.eventReporter.eventStoreKeys.contains(testContext.flagKey)).to(beTrue())
                    expect(testContext.eventReporter.eventStoreKinds.contains(.feature)).to(beTrue())
                }
                it("tracks the flag request") {
                    let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                    expect(flagValueCounter).toNot(beNil())
                    expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                    expect(flagValueCounter?.featureFlag) == testContext.featureFlagWithReasonAndTrackReason
                    expect(flagValueCounter?.isKnown) == true
                    expect(flagValueCounter?.count) == 1
                }
            }
            context("when trackEvents is off") {
                beforeEach {
                    testContext = TestContext(trackEvents: false)
                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey,
                                                                         value: testContext.featureFlag.value!,
                                                                         defaultValue: Constants.defaultValue,
                                                                         featureFlag: testContext.featureFlag,
                                                                         user: testContext.user,
                                                                         includeReason: false)
                }
                it("does not record a feature event") {
                    expect(testContext.eventReporter.eventStore).to(beEmpty())
                }
                it("tracks the flag request") {
                    let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                    expect(flagValueCounter).toNot(beNil())
                    expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                    expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                    expect(flagValueCounter?.isKnown) == true
                    expect(flagValueCounter?.count) == 1
                }
            }
            context("when debugEventsUntilDate exists") {
                context("lastEventResponseDate exists") {
                    context("and debugEventsUntilDate is later") {
                        beforeEach {
                            testContext = TestContext(lastEventResponseDate: Date(), trackEvents: false, debugEventsUntilDate: Date().addingTimeInterval(TimeInterval.oneSecond))
                            testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value!, defaultValue: Constants.defaultValue, featureFlag: testContext.featureFlag, user: testContext.user, includeReason: false)
                        }
                        it("records a debug event") {
                            expect(testContext.eventReporter.eventStore.count) == 1
                            expect(testContext.eventReporter.eventStoreKeys.contains(testContext.flagKey)).to(beTrue())
                            expect(testContext.eventReporter.eventStoreKinds.contains(.debug)).to(beTrue())
                        }
                        it("tracks the flag request") {
                            let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                            expect(flagValueCounter).toNot(beNil())
                            expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                            expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                            expect(flagValueCounter?.isKnown) == true
                            expect(flagValueCounter?.count) == 1
                        }
                    }
                    context("and debugEventsUntilDate is earlier") {
                        beforeEach {
                            testContext = TestContext(lastEventResponseDate: Date(), trackEvents: false, debugEventsUntilDate: Date().addingTimeInterval(-TimeInterval.oneSecond))
                            testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value!, defaultValue: Constants.defaultValue, featureFlag: testContext.featureFlag, user: testContext.user, includeReason: false)
                        }
                        it("does not record a debug event") {
                            expect(testContext.eventReporter.eventStore).to(beEmpty())
                        }
                        it("tracks the flag request") {
                            let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                            expect(flagValueCounter).toNot(beNil())
                            expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                            expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                            expect(flagValueCounter?.isKnown) == true
                            expect(flagValueCounter?.count) == 1
                        }
                    }
                }
                context("lastEventResponseDate is nil") {
                    context("and debugEventsUntilDate is later than current time") {
                        beforeEach {
                            testContext = TestContext(lastEventResponseDate: nil, trackEvents: false, debugEventsUntilDate: Date().addingTimeInterval(TimeInterval.oneSecond))
                            testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value!, defaultValue: Constants.defaultValue, featureFlag: testContext.featureFlag, user: testContext.user, includeReason: false)
                        }
                        it("records a debug event") {
                            expect(testContext.eventReporter.eventStore.count) == 1
                            expect(testContext.eventReporter.eventStoreKeys.contains(testContext.flagKey)).to(beTrue())
                            expect(testContext.eventReporter.eventStoreKinds.contains(.debug)).to(beTrue())
                        }
                        it("tracks the flag request") {
                            let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                            expect(flagValueCounter).toNot(beNil())
                            expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                            expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                            expect(flagValueCounter?.isKnown) == true
                            expect(flagValueCounter?.count) == 1
                        }
                    }
                    context("and debugEventsUntilDate is earlier than current time") {
                        beforeEach {
                            testContext = TestContext(lastEventResponseDate: nil, trackEvents: false, debugEventsUntilDate: Date().addingTimeInterval(-TimeInterval.oneSecond))
                            testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value!, defaultValue: Constants.defaultValue, featureFlag: testContext.featureFlag, user: testContext.user, includeReason: false)
                        }
                        it("does not record a debug event") {
                            expect(testContext.eventReporter.eventStore).to(beEmpty())
                        }
                        it("tracks the flag request") {
                            let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                            expect(flagValueCounter).toNot(beNil())
                            expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                            expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                            expect(flagValueCounter?.isKnown) == true
                            expect(flagValueCounter?.count) == 1
                        }
                    }
                }
            }
            context("when both trackEvents is true and debugEventsUntilDate is later than lastEventResponseDate") {
                beforeEach {
                    testContext = TestContext(lastEventResponseDate: Date(), trackEvents: true, debugEventsUntilDate: Date().addingTimeInterval(TimeInterval.oneSecond))
                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value!, defaultValue: Constants.defaultValue, featureFlag: testContext.featureFlag, user: testContext.user, includeReason: false)
                }
                it("records a feature and debug event") {
                    expect(testContext.eventReporter.eventStore.count == 2).to(beTrue())
                    expect(testContext.eventReporter.eventStoreKeys.filter { eventKey in
                        eventKey == testContext.flagKey
                        }.count == 2).to(beTrue())
                    expect(Set(testContext.eventReporter.eventStore.eventKinds)).to(equal(Set([.feature, .debug])))
                }
                it("tracks the flag request") {
                    let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                    expect(flagValueCounter).toNot(beNil())
                    expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                    expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                    expect(flagValueCounter?.isKnown) == true
                    expect(flagValueCounter?.count) == 1
                }
            }
            context("when both trackEvents is true, debugEventsUntilDate is later than lastEventResponseDate, reason is false, and track reason is true") {
                beforeEach {
                    testContext = TestContext(lastEventResponseDate: Date(), trackEvents: true, debugEventsUntilDate: Date().addingTimeInterval(TimeInterval.oneSecond))
                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value!, defaultValue: Constants.defaultValue, featureFlag: testContext.featureFlagWithReasonAndTrackReason, user: testContext.user, includeReason: false)
                }
                it("records a feature and debug event") {
                    expect(testContext.eventReporter.eventStore.count == 2).to(beTrue())
                    expect(testContext.eventReporter.eventStore[0]["reason"] as? [String: Any] == DarklyServiceMock.Constants.reason).to(beTrue())
                    expect(testContext.eventReporter.eventStore[1]["reason"] as? [String: Any] == DarklyServiceMock.Constants.reason).to(beTrue())
                    expect(testContext.eventReporter.eventStoreKeys.filter { eventKey in
                        eventKey == testContext.flagKey
                        }.count == 2).to(beTrue())
                    expect(Set(testContext.eventReporter.eventStore.eventKinds)).to(equal(Set([.feature, .debug])))
                }
                it("tracks the flag request") {
                    let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                    expect(flagValueCounter).toNot(beNil())
                    expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                    expect(flagValueCounter?.featureFlag) == testContext.featureFlagWithReasonAndTrackReason
                    expect(flagValueCounter?.isKnown) == true
                    expect(flagValueCounter?.count) == 1
                }
            }
            context("when debugEventsUntilDate is nil") {
                beforeEach {
                    testContext = TestContext(lastEventResponseDate: Date(), trackEvents: false, debugEventsUntilDate: nil)
                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value!, defaultValue: Constants.defaultValue, featureFlag: testContext.featureFlag, user: testContext.user, includeReason: false)
                }
                it("does not record an event") {
                    expect(testContext.eventReporter.eventStore).to(beEmpty())
                }
                it("tracks the flag request") {
                    let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                    expect(flagValueCounter).toNot(beNil())
                    expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                    expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                    expect(flagValueCounter?.isKnown) == true
                    expect(flagValueCounter?.count) == 1
                }
            }
            context("when eventTrackingContext is nil") {
                beforeEach {
                    testContext = TestContext(trackEvents: nil)
                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey,
                                                                         value: testContext.featureFlag.value!,
                                                                         defaultValue: Constants.defaultValue,
                                                                         featureFlag: testContext.featureFlag,
                                                                         user: testContext.user,
                                                                         includeReason: false)
                }
                it("does not record an event") {
                    expect(testContext.eventReporter.eventStore).to(beEmpty())
                }
                it("tracks the flag request") {
                    let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                    expect(flagValueCounter).toNot(beNil())
                    expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                    expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                    expect(flagValueCounter?.isKnown) == true
                    expect(flagValueCounter?.count) == 1
                }
            }
            context("when multiple flag requests are made") {
                context("serially") {
                    beforeEach {
                        testContext = TestContext(flagRequestCount: 3, trackEvents: false)
                        for _ in 1...testContext.flagRequestCount {
                            testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey,
                                                                                 value: testContext.featureFlag.value!,
                                                                                 defaultValue: Constants.defaultValue,
                                                                                 featureFlag: testContext.featureFlag,
                                                                                 user: testContext.user,
                                                                                 includeReason: false)
                        }
                    }
                    it("tracks the flag request") {
                        let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                        expect(flagValueCounter).toNot(beNil())
                        expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                        expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                        expect(flagValueCounter?.isKnown) == true
                        expect(flagValueCounter?.count) == testContext.flagRequestCount
                    }
                }
                context("concurrently") {
                    let requestQueue = DispatchQueue(label: "com.launchdarkly.test.eventReporterSpec.flagRequestTracking.concurrent", qos: .userInitiated, attributes: .concurrent)
                    var recordFlagEvaluationCompletionCallCount = 0
                    var recordFlagEvaluationCompletion: (() -> Void)!
                    beforeEach {
                        testContext = TestContext(flagRequestCount: 5, trackEvents: false)

                        waitUntil { done in
                            recordFlagEvaluationCompletion = {
                                DispatchQueue.main.async {
                                    recordFlagEvaluationCompletionCallCount += 1
                                    if recordFlagEvaluationCompletionCallCount == testContext.flagRequestCount {
                                        done()
                                    }
                                }
                            }
                            let fireTime = DispatchTime.now() + 0.1
                            for _ in 1...testContext.flagRequestCount {
                                requestQueue.asyncAfter(deadline: fireTime) {
                                    testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey,
                                                                                         value: testContext.featureFlag.value!,
                                                                                         defaultValue: Constants.defaultValue,
                                                                                         featureFlag: testContext.featureFlag,
                                                                                         user: testContext.user,
                                                                                         includeReason: false)
                                    recordFlagEvaluationCompletion()
                                }
                            }
                        }
                    }
                    it("tracks the flag request") {
                        let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                        expect(flagValueCounter).toNot(beNil())
                        expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                        expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                        expect(flagValueCounter?.isKnown) == true
                        expect(flagValueCounter?.count) == testContext.flagRequestCount
                    }
                }
            }
        }
    }

    private func trackFlagRequestSpec() {
        context("record summary event") {
            var testContext: TestContext!
            beforeEach {
                testContext = TestContext()
                testContext.eventReporter.recordFlagEvaluationEvents(flagKey: testContext.flagKey, value: testContext.featureFlag.value, defaultValue: testContext.featureFlag.value, featureFlag: testContext.featureFlag, user: testContext.user, includeReason: false)
            }
            it("tracks flag requests") {
                let flagCounter = testContext.flagCounter(for: testContext.flagKey)
                expect(flagCounter).toNot(beNil())
                expect(AnyComparer.isEqual(flagCounter?.defaultValue, to: testContext.featureFlag.value, considerNilAndNullEqual: true)).to(beTrue())
                expect(flagCounter?.flagValueCounters.count) == 1

                let flagValueCounter = testContext.flagValueCounter(for: testContext.flagKey, and: testContext.featureFlag)
                expect(flagValueCounter).toNot(beNil())
                expect(AnyComparer.isEqual(flagValueCounter?.reportedValue, to: testContext.featureFlag.value)).to(beTrue())
                expect(flagValueCounter?.featureFlag) == testContext.featureFlag
                expect(flagValueCounter?.isKnown) == true
                expect(flagValueCounter?.count) == testContext.flagRequestCount
            }
        }
    }

    private func reportTimerSpec() {
        describe("report timer fires") {
            var testContext: TestContext!
            afterEach {
                testContext.eventReporter.isOnline = false
            }
            context("with events") {
                beforeEach {
                    testContext = TestContext(eventFlushInterval: Constants.eventFlushIntervalHalfSecond)
                    testContext.eventReporter.isOnline = true
                    waitUntil { done in
                        testContext.recordEvents(Event.Kind.allKinds.count, completion: done)
                    }
                }
                it("reports events") {
                    expect(testContext.serviceMock.publishEventDictionariesCallCount).toEventually(equal(1))
                    expect(testContext.serviceMock.publishedEventDictionaries?.count).toEventually(equal(testContext.events.count))
                    expect(testContext.serviceMock.publishedEventDictionaryKeys).toEventually(equal(testContext.eventKeys))
                    expect( testContext.eventReporter.eventStore.isEmpty).toEventually(beTrue())
                }
            }
            context("without events") {
                beforeEach {
                    testContext = TestContext(eventFlushInterval: Constants.eventFlushIntervalHalfSecond)
                    testContext.eventReporter.isOnline = true
                }
                it("doesn't report events") {
                    waitUntil { done in
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constants.eventFlushIntervalHalfSecond) {
                            expect(testContext.serviceMock.publishEventDictionariesCallCount) == 0
                            done()
                        }
                    }
                }
            }
        }
    }

    private func eventKeysSpec() {
        describe("eventKeys") {
            var testContext: TestContext!
            var eventKeys: String!
            context("when events exist") {
                beforeEach {
                    testContext = TestContext(eventCount: Event.Kind.allKinds.count)

                    eventKeys = testContext.eventReporter.eventStore.eventKeys
                }
                it("creates a list of keys that match the event keys") {
                    expect(eventKeys.isEmpty).to(beFalse())
                    expect(eventKeys.components(separatedBy: ", ").count) == Event.Kind.allKinds.count - 1  //summary events don't have a key
                    testContext.eventKeys.forEach { eventKey in
                        expect(eventKeys.contains(eventKey)).to(beTrue())
                    }
                }
            }
            context("when events do not exist") {
                beforeEach {
                    testContext = TestContext()

                    eventKeys = testContext.eventReporter.eventStore.eventKeys
                }
                it("returns an empty string") {
                    expect(eventKeys.isEmpty).to(beTrue())
                }
            }
        }
    }
}

extension EventReporter {
    var eventStoreKeys: [String] { eventStore.compactMap { $0.eventKey } }
    var eventStoreKinds: [Event.Kind] { eventStore.compactMap { $0.eventKind } }
}

extension TimeInterval {
    static let oneSecond: TimeInterval = 1.0
}

private extension Date {
    var adjustedForHttpUrlHeaderUse: Date {
        let headerDateFormatter = DateFormatter.httpUrlHeaderFormatter
        let dateString = headerDateFormatter.string(from: self)
        return headerDateFormatter.date(from: dateString) ?? self
    }
}

extension Event.Kind {
    static var nonSummaryKinds: [Event.Kind] {
        [feature, debug, identify, custom]
    }
}

// Performs set-wise equality, without ordering
extension Array where Element == [String: Any] {
    static func == (_ lhs: [[String: Any]], _ rhs: [[String: Any]]) -> Bool {
        // Same length and the left hand side does not contain any elements not in the right hand side
        return lhs.count == rhs.count && !lhs.contains { !rhs.contains($0) }
    }
}
