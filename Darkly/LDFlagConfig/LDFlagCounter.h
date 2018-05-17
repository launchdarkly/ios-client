//
//  LDFlagCounter.h
//  Darkly
//
//  Created by Mark Pokorny on 4/18/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDFlagValueCounter.h"

@interface LDFlagCounter : NSObject
@property (nonatomic, strong, readonly) NSString * _Nonnull flagKey;
@property (nonatomic, strong) id _Nonnull defaultValue;
@property (nonatomic, strong) NSArray<LDFlagValueCounter*> * _Nonnull counters;

+(instancetype _Nonnull)counterWithFlagKey:(NSString* _Nonnull)flagKey value:(id _Nullable)value version:(NSInteger)version variation:(NSInteger)variation defaultValue:(id _Nonnull)defaultValue;
-(instancetype _Nonnull)initWithFlagKey:(NSString* _Nonnull)flagKey value:(id _Nullable)value version:(NSInteger)version variation:(NSInteger)variation defaultValue:(id _Nonnull)defaultValue;
+(instancetype _Nonnull)counterForUnknownFlagKey:(NSString* _Nonnull)flagKey defaultValue:(id _Nonnull)defaultValue;
-(instancetype _Nonnull)initForUnknownFlagKey:(NSString* _Nonnull)flagKey defaultValue:(id _Nonnull)defaultValue;

-(void)logRequestWithValue:(id _Nullable)value version:(NSInteger)version variation:(NSInteger)variation defaultValue:(id _Nonnull)defaultValue;

-(NSDictionary* _Nonnull)dictionaryValue;

@end
