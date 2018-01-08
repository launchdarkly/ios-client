//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LDUserModel.h"
#import "LDDataManager.h"
#import "LDUserModel.h"
#import "LDUserModel+Stub.h"
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
}

-(void)testDictionaryValueWithFlags_Yes_AndPrivateProperties_Yes {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allProperties = [NSMutableArray arrayWithArray:[LDUserModel allUserPropertyNames]];
    [allProperties addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *propertyName in allProperties) {
        config.privatePropertyNames = @[propertyName];
        testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:YES privateProperties:config.privatePropertyNames];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);
    }

    config.privatePropertyNames = allProperties;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:YES privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:YES privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = @[];
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:YES privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);
}

-(void)testDictionaryValueWithFlags_Yes_AndPrivateProperties_No {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allProperties = [NSMutableArray arrayWithArray:[LDUserModel allUserPropertyNames]];
    [allProperties addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *propertyName in allProperties) {
        config.privatePropertyNames = @[propertyName];
        testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:NO privateProperties:config.privatePropertyNames];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);
    }

    config.privatePropertyNames = allProperties;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:NO privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = nil;
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:NO privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = @[];
    testDictionary = [userStub dictionaryValueWithFlags:YES includePrivateProperties:NO privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:YES includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);
}

-(void)testDictionaryValueWithFlags_No_AndPrivateProperties_Yes {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allProperties = [NSMutableArray arrayWithArray:[LDUserModel allUserPropertyNames]];
    [allProperties addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *propertyName in allProperties) {
        config.privatePropertyNames = @[propertyName];
        testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:YES privateProperties:config.privatePropertyNames];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);
    }

    config.privatePropertyNames = allProperties;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:YES privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:YES privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = @[];
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:YES privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:YES privatePropertyNames:config.privatePropertyNames]);
}

-(void)testDictionaryValueWithFlags_No_AndPrivateProperties_No {
    LDUserModel *userStub = [LDUserModel stubWithKey:[[NSUUID UUID] UUIDString]];
    NSMutableArray *allProperties = [NSMutableArray arrayWithArray:[LDUserModel allUserPropertyNames]];
    [allProperties addObjectsFromArray:userStub.custom.allKeys];
    LDConfig *config = [[LDConfig alloc] initWithMobileKey:@"customMobileKey"];
    NSDictionary *testDictionary;

    for (NSString *propertyName in allProperties) {
        config.privatePropertyNames = @[propertyName];
        testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:NO privateProperties:config.privatePropertyNames];
        XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);
    }

    config.privatePropertyNames = allProperties;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:NO privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = nil;
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:NO privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);

    config.privatePropertyNames = @[];
    testDictionary = [userStub dictionaryValueWithFlags:NO includePrivateProperties:NO privateProperties:config.privatePropertyNames];
    XCTAssertTrue([userStub matchesDictionary:testDictionary includeConfig:NO includePrivateProperties:NO privatePropertyNames:config.privatePropertyNames]);
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
    XCTAssertTrue([user isEqual:[LDUserModel userFrom:jsonUser] ignoringProperties:ignoredProperties]);
}

- (void)testUserSave {
    NSString *userKey = [[NSUUID UUID] UUIDString];
    NSMutableDictionary *userDict = [self userDictionaryWithUserKey:userKey userName:@"John Doe" customDictionary:[self customDictionary]];
    [self validateUserModelIsEqualBehaviorUsingUserDictionary:userDict];
    LDUserModel *user = [[LDUserModel alloc] initWithDictionary:userDict];
    
    [[LDDataManager sharedManager] saveUser:user];
    
    LDUserModel *retrievedUser = [[LDDataManager sharedManager] findUserWithkey:userKey];
    XCTAssertTrue([user isEqual:retrievedUser ignoringProperties:@[@"updatedAt"]]);
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
    XCTAssertTrue([user isEqual:retrievedUser ignoringProperties:@[@"updatedAt"]]);
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
    XCTAssertFalse([user isEqual:changedUser ignoringProperties:@[@"updatedAt"]]);
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
