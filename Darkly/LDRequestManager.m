//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import "LDRequestManager.h"
#import "LDUtil.h"
#import "LDClientManager.h"
#import "LDConfig.h"

static NSString * const kFeatureFlagGetUrl = @"/msdk/eval/users/";
static NSString * const kFeatureFlagReportUrl = @"/msdk/eval/user";
static NSString * const kEventUrl = @"/mobile/events/bulk";
NSString * const kHeaderMobileKey = @"api_key ";
static NSString * const kConfigRequestCompletedNotification = @"config_request_completed_notification";
static NSString * const kEventRequestCompletedNotification = @"event_request_completed_notification";

@implementation LDRequestManager

@synthesize mobileKey, baseUrl, eventsUrl, connectionTimeout, delegate;

+(LDRequestManager *)sharedInstance {
    static LDRequestManager *sharedApiManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedApiManager = [[self alloc] init];
        [sharedApiManager setDelegate:[LDClientManager sharedInstance]];
        LDClient *client = [LDClient sharedInstance];
        LDConfig *config = client.ldConfig;
        [sharedApiManager setMobileKey:config.mobileKey];
        [sharedApiManager setBaseUrl:config.baseUrl];
        [sharedApiManager setEventsUrl:config.eventsUrl];
        [sharedApiManager setConnectionTimeout:[config.connectionTimeout doubleValue]];
    });
    return sharedApiManager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)performFeatureFlagRequest:(LDUserModel *)user
{
    if (!mobileKey) {
        DEBUG_LOGX(@"RequestManager unable to sync config to server since no mobileKey");
        return;
    }
    
    if (!user) {
        DEBUG_LOGX(@"RequestManager unable to sync config to server since no user");
        return;
    }
    
    if ([LDClient sharedInstance].ldConfig.useReport) {
        DEBUG_LOGX(@"RequestManager syncing config to server via REPORT");
        NSURLRequest *flagRequestUsingReportMethod = [self flagRequestUsingReportMethodForUser:user];
        [self performFlagRequest:flagRequestUsingReportMethod completionHandler:^(NSData * _Nullable originalData, NSURLResponse * _Nullable originalResponse, NSError * _Nullable originalError) {
            
            if ([self shouldTryFlagGetRequestForFlagResponse:originalResponse]) {
                NSURLRequest *flagRequestUsingGetMethod = [self flagRequestUsingGetMethodForUser:user];
                if (flagRequestUsingGetMethod) {
                    DEBUG_LOGX(@"RequestManager syncing config to server via GET");
                    
                    [self performFlagRequest:flagRequestUsingGetMethod completionHandler:^(NSData * _Nullable retriedData, NSURLResponse * _Nullable retriedResponse, NSError * _Nullable retriedError) {
                        [self processFlagResponseWithData:retriedData error:retriedError];
                    }];
                    return;
                }
            }
            [self processFlagResponseWithData:originalData error:originalError];
        }];
    } else {
        DEBUG_LOGX(@"RequestManager syncing config to server via GET");

        NSURLRequest *flagRequestUsingGetMethod = [self flagRequestUsingGetMethodForUser:user];
        [self performFlagRequest:flagRequestUsingGetMethod completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            [self processFlagResponseWithData:data error:error];
        }];
    }
}

-(BOOL)shouldTryFlagGetRequestForFlagResponse:(NSURLResponse*)flagResponse {
    if (!flagResponse) { return NO; }
    if (![flagResponse isKindOfClass:[NSHTTPURLResponse class]]) { return NO; }
    NSHTTPURLResponse *httpFlagResponse = (NSHTTPURLResponse*)flagResponse;
    return [LDClient sharedInstance].ldConfig.useReport && [[LDClient sharedInstance].ldConfig isFlagRetryStatusCode:httpFlagResponse.statusCode];
}

