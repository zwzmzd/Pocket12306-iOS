//
//  TDBHTTPClient.m
//  12306
//
//  Created by Wenzhe Zhou on 13-10-19.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBHTTPClient.h"
#import "DataSerializeUtility.h"

@interface TDBHTTPClient()

@property (nonatomic) dispatch_queue_t callbackQueue;

@end

@implementation TDBHTTPClient

+ (TDBHTTPClient *)sharedClient {
    static TDBHTTPClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

- (id)init {
    NSURL *base = [NSURL URLWithString:@"http://dynamic.12306.cn/otsweb/"];
    
    if (self = [super initWithBaseURL:base]) {
        [self setDefaultHeader:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36"];
        [self setDefaultHeader:@"Referer" value:[self.baseURL absoluteString]];
        [self setDefaultHeader:@"Origin" value:[self.baseURL absoluteString]];
        
        _callbackQueue = dispatch_queue_create("com.enjoy-what.app.12306assistant.network-callback-queue", 0);
    }
    return self;
}

#pragma mark - Login
- (void)getVerifyImage:(void (^)(NSData *))success {
    NSString *path = [NSString stringWithFormat:@"/otsweb/passCodeNewAction.do?module=login&rand=sjrand&0.%d%d", abs(arc4random()), abs(arc4random())];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    }];
}

