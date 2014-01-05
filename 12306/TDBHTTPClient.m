//
//  TDBHTTPClient.m
//  12306
//
//  Created by Wenzhe Zhou on 13-10-19.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBHTTPClient.h"
#import "DataSerializeUtility.h"
#import "GlobalDataStorage.h"
#import "TDBTrainInfo.h"
#import "Macros.h"

#define USER_DEFINED_POSTBODY (@"UserPostBody")

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
    NSURL *base = [NSURL URLWithString:@"http://kyfw.12306.cn/otn/"];
    
    if (self = [super initWithBaseURL:base]) {
        [self setDefaultHeader:@"User-Agent" value:USER_AGENT_STR];
        [self setDefaultHeader:@"Referer" value:[self.baseURL absoluteString]];
        [self setDefaultHeader:@"Origin" value:[self.baseURL absoluteString]];
        [self setDefaultHeader:@"Host" value:[self.baseURL host]];
        
        _callbackQueue = dispatch_queue_create("com.enjoy-what.app.12306assistant.network-callback-queue", 0);
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    }
    return self;
}

#pragma mark - 登录部分
- (void)getVerifyImage:(void (^)(NSData *))success {
    NSString *path = [NSString stringWithFormat:@"/otn/passcodeNew/getPassCodeNew?module=login&rand=sjrand"];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    }];
}

