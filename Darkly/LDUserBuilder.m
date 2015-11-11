//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//


#import "LDUserBuilder.h"
#import "DarklyUtil.h"
#import "DataManager.h"
#import "UserEntity.h"

@interface LDUserBuilder() {
    NSString *key;
    NSString *ip;
    NSString *country;
    NSString *firstName;
    NSString *lastName;
    NSString *email;
    NSString *avatar;
    NSMutableDictionary *customDict;
    BOOL anonymous;
}

@end

@implementation LDUserBuilder

+ (User *)compareNewBuilder:(LDUserBuilder *)iBuilder withUser:(User *)iUser {
    if (iBuilder->key) {
        [iUser key:iBuilder->key];
    }
    if (iBuilder->ip || [iUser ip]) {
        [iUser setIp:iBuilder->ip];
    }
    if (iBuilder->country || [iUser country]) {
        [iUser setCountry:iBuilder->country];
    }
    if (iBuilder->firstName || [iUser firstName]) {
        [iUser setFirstName:iBuilder->firstName];
    }
    if (iBuilder->lastName || [iUser lastName]) {
        [iUser setLastName:iBuilder->lastName];
    }
    if (iBuilder->email || [iUser email]) {
        [iUser setEmail:iBuilder->email];
    }
    if (iBuilder->avatar || [iUser avatar]) {
        [iUser setAvatar:iBuilder->avatar];
    }
    if ((iBuilder->customDict && [iBuilder->customDict count]) || ([iUser custom] && [[iUser custom] count])) {
        [iUser setCustom:iBuilder->customDict];
    }
    [iUser setAnonymous:iBuilder->anonymous];
    return iUser;
}

+ (LDUserBuilder *)retrieveCurrentBuilder:(User *)iUser {
    LDUserBuilder *userBuilder = [[LDUserBuilder alloc] init];
    if ([iUser key]) {
        [userBuilder withKey:[iUser key]];
    }
    if ([iUser ip]) {
        [userBuilder withIp:[iUser ip]];
    }
    if ([iUser country]) {
        [userBuilder withCountry:[iUser country]];
    }
    if ([iUser firstName]) {
        [userBuilder withFirstName:[iUser firstName]];
    }
    if ([iUser lastName]) {
        [userBuilder withLastName:[iUser lastName]];
    }
    if ([iUser email]) {
        [userBuilder withEmail:[iUser email]];
    }
    if ([iUser avatar]) {
        [userBuilder withAvatar:[iUser avatar]];
    }
    if ([iUser custom] && [[iUser custom] count]) {
        [userBuilder withCustomDictionary:[[iUser custom] mutableCopy]];
    }
    [userBuilder withAnonymous:[iUser anonymous]];
    return userBuilder;
}

- (id)init {
    self = [super init];
    customDict = [[NSMutableDictionary alloc] init];
    return self;
}

- (LDUserBuilder *)withKey:(NSString *)inputKey
{
    key = inputKey;
    return self;
}

- (LDUserBuilder *)withIp:(NSString *)inputIp
{
    ip = inputIp;
    return self;
}

- (LDUserBuilder *)withCountry:(NSString *)inputCountry
{
    country = inputCountry;
    return self;
}

- (LDUserBuilder *)withFirstName:(NSString *)inputFirstName
{
    firstName = inputFirstName;
    return self;
}

- (LDUserBuilder *)withLastName:(NSString *)inputLastName
{
    lastName = inputLastName;
    return self;
}

- (LDUserBuilder *)withEmail:(NSString *)inputEmail
{
    email = inputEmail;
    return self;
}

- (LDUserBuilder *)withAvatar:(NSString *)inputAvatar
{
    avatar = inputAvatar;
    return self;
}

- (LDUserBuilder *)withCustomString:(NSString *)inputKey value:(NSString *)value
{
    [customDict setObject:value forKey:inputKey];
    return self;
}

- (LDUserBuilder *)withCustomBool:(NSString *)inputKey value:(BOOL)value
{
    [customDict setObject:[NSNumber numberWithBool:value] forKey:inputKey];
    return self;
}