- (void)getLoginToken:(void (^)(NSData *))success {
    NSString *randCode = [NSString stringWithFormat:@"%04d", abs(arc4random()) % 8000 + 1000];
    NSString *path = [NSString stringWithFormat:@"/otsweb/dynamicJsAction.do?jsversion=%@&method=loginJs", randCode];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)loginAysnSuggest:(void (^)(NSDictionary *))success {
    NSString *path = @"/otsweb/loginAction.do?method=loginAysnSuggest";
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *jsonErr = nil;
        NSDictionary *result = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonErr];
        if (success) {
            success(result);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

- (void)loginWithName:(NSString *)name AndPassword:(NSString *)password andVerifyCode:(NSString *)verifyCode loginRand:(NSString *)loginRand tokenKey:(NSString *)tokenKey tokenValue:(NSString *)tokenValue success:(void (^)())success {
//    NSDictionary *extraInfo = [self loginAysnSuggest];
    
    NSMutableDictionary *arguments = [NSMutableDictionary new];
    [arguments setObject:loginRand forKey:@"loginRand"];
    [arguments setObject:@"N" forKey:@"refundLogin"];
    [arguments setObject:@"Y" forKey:@"refundFlag"];
    [arguments setObject:@"" forKey:@"isClick"];
    [arguments setObject:@"null" forKey:@"form_tk"];
    [arguments setObject:name forKey:@"loginUser.user_name"];
    [arguments setObject:@"" forKey:@"nameErrorFocus"];
    [arguments setObject:password forKey:@"user.password"];
    [arguments setObject:@"" forKey:@"passwordErrorFocus"];
    [arguments setObject:verifyCode forKey:@"randCode"];
    [arguments setObject:@"" forKey:@"randErrorFocus"];
    [arguments setObject:tokenValue forKey:tokenKey];
    [arguments setObject:@"undefined" forKey:@"myversion"];
    
    
    
//    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/loginAction.do?method=login"];
//    NSURL *url = [NSURL URLWithString:path];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    request.HTTPMethod = @"POST";
//    request.HTTPBody = [[arguments getFinalData] dataUsingEncoding:NSUTF8StringEncoding];
//    
//    [request setValue:SYSURL forHTTPHeaderField:@"Origin"];
//    [request setValue:SYSURL @"/otsweb/loginAction.do?method=init" forHTTPHeaderField:@"Referer"];
//    
//    NSData *json = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
//    NSString *result = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
//    NSRange range = [result rangeOfString:@"系统消息"];
//    
//    if (range.length > 0) {
//        self.isLoggedIn = YES;
//        return LOGIN_MSG_SUCCESS;
//    } else {
//        NSRange range = [result rangeOfString:@"系统维护中"];
//        if (range.length > 0) {
//            return LOGIN_MSG_OUTOFSERVICE;
//        } else
//        return LOGIN_MSG_UNEXPECTED;
//    }
}


- (void)getRandpImage:(void (^)(NSData *))success {
    NSString *path = [NSString stringWithFormat:@"/otsweb/passCodeNewAction.do?module=passenger&rand=randp&0.%d%d", abs(arc4random()), abs(arc4random())];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)qt:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)())success
{
    NSLog(@"queryLeftTicketWithDate qt");
    
    // 二逼tdb，必须按顺序提交
    POSTDataConstructor *arguments = [[POSTDataConstructor alloc] init];
    [arguments addValue:@"qt" forKey:@"method"];
    [arguments addValue:date forKey:@"orderRequest.train_date"];
    [arguments addValue:from forKey:@"orderRequest.from_station_telecode"];
    [arguments addValue:to forKey:@"orderRequest.to_station_telecode"];
    [arguments addValue:@"" forKey:@"orderRequest.train_no"];
    [arguments addValue:@"QB" forKey:@"trainPassType"];
    [arguments addValue:@"QB#D#Z#T#K#QT#" forKey:@"trainClass"];
    [arguments addValue:@"00" forKey:@"includeStudent"];
    [arguments addValue:@"" forKey:@"seatTypeAndNum"];
    
    
    NSString *path = [NSString stringWithFormat:@"/otsweb/order/querySingleAction.do?%@&orderRequest.start_time_str=00%%3A00--24%%3A00", [arguments getFinalData]];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", operation.responseString);
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)queryLeftTickWithDate:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)(NSData *))success {
    NSLog(@"queryLeftTicketWithDate");
    
    // 二逼tdb，必须按顺序提交
    POSTDataConstructor *arguments = [[POSTDataConstructor alloc] init];
    [arguments addValue:@"queryLeftTicket" forKey:@"method"];
    [arguments addValue:date forKey:@"orderRequest.train_date"];
    [arguments addValue:from forKey:@"orderRequest.from_station_telecode"];
    [arguments addValue:to forKey:@"orderRequest.to_station_telecode"];
    [arguments addValue:@"" forKey:@"orderRequest.train_no"];
    [arguments addValue:@"QB" forKey:@"trainPassType"];
    [arguments addValue:@"QB#D#Z#T#K#QT#" forKey:@"trainClass"];
    [arguments addValue:@"00" forKey:@"includeStudent"];
    [arguments addValue:@"" forKey:@"seatTypeAndNum"];
    
    NSString *path = [NSString stringWithFormat:@"/otsweb/order/querySingleAction.do?%@&orderRequest.start_time_str=00%%3A00--24%%3A00", [arguments getFinalData]];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)queryaTrainStopTimeByTrainNo:(NSString *)trainNo fromStationTelecode:(NSString *)fromStationTelecode toStationTelecode:(NSString *)toStationTelecode departDate:(NSString *)departDate success:(void (^)(NSArray *))success {
    NSLog(@"queryaTrainStopTimeByTrainNo");
    
    NSMutableDictionary *argument = [NSMutableDictionary new];
    [argument setObject:@"queryaTrainStopTimeByTrainNo" forKey:@"method"];
    [argument setObject:trainNo forKey:@"train_no"];
    [argument setObject:fromStationTelecode forKey:@"from_station_telecode"];
    [argument setObject:toStationTelecode forKey:@"to_station_telecode"];
    [argument setObject:departDate forKey:@"depart_date"];
    
    NSString *path = [NSString stringWithFormat:@"/otsweb/order/querySingleAction.do"];
    [self getPath:path parameters:argument success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSError *jsonErr = nil;
            NSArray *result = (NSArray *)[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonErr];
            success(jsonErr ? nil : result);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
//    NSLog(@"%@", request);
    return request;
}

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    dispatch_queue_t callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    operation.successCallbackQueue = callbackQueue;
    operation.failureCallbackQueue = callbackQueue;
    [super enqueueHTTPRequestOperation:operation];
}

@end
