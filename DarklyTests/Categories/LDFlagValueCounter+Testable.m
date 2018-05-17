//
//  LDFlagValueCounter+Testable.m
//  DarklyTests
//
//  Created by Mark Pokorny on 4/18/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

#import "LDFlagValueCounter+Testable.h"
#import "LDFlagConfigValue+Testable.h"

@implementation LDFlagValueCounter(Testable)
-(BOOL)hasPropertiesMatchingDictionary:(NSDictionary*)dictionary {
    NSMutableArray<NSString*> *mismatchedProperties = [NSMutableArray array];
    if (self.known) {
        if (self.flagConfigValue) {
            if (![self.flagConfigValue hasPropertiesMatchingDictionary:dictionary]) {
                [mismatchedProperties addObject:kLDFlagValueCounterKeyFlagConfigValue];
            }
        } else {
            if (![self.value isEqual:dictionary[kLDFlagValueCounterKeyValue]]) {
                [mismatchedProperties addObject:kLDFlagValueCounterKeyValue];
            }
            if (self.version != [dictionary[kLDFlagValueCounterKeyVersion] integerValue]) {
                [mismatchedProperties addObject:kLDFlagValueCounterKeyVersion];
            }
            if (self.variation != [dictionary[kLDFlagValueCounterKeyVariation] integerValue]) {
                [mismatchedProperties addObject:kLDFlagValueCounterKeyVariation];
            }
        }
        if (dictionary[kLDFlagValueCounterKeyUnknown]) {
            [mismatchedProperties addObject:kLDFlagValueCounterKeyUnknown];
        }
    } else {
        if (dictionary[kLDFlagValueCounterKeyFlagConfigValue]) {
            [mismatchedProperties addObject:kLDFlagValueCounterKeyFlagConfigValue];
        }
        if (dictionary[kLDFlagValueCounterKeyValue]) {
            [mismatchedProperties addObject:kLDFlagValueCounterKeyValue];
        }
        if (dictionary[kLDFlagValueCounterKeyVersion]) {
            [mismatchedProperties addObject:kLDFlagValueCounterKeyVersion];
        }
        if (dictionary[kLDFlagValueCounterKeyVariation]) {
            [mismatchedProperties addObject:kLDFlagValueCounterKeyVariation];
        }
        if ([dictionary[kLDFlagValueCounterKeyUnknown] boolValue] != YES) {
            [mismatchedProperties addObject:kLDFlagValueCounterKeyUnknown];
        }
    }
    if (self.count != [dictionary[kLDFlagValueCounterKeyCount] integerValue]) {
        [mismatchedProperties addObject:kLDFlagValueCounterKeyCount];
    }

    if (mismatchedProperties.count > 0) {
        NSLog(@"[%@ %@] unequal properties: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [mismatchedProperties componentsJoinedByString:@", "]);
        return NO;
    }

    return YES;
}
@end
