//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import "DarklyConstants.h"

NSString * const kClientVersion = @"2.3.0";
NSString * const kBaseUrl = @"https://app.launchdarkly.com";
NSString * const kEventsUrl = @"https://mobile.launchdarkly.com";
NSString * const kStreamUrl = @"https://clientstream.launchdarkly.com/mping";
NSString * const kNoMobileKeyExceptionName = @"NoMobileKeyDefinedException";
NSString * const kNoMobileKeyExceptionReason = @"A valid MobileKey must be provided";
NSString * const kNilConfigExceptionName = @"NilConfigException";
NSString * const kNilConfigExceptionReason = @"A valid LDConfig must be provided";
NSString * const kClientNotStartedExceptionName = @"ClientNotStartedException";
NSString * const kClientNotStartedExceptionReason = @"The LDClient must be started before this method can be called";
NSString * const kClientAlreadyStartedExceptionName = @"ClientAlreadyStartedException";
NSString * const kClientAlreadyStartedExceptionReason = @"The LDClient can only be started once";
NSString * const kIphone = @"iPhone";
NSString * const kIpad = @"iPad";
NSString * const kAppleWatch = @"Apple Watch";
NSString * const kAppleTV = @"Apple TV";
NSString * const kMacOS = @"macOS";
NSString * const kUserDictionaryStorageKey = @"ldUserModelDictionary";
NSString * const kDeviceIdentifierKey = @"ldDeviceIdentifier";
NSString * const kLDUserUpdatedNotification = @"Darkly.UserUpdatedNotification";
NSString * const kLDBackgroundFetchInitiated = @"Darkly.BackgroundFetchInitiated";
NSString *const kLDFlagConfigChangedNotification = @"Darkly.FlagConfigChangedNotification";
int const kCapacity = 100;
int const kConnectionTimeout = 10;
int const kDefaultFlushInterval = 30;
int const kMinimumFlushIntervalMillis = 0;
int const kDefaultPollingInterval = 300;
int const kMinimumPollingInterval = 60;
int const kMillisInSecs = 1000;
