//
//  ClientServiceMockFactory.swift
//  DarklyTests
//
//  Created by Mark Pokorny on 11/13/17. +JMJ
//  Copyright © 2017 LaunchDarkly. All rights reserved.
//

@testable import Darkly

struct ClientServiceMockFactory: ClientServiceCreating {
    func makeKeyedValueCache() -> KeyedValueCaching {
        return KeyedValueCachingMock()
    }

    func makeCacheConverter() -> UserCacheConverting {
        return makeCacheConverter(keyStore: KeyedValueCachingMock())
    }

    func makeCacheConverter(keyStore: KeyedValueCaching) -> UserCacheConverting {
        return UserCacheConverter(keyStore: keyStore, flagCollectionCache: FlagCollectionCachingMock())
    }

    func makeFlagCollectionCache(keyStore: KeyedValueCaching) -> FlagCollectionCaching {
        return FlagCollectionCachingMock()
    }

    var userFlagCache = UserFlagCachingMock()
    func makeUserFlagCache() -> UserFlagCaching {
        return userFlagCache
    }

    func makeUserFlagCache(flagCollectionStore: FlagCollectionCaching) -> UserFlagCaching {
        return userFlagCache
    }

    func makeFlagCache(maxCachedValues: Int) -> UserFlagCache {
        return UserFlagCache(flagCollectionStore: FlagCollectionCachingMock())
    }

    func makeFlagCache() -> UserFlagCache {
        return UserFlagCache(flagCollectionStore: FlagCollectionCachingMock())
    }

    func makeDarklyServiceProvider(mobileKey: String, config: LDConfig, user: LDUser) -> DarklyServiceProvider {
        return DarklyServiceMock(config: config, user: user)
    }

    var makeFlagSynchronizerCallCount = 0
    var makeFlagSynchronizerReceivedParameters: (streamingMode: LDStreamingMode, pollingInterval: TimeInterval, service: DarklyServiceProvider)? = nil
    mutating func makeFlagSynchronizer(streamingMode: LDStreamingMode, pollingInterval: TimeInterval, service: DarklyServiceProvider, onSync: FlagsReceivedClosure?, onError: SynchronizingErrorClosure?) -> LDFlagSynchronizing {
        makeFlagSynchronizerCallCount += 1
        makeFlagSynchronizerReceivedParameters = (streamingMode, pollingInterval, service)
        return LDFlagSynchronizingMock()
    }

    func makeEventReporter(mobileKey: String, config: LDConfig, service: DarklyServiceProvider) -> LDEventReporting {
        let reporterMock = LDEventReportingMock()
        reporterMock.config = config
        return reporterMock
    }
}