- (LDUserBuilder *)withCustomNumber:(NSString *)inputKey value:(NSNumber *)value
{
    [customDict setObject:value forKey:inputKey];
    return self;
}

- (LDUserBuilder *)withCustomArray:(NSString *)inputKey value:(NSArray *)value
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    for (id myArrayElement in value) {
        if ([myArrayElement isKindOfClass:[NSString class]]) {
            [resultArray addObject:myArrayElement];
        } else if ([myArrayElement isKindOfClass:[NSNumber class]]) {
            [resultArray addObject:myArrayElement];
        } else if (myArrayElement) {
            [resultArray addObject:[NSNumber numberWithBool:YES]];
        } else {
            [resultArray addObject:[NSNumber numberWithBool:NO]];
        }
    }
    if ([resultArray count]) {
        [customDict setObject:resultArray forKey:inputKey];
    }
    return self;
}

- (LDUserBuilder *)withCustomDictionary:(NSMutableDictionary *)inputDictionary
{
    customDict = inputDictionary;
    return self;
}

- (LDUserBuilder *)withAnonymous:(BOOL)inputAnonymous {
    anonymous = inputAnonymous;
    return self;
}

-(User *)build {
    DEBUG_LOGX(@"LDUserBuilder build method called");
    User *user = nil;
    
    if (key) {
        if(!(user = [[DataManager sharedManager] findUserWithkey:key])) {
            user = [[User alloc] init];
        }
        [user key:key];
        DEBUG_LOG(@"LDUserBuilder building User with key: %@", key);
    } else {
        NSString *uniqueKey = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        DEBUG_LOG(@"LDUserBuilder building User with key: %@", uniqueKey);

        user = [[User alloc] init];
        [user key:uniqueKey];
        if (!anonymous) {
            Boolean currentAnonymous = YES;
            [user setAnonymous:currentAnonymous];
        }
    }
    if (ip) {
        DEBUG_LOG(@"LDUserBuilder building User with ip: %@", ip);
        [user setIp:ip];
    }
    if (country) {
        DEBUG_LOG(@"LDUserBuilder building User with country: %@", country);
        [user setCountry:country];
    }
    if (firstName) {
        DEBUG_LOG(@"LDUserBuilder building User with firstName: %@", firstName);
        [user setFirstName:firstName];
    }
    if (lastName) {
        DEBUG_LOG(@"LDUserBuilder building User with lastName: %@", lastName);
        [user setLastName:lastName];
    }
    if (email) {
        DEBUG_LOG(@"LDUserBuilder building User with email: %@", email);
        [user setEmail:email];
    }
    if (avatar) {
        DEBUG_LOG(@"LDUserBuilder building User with avatar: %@", avatar);
        [user setAvatar:avatar];
    }
    if ([customDict count]) {
        DEBUG_LOG(@"LDUserBuilder building User with custom: %@", customDict);
        [user setCustom:customDict];
    }
    if (anonymous) {
        Boolean currentAnonymous = anonymous;
        [user setAnonymous:currentAnonymous];
    }
    DEBUG_LOG(@"LDUserBuilder building User with anonymous: %d", anonymous);
    [self saveUser: user];
    return user;
}

-(void) saveUser: (User *) user {
    UserEntity *userEntity = [[DataManager sharedManager] findUserEntityWithkey:key];
    
    if(!userEntity) {
        [MTLManagedObjectAdapter managedObjectFromModel: user
                                   insertingIntoContext: [[DataManager sharedManager] managedObjectContext]
                                                  error: nil];
    } else {
        userEntity.key = user.key;
        userEntity.anonymous = [NSNumber numberWithBool: user.anonymous];
        userEntity.avatar = user.avatar;
        userEntity.country = user.country;
        userEntity.custom = user.custom;
        userEntity.device = user.device;
        userEntity.email = user.email;
        userEntity.firstName = user.firstName;
        userEntity.ip = user.ip;
        userEntity.lastName = user.lastName;
        userEntity.os = user.os;
        userEntity.updatedAt = [NSDate date];
    }                       
    
    [[DataManager sharedManager] saveContext];
}

@end