-(void)processFlagResponseWithData:(NSData*)data error:(NSError*)error {
    BOOL configProcessed = NO;
    NSDictionary *featureFlags;
    if (!error) {
        NSError *jsonError;
        featureFlags = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        configProcessed = featureFlags != nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate processedConfig:configProcessed jsonConfigDictionary:featureFlags];
    });
}

-(void)performFlagRequest:(NSURLRequest*)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    if (!request) { return; }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(data, response, error);
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    [dataTask resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

-(void)performEventRequest:(NSArray *)jsonEventArray {
    DEBUG_LOGX(@"RequestManager syncing events to server");
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    if (mobileKey) {
        if (jsonEventArray) {
            NSURLSession *defaultSession = [NSURLSession sharedSession];
            NSString *requestUrl = [eventsUrl stringByAppendingString:kEventUrl];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
            [request setTimeoutInterval:self.connectionTimeout];
            [self addEventRequestHeaders:request];
            
            NSError *error;
            NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonEventArray options:0 error:&error];
            
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:postData];
            
            NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                dispatch_semaphore_signal(semaphore);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL processedEvents = !error ? YES : NO;
                    [delegate processedEvents:processedEvents jsonEventArray:jsonEventArray];
                });
            }];
            
            [dataTask resume];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
        } else {
            DEBUG_LOGX(@"RequestManager unable to sync events to server since no events");
        }
    } else {
        DEBUG_LOGX(@"RequestManager unable to sync events to server since no mobileKey");
    }
}

#pragma mark - requests
-(NSURLRequest*)flagRequestUsingReportMethodForUser:(LDUserModel*)user {
    if (!user) {
        DEBUG_LOGX(@"RequestManager unable to sync config to server since no user");
        return nil;
    }
    NSString *userJson = [user convertToJson];
    if (!userJson) {
        DEBUG_LOGX(@"RequestManager could not convert user to json, aborting sync config to server");
        return nil;
    }
    
    NSString *requestUrl = [baseUrl stringByAppendingString:kFeatureFlagReportUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
    request.HTTPMethod = @"REPORT";
    request.HTTPBody = [userJson dataUsingEncoding:NSUTF8StringEncoding];
    [request setTimeoutInterval:self.connectionTimeout];
    [self addFeatureRequestHeaders:request];
    
    return request;
}

-(NSURLRequest*)flagRequestUsingGetMethodForUser:(LDUserModel*)user {
    if (!user) {
        DEBUG_LOGX(@"RequestManager unable to sync config to server since no user");
        return nil;
    }
    NSString *userJson = [user convertToJson];
    if (!userJson) {
        DEBUG_LOGX(@"RequestManager could not convert user to json, aborting sync config to server");
        return nil;
    }
    NSString *encodedUser = [LDUtil base64UrlEncodeString:userJson];
    if (!encodedUser) {
        DEBUG_LOGX(@"RequestManager could not base64Url encode user, aborting sync config to server");
        return nil;
    }
    NSString *requestUrl = [baseUrl stringByAppendingString:kFeatureFlagGetUrl];
    requestUrl = [requestUrl stringByAppendingString:encodedUser];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
    [request setTimeoutInterval:self.connectionTimeout];
    [self addFeatureRequestHeaders:request];
    
    return request;
}

-(void)addFeatureRequestHeaders:(NSMutableURLRequest *)request {
    NSString *authKey = [kHeaderMobileKey stringByAppendingString:mobileKey];
    
    [request addValue:authKey forHTTPHeaderField:@"Authorization"];
    [request addValue:[@"iOS/" stringByAppendingString:kClientVersion] forHTTPHeaderField:@"User-Agent"];
}

-(void)addEventRequestHeaders: (NSMutableURLRequest *)request {
    NSString *authKey = [kHeaderMobileKey stringByAppendingString:mobileKey];
    
    [request addValue:authKey forHTTPHeaderField:@"Authorization"];
    [request addValue:[@"iOS/" stringByAppendingString:kClientVersion] forHTTPHeaderField:@"User-Agent"];
    [request addValue: @"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

@end