- (void)loginWithName:(NSString *)name AndPassword:(NSString *)password andVerifyCode:(NSString *)verifyCode success:(void (^)(NSDictionary *))success {
    NSString *path = @"/otn/login/loginAysnSuggest";
    
    NSMutableDictionary *arguments = [NSMutableDictionary new];
    [arguments setObject:name forKey:@"loginUserDTO.user_name"];
    [arguments setObject:password forKey:@"userDTO.password"];
    [arguments setObject:verifyCode forKey:@"randCode"];
    
    [self postPath:path parameters:arguments success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSError *jsonErr = nil;
            NSDictionary *result = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonErr];
            success(jsonErr ? nil : result);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

#pragma mark - 检索模块
- (void)qt:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)())success
{
    NSLog(@"queryLeftTicketWithDate qt");
    
    // 二逼tdb，必须按顺序提交
    POSTDataConstructor *arguments = [[POSTDataConstructor alloc] init];
    [arguments setObject:@"qt" forKey:@"method"];
    [arguments setObject:date forKey:@"orderRequest.train_date"];
    [arguments setObject:from forKey:@"orderRequest.from_station_telecode"];
    [arguments setObject:to forKey:@"orderRequest.to_station_telecode"];
    [arguments setObject:@"" forKey:@"orderRequest.train_no"];
    [arguments setObject:@"QB" forKey:@"trainPassType"];
    [arguments setObject:@"QB#D#Z#T#K#QT#" forKey:@"trainClass"];
    [arguments setObject:@"00" forKey:@"includeStudent"];
    [arguments setObject:@"" forKey:@"seatTypeAndNum"];
    
    
    NSString *path = [NSString stringWithFormat:@"/otsweb/order/querySingleAction.do?%@&orderRequest.start_time_str=00%%3A00--24%%3A00", [arguments getFinalData]];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)queryLeftTickWithDate:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)(NSData *))success {
    NSLog(@"queryLeftTicketWithDate");
    
    POSTDataConstructor *arguments = [[POSTDataConstructor alloc] init];
    [arguments setObject:date forKey:@"leftTicketDTO.train_date"];
    [arguments setObject:from forKey:@"leftTicketDTO.from_station"];
    [arguments setObject:to forKey:@"leftTicketDTO.to_station"];
    [arguments setObject:@"ADULT" forKey:@"purpose_codes"];
    
    
    NSString *path = [NSString stringWithFormat:@"/otn/leftTicket/query?%@", [arguments getFinalData]];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)queryaTrainStopTimeByTrainNo:(NSString *)trainNo fromStationTelecode:(NSString *)fromStationTelecode toStationTelecode:(NSString *)toStationTelecode departDate:(NSString *)departDate success:(void (^)(NSArray *))success {
    NSLog(@"queryByTrainNo");
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:trainNo forKey:@"train_no"];
    [argument setObject:fromStationTelecode forKey:@"from_station_telecode"];
    [argument setObject:toStationTelecode forKey:@"to_station_telecode"];
    [argument setObject:departDate forKey:@"depart_date"];
    
    NSString *path = [NSString stringWithFormat:@"/otn/czxx/queryByTrainNo?%@", [argument getFinalData]];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSError *jsonErr = nil;
            NSDictionary *result = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonErr];
            if (result) {
                success([[result objectForKey:@"data"] objectForKey:@"data"]);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

#pragma mark - 预定模块

- (void)getRandpImage:(void (^)(NSData *))success {
    NSString *path = [NSString stringWithFormat:@"/otsweb/passCodeNewAction.do?module=passenger&rand=randp&0.%d%d", abs(arc4random()), abs(arc4random())];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)getSubmutToken:(void (^)(NSData *))success {
    NSString *randCode = [NSString stringWithFormat:@"%04d", abs(arc4random()) % 8000 + 1000];
    NSString *path = [NSString stringWithFormat:@"/otsweb/dynamicJsAction.do?jsversion=%@&method=queryJs", randCode];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)submutOrderRequestWithTrainInfo:(id)train date:(NSString *)date tokenKey:(NSString *)tokenKey tokenValue:(NSString *)tokenValue success:(void (^)(NSData *))success {
    NSLog(@"submutOrderRequestWithTrainInfo");
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:[train getTrainNo] forKey:@"station_train_code"];
    [argument setObject:date forKey:@"train_date"];
    [argument setObject:@"" forKey:@"seatstype_num"];
    [argument setObject:[train getDepartStationTeleCode] forKey:@"from_station_telecode"];
    [argument setObject:[train getArriveStationTeleCode] forKey:@"to_station_telecode"];
    [argument setObject:@"00" forKey:@"include_student"];
    [argument setObject:[train getDapartStationName] forKey:@"from_station_telecode_name"];
    [argument setObject:[train getArriveStationName] forKey:@"to_station_telecode_name"];
    [argument setObject:date forKey:@"round_train_date"];
    [argument setObject:@"00:00--00:24" forKey:@"round_start_time_str"];
    [argument setObject:@"1" forKey:@"single_round_trip"];
    [argument setObject:@"QB" forKey:@"train_pass_type"];
    [argument setObject:@"QB#D#Z#T#K#QT#" forKey:@"train_class_arr"];
    [argument setObject:@"00:00--00:24" forKey:@"start_time_str"];
    [argument setObject:[train getDuration] forKey:@"lishi"];
    [argument setObject:[train getDepartTime] forKey:@"train_start_time"];
    [argument setObject:[train getTrainCode] forKey:@"trainno4"];
    [argument setObject:[train getArriveTime] forKey:@"arrive_time"];
    [argument setObject:[train getDapartStationName] forKey:@"from_station_name"];
    [argument setObject:[train getArriveStationName] forKey:@"to_station_name"];
    [argument setObject:[train getDepartStationNo] forKey:@"from_station_no"];
    [argument setObject:[train getArriveStationNo] forKey:@"to_station_no"];
    [argument setObject:[train getYPInfoDetail] forKey:@"ypInfoDetail"];
    [argument setObject:[train getMMStr] forKey:@"mmStr"];
    [argument setObject:[train getLocationCode] forKey:@"locationCode"];
    [argument setObject:tokenValue forKey:tokenKey];
    [argument setObject:@"undefined" forKey:@"myversion"];
    
    
    NSString *path = @"/otsweb/order/querySingleAction.do?method=submutOrderRequest";
    NSDictionary *parameters = @{USER_DEFINED_POSTBODY: [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding]};
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)queryMyOrder:(void (^)(NSArray *))success {
    NSDate *fromDate = [NSDate dateWithTimeIntervalSinceNow:-3600*24*60];
    NSString *fromDateString = [GlobalDataStorage dateInString:fromDate];
    NSString *todayString = [GlobalDataStorage getTodayDateInString];
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:@"1" forKey:@"queryType"];
    [argument setObject:fromDateString forKey:@"queryStartDate"];
    [argument setObject:todayString forKey:@"queryEndDate"];
    [argument setObject:@"my_flag" forKey:@"come_from_flag"];
    [argument setObject:@"100" forKey:@"pageSize"];
    [argument setObject:@"0" forKey:@"pageIndex"];
    [argument setObject:@"" forKey:@"sequence_train_name"];
    
    NSString *path = @"/otn/queryOrder/queryMyOrder";
    NSDictionary *parameters = @{USER_DEFINED_POSTBODY: [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding]};
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *jsonErr = nil;
        NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonErr];
        if (success) {
            if ([[dict objectForKey:@"status"] boolValue]) {
                success([[dict objectForKey:@"data"] objectForKey:@"OrderDTODataList"]);
            } else {
                success(nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

- (void)queryMyOrderNoComplete:(void (^)(NSArray *))success {
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:@"" forKey:@"_json_att"];
    
    NSString *path = @"/otn/queryOrder/queryMyOrderNoComplete";
    NSDictionary *parameters = @{USER_DEFINED_POSTBODY: [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding]};
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *jsonErr = nil;
        NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonErr];
        if (success) {
            if ([[dict objectForKey:@"status"] boolValue]) {
                success([[dict objectForKey:@"data"] objectForKey:@"orderDBList"]);
            } else {
                success(nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

#pragma mark - 支付模块

- (void)payOrderInit:(void (^)(NSData *))success {
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:@"" forKey:@"_json_att"];
    
    NSString *path = @"/otn/payOrder/init";
    NSDictionary *parameters = @{USER_DEFINED_POSTBODY: [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding]};
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

- (void)laterEpayWithOrderSequenceNo:(NSString *)orderSequenceNo apacheToken:(NSString *)apacheToken ticketKey:(NSString *)ticketKey success:(void (^)(NSData *))success {
    NSLog(@"laterEpay");
    
#define QDO @"queryOrderDTO."
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:apacheToken forKey:@"org.apache.struts.taglib.html.TOKEN"];
    [argument setObject:@"" forKey:QDO @"from_order_date"];
    [argument setObject:@"" forKey:QDO @"to_order_date"];
    [argument setObject:[NSString stringWithFormat:@"%@;", ticketKey] forKey:@"ticket_key"];
#undef QDO
    
    NSString *path = [NSString stringWithFormat:@"/otsweb/order/myOrderAction.do?method=laterEpay&orderSequence_no=%@&con_pay_type=epay", orderSequenceNo];
    NSDictionary *parameters = @{USER_DEFINED_POSTBODY: [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding]};
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

#pragma mark - 辅助模块

- (void)getPassengersWithIndex:(NSUInteger)index size:(NSUInteger)size success:(void (^)(NSDictionary *))success {
    NSLog(@"getPassengers");
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:[NSString stringWithFormat:@"%u", index] forKey:@"pageIndex"];
    [argument setObject:[NSString stringWithFormat:@"%u", size] forKey:@"pageSize"];
    [argument setObject:@"" forKey:@"passenger_name"];
    
    NSString *path = @"/otsweb/passengerAction.do?method=getPagePassengerAll";
    NSDictionary *parameters = @{USER_DEFINED_POSTBODY: [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding]};
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSError *jsonErr = nil;
            NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonErr];
            success(jsonErr ? nil : dict);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

#pragma mark - AFHTTPClient functions overwirte

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request;
    NSData *postBody = [parameters objectForKey:USER_DEFINED_POSTBODY];
    
    // 有的时候，我们需要自己构造数据提交
    if (postBody != nil) {
        request = [super requestWithMethod:method path:path parameters:nil];
        request.HTTPMethod = @"POST";
        request.HTTPBody = postBody;
    } else {
        request = [super requestWithMethod:method path:path parameters:parameters];
    }
    return request;
}

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    dispatch_queue_t callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    operation.successCallbackQueue = callbackQueue;
    operation.failureCallbackQueue = callbackQueue;
    [super enqueueHTTPRequestOperation:operation];
}

@end
