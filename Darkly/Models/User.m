//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import "User.h"
#import "DarklyUtil.h"

@implementation User

@synthesize key;

- (instancetype)init {
    self = [super init];
    
    if(self != nil) {
        // Need to set device
        NSString *device = [DarklyUtil getDeviceAsString];
        DEBUG_LOG(@"User building User with device: %@", device);
        [self setDevice:device];
 
        // Need to set os
        NSString *systemVersion = [DarklyUtil getSystemVersionAsString];
        DEBUG_LOG(@"User building User with system version: %@", systemVersion);
        [self setOs:systemVersion];
        
        self.custom = @{};
    }
    
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    // mapping between json returned from API and mantle attributes goes here
    return @{  @"key": @"key",
               @"ip": @"ip",
               @"country": @"country",
               @"email": @"email",
               @"firstName": @"firstName",
               @"lastName": @"lastName",
               @"avatar": @"avatar",
               @"custom": @"custom",
               @"device": @"device",
               @"os": @"os",
               @"anonymous": @"anonymous"
               };
}

+ (NSDictionary *)managedObjectKeysByPropertyKey {
    // mapping between NSManagaedObject and Mantle object goes here
    return @{  @"key": @"key",
               @"ip": @"ip",
               @"country": @"country",
               @"email": @"email",
               @"firstName": @"firstName",
               @"lastName": @"lastName",
               @"avatar": @"avatar",
               @"custom": @"custom",
               @"device": @"device",
               @"os": @"os",
               @"config": @"config",
               @"anonymous": @"anonymous",
               @"updatedAt": @"updatedAt"
               };
}

+ (NSString *)managedObjectEntityName {
    return @"UserEntity";
}

+ (NSValueTransformer *)configTransformer {
    return [NSValueTransformer mtl_validatingTransformerForClass:[Config class]];
}

+ (NSDictionary *)relationshipModelClassesByPropertyKey {
    return @{
             @"config" : [Config class]
             };
}

-(BOOL) isFlagOn: ( NSString * __nonnull )keyName {
    return [self.config isFlagOn: keyName];
}

-(BOOL) doesFlagExist: ( NSString * __nonnull )keyName {
    return [self.config doesFlagExist: keyName];
}

-(void)key: (NSString *)aKey {
    if (aKey.length > 0) {
        key = aKey;
        self.anonymous = NO;
    } else {
        self.anonymous = YES;
        NSString *uniqueKey = [[NSUUID UUID] UUIDString];
        DEBUG_LOG(@"User key set to blank/nil changing to anonymous with NSUUID: %@", uniqueKey);
        key = uniqueKey;
    }
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *modifiedDictionaryValue = [[super dictionaryValue] mutableCopy];
    
    for (NSString *originalKey in [super dictionaryValue]) {
        id propertyValue = [self valueForKey:originalKey];
        if ( propertyValue == nil ||
            [originalKey isEqualToString: @"config"] ||
            ([originalKey isEqualToString: @"custom"] &&
             [(NSDictionary *)propertyValue count] == 0)) {
            [modifiedDictionaryValue removeObjectForKey:originalKey];
        }
    }
    
    return [modifiedDictionaryValue copy];
}

@end
