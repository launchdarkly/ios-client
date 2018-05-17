//
//  NSDate+ReferencedDate.h
//  Darkly
//
//  Created by Mark Pokorny on 4/11/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ReferencedDate)
+(NSDate*)dateFromMillisSince1970:(NSInteger)millis;
-(NSInteger)millisSince1970;
-(BOOL)isWithinTimeInterval:(NSTimeInterval)timeInterval ofDate:(NSDate*)otherDate;
@end
