//
//  LDEventModel.h
//  Darkly
//
//  Created by Jeffrey Byrnes on 1/18/16.
//  Copyright © 2016 Darkly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LDUserModel;

@interface LDEventModel : NSObject <NSCoding>
@property (nullable, nonatomic, strong) NSString *key;
@property (nullable, nonatomic, strong) NSString *kind;
@property (nonatomic) NSInteger creationDate;
@property (nullable, nonatomic, strong) NSDictionary *data;
@property (nullable, nonatomic, strong) LDUserModel *user;

@property (nonatomic, assign) BOOL featureKeyValue;
@property (nonatomic, assign) BOOL isDefault;

-(nonnull id)initWithDictionary:(nonnull NSDictionary *)dictionary;
-(nonnull NSDictionary *)dictionaryValue;

-(nonnull instancetype)featureEventWithKey:(nonnull NSString *)featureKey keyValue:(BOOL)keyValue defaultKeyValue:(BOOL)defaultKeyValue userValue:(nonnull LDUserModel *)userValue;
-(nonnull instancetype) customEventWithKey: (nonnull NSString *)featureKey
                         andDataDictionary: (nonnull NSDictionary *)customData userValue:(nonnull LDUserModel *)userValue;
@end
