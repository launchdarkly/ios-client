//
//  LDFlagValueCounterTest.m
//  DarklyTests
//
//  Created by Mark Pokorny on 4/18/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LDFlagValueCounter.h"
#import "LDFlagValueCounter+Testable.h"
#import "LDFlagConfigModel.h"
#import "LDFlagConfigModel+Testable.h"
#import "LDFlagConfigValue.h"

extern const NSInteger kLDFlagConfigVersionDoesNotExist;
extern const NSInteger kLDFlagConfigVariationDoesNotExist;

@interface LDFlagValueCounterTest : XCTestCase
@property (nonatomic, strong) NSDictionary<NSString*, LDFlagConfigValue*> *flagConfigDictionary;
@end

@implementation LDFlagValueCounterTest

- (void)setUp {
    [super setUp];
    self.flagConfigDictionary = [LDFlagConfigModel flagConfigFromJsonFileNamed:@"featureFlags-withVersions"].featuresJsonDictionary;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testInitAndCounterWithValueConstructors {
    for (NSString *flagKey in self.flagConfigDictionary.allKeys) {
        LDFlagConfigValue *flagConfigValue = self.flagConfigDictionary[flagKey];
        NSInteger variation = arc4random_uniform(9) + 1;    //TODO: When adding the new streaming data model, replace this with the value from the flagConfigValue

        LDFlagValueCounter *flagValueCounter = [LDFlagValueCounter counterWithValue:flagConfigValue.value variation:variation version:flagConfigValue.version isKnownValue:YES];

        XCTAssertEqualObjects(flagValueCounter.value, flagConfigValue.value);
        XCTAssertEqual(flagValueCounter.variation, variation);
        XCTAssertEqual(flagValueCounter.version, flagConfigValue.version);
        XCTAssertEqual(flagValueCounter.count, 1);
        XCTAssertEqual(flagValueCounter.known, YES);
    }
}

-(void)testDictionaryValue {
    for (NSString *flagKey in self.flagConfigDictionary.allKeys) {
        LDFlagConfigValue *flagConfigValue = self.flagConfigDictionary[flagKey];
        NSInteger variation = arc4random_uniform(9) + 1;    //TODO: When adding the new streaming data model, replace this with the value from the flagConfigValue
        LDFlagValueCounter *flagValueCounter = [LDFlagValueCounter counterWithValue:flagConfigValue.value variation:variation version:flagConfigValue.version isKnownValue:YES];

        NSDictionary *flagValueCounterDictionary = [flagValueCounter dictionaryValue];

        XCTAssertTrue([flagValueCounter hasPropertiesMatchingDictionary:flagValueCounterDictionary]);

        //Unknown flag config values
        flagValueCounter = [LDFlagValueCounter counterWithValue:flagConfigValue.value variation:kLDFlagConfigVariationDoesNotExist version:flagConfigValue.version isKnownValue:NO];

        flagValueCounterDictionary = [flagValueCounter dictionaryValue];

        XCTAssertTrue([flagValueCounter hasPropertiesMatchingDictionary:flagValueCounterDictionary]);
    }
}

@end
