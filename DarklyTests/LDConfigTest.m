//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import "LDConfig.h"
#import "DarklyXCTestCase.h"

@interface LDConfigTest : DarklyXCTestCase

@end

@implementation LDConfigTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConfigDefaultValues {
    NSString *testMobileKey = @"testMobileKey";
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:testMobileKey];
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertEqualObjects([config capacity], [NSNumber numberWithInt:kCapacity]);
    XCTAssertEqualObjects([config connectionTimeout], [NSNumber numberWithInt:kConnectionTimeout]);
    XCTAssertEqualObjects([config flushInterval], [NSNumber numberWithInt:kDefaultFlushInterval]);
    XCTAssertFalse([config debugEnabled]);
}

- (void)testConfigOverrideBaseUrl {
    NSString *testMobileKey = @"testMobileKey";
    NSString *testBaseUrl = @"testBaseUrl";
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:testMobileKey];
    config.baseUrl = testBaseUrl;
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertEqualObjects([config capacity], [NSNumber numberWithInt:kCapacity]);
    XCTAssertEqualObjects([config connectionTimeout], [NSNumber numberWithInt:kConnectionTimeout]);
    XCTAssertEqualObjects([config flushInterval], [NSNumber numberWithInt:kDefaultFlushInterval]);
    XCTAssertFalse([config debugEnabled]);
}

- (void)testConfigOverrideCapacity {
    NSString *testMobileKey = @"testMobileKey";
    int testCapacity = 20;
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:testMobileKey];
    config.capacity = [NSNumber numberWithInt:testCapacity];
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertEqualObjects([config capacity], [NSNumber numberWithInt:testCapacity]);
    XCTAssertEqualObjects([config connectionTimeout], [NSNumber numberWithInt:kConnectionTimeout]);
    XCTAssertEqualObjects([config flushInterval], [NSNumber numberWithInt:kDefaultFlushInterval]);
    XCTAssertFalse([config debugEnabled]);
}

- (void)testConfigOverrideConnectionTimeout {
    NSString *testMobileKey = @"testMobileKey";
    int testConnectionTimeout = 15;
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:testMobileKey];
    config.connectionTimeout = [NSNumber numberWithInt:testConnectionTimeout];
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertEqualObjects([config capacity], [NSNumber numberWithInt:kCapacity]);
    XCTAssertEqualObjects([config connectionTimeout], [NSNumber numberWithInt:testConnectionTimeout]);
    XCTAssertEqualObjects([config flushInterval], [NSNumber numberWithInt:kDefaultFlushInterval]);
    XCTAssertFalse([config debugEnabled]);
}

- (void)testConfigOverrideFlushInterval {
    NSString *testMobileKey = @"testMobileKey";
    int testFlushInterval = 5;
    LDConfigBuilder *builder = [[LDConfigBuilder alloc] init];
    [builder withMobileKey:testMobileKey];
    [builder withFlushInterval:testFlushInterval];
    LDConfig *config = [builder build];
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertEqualObjects([config capacity], [NSNumber numberWithInt:kCapacity]);
    XCTAssertEqualObjects([config connectionTimeout], [NSNumber numberWithInt:kConnectionTimeout]);
    XCTAssertEqualObjects([config flushInterval], [NSNumber numberWithInt:testFlushInterval]);
    XCTAssertFalse([config debugEnabled]);
}

- (void)testConfigOverridePollingInterval {
    NSString *testMobileKey = @"testMobileKey";
    LDConfigBuilder *builder = [[LDConfigBuilder alloc] init];
    [builder withMobileKey:testMobileKey];
    
    LDConfig *config = [builder build];
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertEqualObjects([config pollingInterval], [NSNumber numberWithInt:kDefaultPollingInterval]);
    XCTAssertFalse([config debugEnabled]);
    
    [builder withPollingInterval:5000];
    config = [builder build];
    XCTAssertEqualObjects([config pollingInterval], [NSNumber numberWithInt:5000]);
    
    [builder withPollingInterval:50];
    config = [builder build];
    XCTAssertEqualObjects([config pollingInterval], [NSNumber numberWithInt:kMinimumPollingInterval]);
}

- (void)testConfigOverrideStreaming {
    NSString *testMobileKey = @"testMobileKey";
    LDConfigBuilder *builder = [[LDConfigBuilder alloc] init];
    [builder withMobileKey:testMobileKey];
    
    LDConfig *config = [builder build];
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertTrue([config streaming]);
    
    [builder withStreaming:NO];
    config = [builder build];
    XCTAssertFalse([config streaming]);
}

- (void)testConfigOverrideDebug {
    NSString *testMobileKey = @"testMobileKey";
    LDConfigBuilder *builder = [[LDConfigBuilder alloc] init];
    [builder withMobileKey:testMobileKey];
    [builder withDebugEnabled:YES];
    LDConfig *config = [builder build];
    XCTAssertEqualObjects([config mobileKey], testMobileKey);
    XCTAssertEqualObjects([config capacity], [NSNumber numberWithInt:kCapacity]);
    XCTAssertEqualObjects([config connectionTimeout], [NSNumber numberWithInt:kConnectionTimeout]);
    XCTAssertEqualObjects([config flushInterval], [NSNumber numberWithInt:kDefaultFlushInterval]);
    XCTAssertTrue([config debugEnabled]);
}

@end
