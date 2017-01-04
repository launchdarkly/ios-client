//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//


#import "LDUtil.h"


@implementation LDUtil


+ (void)assertThreadIsNotMain
{
#ifndef NDEBUG
    if ([LDUtil getSystemVersionAsAnInteger] >= __IPHONE_4_0 &&
        ![[[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIApplicationExitsOnSuspend"] boolValue])
    {
        assert(![NSThread isMainThread]);
    }
#endif
}

+ (BOOL)isIPad
{
#if TARGET_OS_OSX
    return NO;
#else
    if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] &&
        [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        return YES;
    }
    return NO;
#endif
}

+ (BOOL)isRetina
{
#if TARGET_OS_OSX
    NSScreen *curScreen = [NSScreen mainScreen];
    // Not sure exactly if this will work on macOS
    if (curScreen.backingScaleFactor == 2.0) {
        return YES;
    } else {
        return NO;
    }
#else
    UIScreen *curScreen = [UIScreen mainScreen];

    if ([curScreen respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([curScreen respondsToSelector:@selector(scale)])) {
        if (curScreen.scale == 2.0) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
#endif

}

+ (NSString *)getDeviceAsString
{
    if ([self isIPad]) {
        return kIpad;
    } else {
        return kIphone;
    }
}

+ (NSString *)getSystemVersionAsString
{
#if TARGET_OS_OSX
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
#else
    return [[UIDevice currentDevice] systemVersion];
#endif
}

+ (NSInteger)getSystemVersionAsAnInteger {
    int index = 0;
    static NSInteger version = 0;
    
    @synchronized (self) {
        if(version != 0) {
            // PRIVATE_LOG(@"Darkly: System version found already. [%d]", version);
            return version;
        }

#if TARGET_OS_OSX
        // This may not be the best way to do this on macOS because in the docs it says this:
        //      "This string is not appropriate for parsing"
        NSString* systemVersion = [[NSProcessInfo processInfo] operatingSystemVersionString];
#else
        NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
#endif
        
        NSArray* digits = [systemVersion componentsSeparatedByString:@"."];
        NSEnumerator* enumer = [digits objectEnumerator];
        NSString* number;
        while (number = [enumer nextObject]) {
            if (index>2) {
                break;
            }
            NSInteger multipler = powf(100, 2-index);
            version += [number intValue]*multipler;
            index++;
        }
        
        // PRIVATE_LOG(@"Darkly: System version [%d]", version);
    }
    return version;
}

static DarklyLogLevel gLogLevel = DarklyLogLevelCriticalOnly;


+ (void)setLogLevel:(DarklyLogLevel)value
{
    DEBUG_LOG(@"DarklyUtil LogLevel set to: %u", value);
    gLogLevel = value;
}

+ (DarklyLogLevel)logLevel
{
    return gLogLevel;
}

+ (NSString *)base64EncodeString:(NSString *)unencodedString
{
    DEBUG_LOG(@"DarklyUtil base64EncodeString method called on string: %@", unencodedString);
    NSData *plainData = [unencodedString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    return base64String;
}

+ (NSString *)base64DecodeString:(NSString *)encodedString
{
    DEBUG_LOG(@"DarklyUtil base64DecodeString method called on string: %@", encodedString);
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    return decodedString;
}

+ (void)throwException:(NSString *)name reason:(NSString *)reason
{
    NSException *e = [NSException
                      exceptionWithName:name
                      reason:reason
                      userInfo:nil];
    @throw e;
}


@end
