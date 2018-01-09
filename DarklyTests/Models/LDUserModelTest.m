//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LDUserModel.h"
#import "LDDataManager.h"
#import "LDUserModel.h"
#import "LDUserModel+Stub.h"
#import "LDUserModel+Testable.h"
#import "LDUserModel+Equatable.h"
#import "LDUserModel+JsonDecodeable.h"
#import "NSMutableDictionary+NullRemovable.h"
#import "NSString+RemoveWhitespace.h"

@interface LDUserModelTest : XCTestCase
@end

@implementation LDUserModelTest
- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testNewUserSetupProperly {
    LDUserModel *user = [[LDUserModel alloc] init];
    
    XCTAssertNotNil(user.os);
    XCTAssertNotNil(user.device);
    XCTAssertNotNil(user.updatedAt);
    XCTAssertNil(user.privateAttributes);
}

-(void)testDictionaryValueWithFlags_Yes_AndPrivateProperties_Yes {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allAttributes = [NSMutableArray arrayWithArray:[LDUserModel allUserAttributes]];
    [allAttributes addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *attribute in allAttributes) {
        config.privateUserAttributes = nil;
        userStub.privateAttributes = @[attribute];
        testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:YES privateAttributes:@[attribute]]);

        config.privateUserAttributes = @[attribute];
        userStub.privateAttributes = nil;
        testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:YES privateAttributes:@[attribute]]);
    }

    config.privateUserAttributes = allAttributes;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:YES privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = allAttributes;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:YES privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:YES privateAttributes:nil]);

    config.privateUserAttributes = @[];
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:YES privateAttributes:@[]]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = @[];
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:YES privateAttributes:@[]]);
}

-(void)testDictionaryValueWithFlags_Yes_AndPrivateProperties_No {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allAttributes = [NSMutableArray arrayWithArray:[LDUserModel allUserAttributes]];
    [allAttributes addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *attribute in allAttributes) {
        config.privateUserAttributes = nil;
        userStub.privateAttributes = @[attribute];
        testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:NO privateAttributes:@[attribute]]);

        config.privateUserAttributes = @[attribute];
        userStub.privateAttributes = nil;
        testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:NO privateAttributes:@[attribute]]);

    }

    config.privateUserAttributes = allAttributes;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:NO privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = allAttributes;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:NO privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:NO privateAttributes:nil]);

    config.privateUserAttributes = @[];
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:NO privateAttributes:@[]]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = @[];
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:YES includePrivateAttributes:NO privateAttributes:@[]]);
}

-(void)testDictionaryValueWithFlags_No_AndPrivateProperties_Yes {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allAttributes = [NSMutableArray arrayWithArray:[LDUserModel allUserAttributes]];
    [allAttributes addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *attribute in allAttributes) {
        config.privateUserAttributes = nil;
        userStub.privateAttributes = @[attribute];
        testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:YES privateAttributes:@[attribute]]);

        config.privateUserAttributes = @[attribute];
        userStub.privateAttributes = nil;
        testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:YES privateAttributes:@[attribute]]);

    }

    config.privateUserAttributes = allAttributes;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:YES privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = allAttributes;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:YES privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:YES privateAttributes:nil]);

    config.privateUserAttributes = @[];
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:YES privateAttributes:@[]]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = @[];
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:YES privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:YES privateAttributes:@[]]);
}

-(void)testDictionaryValueWithFlags_No_AndPrivateProperties_No {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allAttributes = [NSMutableArray arrayWithArray:[LDUserModel allUserAttributes]];
    [allAttributes addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *attribute in allAttributes) {
        config.privateUserAttributes = nil;
        userStub.privateAttributes = @[attribute];
        testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:NO privateAttributes:@[attribute]]);

        config.privateUserAttributes = @[attribute];
        userStub.privateAttributes = nil;
        testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:NO privateAttributes:@[attribute]]);

    }

    config.privateUserAttributes = allAttributes;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:NO privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = allAttributes;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:NO privateAttributes:allAttributes]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:NO privateAttributes:nil]);

    config.privateUserAttributes = @[];
    userStub.privateAttributes = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:NO privateAttributes:@[]]);

    config.privateUserAttributes = nil;
    userStub.privateAttributes = @[];
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateAttributes:NO privateAttributesFromConfig:config.privateUserAttributes];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeFlags:NO includePrivateAttributes:NO privateAttributes:@[]]);
}

-(void)testEncodeAndDecode {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allAttributes = [NSMutableArray arrayWithArray:[LDUserModel allUserAttributes]];
    [allAttributes addObjectsFromArray:userStub.custom.allKeys];
    userStub.privateAttributes = allAttributes;

    NSData *encodedUserData = [NSKeyedArchiver archivedDataWithRootObject:userStub];
    XCTAssertNotNil(encodedUserData);

    LDUserModel *decodedUser = [NSKeyedUnarchiver unarchiveObjectWithData:encodedUserData];
    XCTAssertTrue([userStub isEqual:decodedUser ignoringAttributes:@[kUserAttributeUpdatedAt]]);
}

