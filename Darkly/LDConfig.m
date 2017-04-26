//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import "LDConfig.h"
#import "LDUtil.h"

@interface LDConfig()
@property (nonatomic, copy, nonnull) NSString* mobileKey;
@end

@implementation LDConfig

- (instancetype)initWithMobileKey:(NSString *)mobileKey {
    if (!(self = [super init])) {
        return nil;
    }

    self.mobileKey = mobileKey;
    self.streaming = YES;
    self.capacity = [NSNumber numberWithInt:kCapacity];
    self.connectionTimeout = [NSNumber numberWithInt:kConnectionTimeout];
    self.flushInterval = [NSNumber numberWithInt:kDefaultFlushInterval];
    self.pollingInterval = [NSNumber numberWithInt:kDefaultPollingInterval];
    self.baseUrl = kBaseUrl;
    self.eventsUrl = kEventsUrl;

    return self;
}

- (void)setMobileKey:(NSString *)mobileKey {
    _mobileKey = [mobileKey copy];
    DEBUG_LOG(@"Set LDConfig mobileKey: %@", mobileKey);
}

- (void)setBaseUrl:(NSString *)baseUrl {
    if (baseUrl) {
        DEBUG_LOG(@"Set LDConfig baseUrl: %@", baseUrl);
        _baseUrl = [baseUrl copy];
    } else {
        DEBUG_LOG(@"Set LDConfig default baseUrl: %@", kBaseUrl);
        _baseUrl = kBaseUrl;
    }
}

- (void)setEventsUrl:(NSString *)eventsUrl {
    if (eventsUrl) {
        DEBUG_LOG(@"Set LDConfig eventsUrl: %@", eventsUrl);
        _eventsUrl = [eventsUrl copy];
    } else {
        DEBUG_LOG(@"Set LDConfig default eventsUrl: %@", kEventsUrl);
        _eventsUrl = kEventsUrl;
    }
}

- (void)setCapacity:(NSNumber *)capacity {
    if (capacity) {
        DEBUG_LOG(@"Set LDConfig capacity: %@", capacity);
        _capacity = capacity;

    } else {
        DEBUG_LOG(@"Set LDConfig default capacity: %d", kCapacity);
        _capacity = [NSNumber numberWithInt:kCapacity];
    }
}

- (void)setConnectionTimeout:(NSNumber *)connectionTimeout {
    if (connectionTimeout) {
        DEBUG_LOG(@"Set LDConfig timeout: %@", connectionTimeout);
        _connectionTimeout = connectionTimeout;
    } else {
        DEBUG_LOG(@"Set LDConfig default timeout: %d", kConnectionTimeout);
        _connectionTimeout = [NSNumber numberWithInt:kConnectionTimeout];
    }
}

- (void)setFlushInterval:(NSNumber *)flushInterval {
    if (flushInterval) {
        DEBUG_LOG(@"Set LDConfig flush interval: %@", flushInterval);
        _flushInterval = flushInterval;
    } else {
        DEBUG_LOG(@"Set LDConfig default flush interval: %d", kDefaultFlushInterval);
        _flushInterval = [NSNumber numberWithInt:kDefaultFlushInterval];
    }
}

- (void)setPollingInterval:(NSNumber *)pollingInterval {
    if (pollingInterval) {
        DEBUG_LOG(@"Set LDConfig polling interval: %@", pollingInterval);
        _pollingInterval = [NSNumber numberWithInt:MAX(pollingInterval.intValue, kMinimumPollingInterval)];
    } else {
        DEBUG_LOG(@"Set LDConfig default polling interval: %d", kDefaultPollingInterval);
        _pollingInterval = [NSNumber numberWithInt:kDefaultPollingInterval];
    }
}

- (void)setStreaming:(BOOL)streaming {
    _streaming = streaming;
    DEBUG_LOG(@"Set LDConfig streaming enabled: %d", streaming);
}

- (void)setDebugEnabled:(BOOL)debugEnabled {
    _debugEnabled = debugEnabled;
    DEBUG_LOG(@"Set LDConfig debug enabled: %d", debugEnabled);
}

@end