-(void)testInitWithDictionary {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allAttributes = [NSMutableArray arrayWithArray:[LDUserModel allUserAttributes]];
    [allAttributes addObjectsFromArray:userStub.custom.allKeys];
    userStub.privateAttributes = allAttributes;

    NSDictionary *userDictionary = [userStub dictionaryValueWithFlags:YES includePrivateAttributes:YES privateAttributesFromConfig:nil includePrivateAttributeList:YES];
    XCTAssertTrue(userDictionary && [userDictionary count]);

    LDUserModel *reinflatedUser = [[LDUserModel alloc] initWithDictionary:userDictionary];
    XCTAssertTrue([userStub isEqual:reinflatedUser ignoringAttributes:nil]);
}

-(void)testConvertToJson {
    NSMutableDictionary *userDict = [self userDictionaryWithUserKey:@"aKey" userName:@"John_Doe" customDictionary:@{@"foo": @"Foo"}];   //Keep whitespace out of strings!!
    LDUserModel *user = [[LDUserModel alloc] initWithDictionary:userDict];
    [self validateUserModelIsEqualBehaviorUsingUserDictionary:userDict];
    NSString *jsonUser = [user convertToJson];

    //jsonUser contains no whitespace
    NSString *strippedJsonUser = [jsonUser stringByRemovingWhitespace];
    XCTAssertTrue([jsonUser isEqualToString:strippedJsonUser]);
    
    //jsonUser converts to the same user minus config
    NSArray<NSString*> *ignoredProperties = @[@"config", @"updatedAt"];
    XCTAssertTrue([user isEqual:[LDUserModel userFrom:jsonUser] ignoringAttributes:ignoredProperties]);
}

- (void)testUserSave {
    NSString *userKey = [[NSUUID UUID] UUIDString];
    NSMutableDictionary *userDict = [self userDictionaryWithUserKey:userKey userName:@"John Doe" customDictionary:[self customDictionary]];
    [self validateUserModelIsEqualBehaviorUsingUserDictionary:userDict];
    LDUserModel *user = [[LDUserModel alloc] initWithDictionary:userDict];
    
    [[LDDataManager sharedManager] saveUser:user];
    
    LDUserModel *retrievedUser = [[LDDataManager sharedManager] findUserWithkey:userKey];
    XCTAssertTrue([user isEqual:retrievedUser ignoringAttributes:@[@"updatedAt"]]);
}

-(void)testUserBackwardsCompatibility {
    NSString *userKey = [[NSUUID UUID] UUIDString];
    NSMutableDictionary *userDict = [self userDictionaryWithUserKey:userKey userName:@"John Doe" customDictionary:[self customDictionary]];
    LDUserModel *user = [[LDUserModel alloc] initWithDictionary:userDict];
    [self validateUserModelIsEqualBehaviorUsingUserDictionary:userDict];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[LDDataManager sharedManager] saveUserDeprecated:user];
#pragma clang diagnostic pop
    
    LDUserModel *retrievedUser = [[LDDataManager sharedManager] findUserWithkey:userKey];
    XCTAssertTrue([user isEqual:retrievedUser ignoringAttributes:@[@"updatedAt"]]);
}

#pragma mark - Helpers
///Trims out null values, and config
-(NSDictionary*)targetUserDictionaryFrom:(NSDictionary*)userDictionary withConfig:(BOOL)withConfig {
    NSMutableDictionary *target = [[NSMutableDictionary dictionaryWithDictionary:userDictionary] removeNullValues];
    
    //Remove config if needed
    target[@"config"] = withConfig ? target[@"config"] : nil;
    
    return [target copy];
}

//Verify LDUserModel isEqual is behaving as expected...important for forward compatability
-(void)validateUserModelIsEqualBehaviorUsingUserDictionary:(NSMutableDictionary*)userDictionary {
    LDUserModel *user = [[LDUserModel alloc] initWithDictionary:userDictionary];
    
    //Change the user dictionary & validate the users differ
    NSMutableDictionary *customDictionary = [NSMutableDictionary dictionaryWithDictionary:userDictionary[@"custom"]];
    customDictionary[@"os"] = @"ios 10.3";
    userDictionary[@"custom"] = [customDictionary copy];
    LDUserModel *changedUser = [[LDUserModel alloc] initWithDictionary:userDictionary];
    XCTAssertFalse([user isEqual:changedUser ignoringAttributes:@[@"updatedAt"]]);
}

-(NSDictionary*)serverJson {
    NSString *filepath = [[NSBundle bundleForClass:[LDUserModelTest class]] pathForResource:@"feature_flags"
                                                                                     ofType:@"json"];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    NSDictionary *serverJson = [NSJSONSerialization JSONObjectWithData:data
                                                               options:kNilOptions
                                                                 error:&error];
    return serverJson;
}

-(NSMutableDictionary*)customDictionary {
    return [NSMutableDictionary dictionaryWithDictionary:@{@"foo": @"Foo",
                                                           @"device": @"iPad",
                                                           @"os": @"IOS 9.2.1"}];
}

-(NSMutableDictionary*)userDictionaryWithUserKey:(NSString*)userKey userName:(NSString*)userName customDictionary:(NSDictionary*)customDictionary {
    return [[NSMutableDictionary alloc] initWithDictionary:@{ @"key": userKey,
                                                              @"ip": @"123.456.789",
                                                              @"country": @"USA",
                                                              @"name": userName,
                                                              @"firstName": @"John",
                                                              @"lastName": @"Doe",
                                                              @"email": @"jdub@g.com",
                                                              @"avatar": @"foo",
                                                              @"config": [self serverJson],
                                                              @"custom": [customDictionary copy],
                                                              @"anonymous": @1
                                                              }];
}
@end
