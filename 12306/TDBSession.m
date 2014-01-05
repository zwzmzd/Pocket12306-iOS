//
//  TDBSession.m
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBSession.h"
#import "DataSerializeUtility.h"
#import "TDBTrainInfo.h"
#import "PassengerInfo.h"
#import "Macros.h"
#import "MobClick.h"

#define ADD_UA() \
    [request setValue:USER_AGENT_STR forHTTPHeaderField:@"User-Agent"]

@interface TDBSession()

@property (nonatomic, strong) NSHTTPCookieStorage *cookieManager;
@property (nonatomic) BOOL isLoggedIn;

@end

@implementation TDBSession

+ (void)resetSession
{
    NSHTTPCookieStorage *cookieMgr = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSURL *url = [NSURL URLWithString:SYSURL @"/otn/"];
    NSArray *cookies = [cookieMgr cookiesForURL:url];
    NSEnumerator *enumerator = [cookies objectEnumerator];
    NSHTTPCookie *cookie;
    while (cookie = [enumerator nextObject]) {
        //NSLog(@"Del Cookie{%@ %@}", cookie.name, cookie.value);
        [cookieMgr deleteCookie:cookie];
    }
    NSLog(@"session reseted");
    [MobClick event:@"session restarted"];
}

- (id)init
{
    self = [super init];
    if (self){
        _cookieManager = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        _isLoggedIn = NO;
    }
    
    return self;
}

- (void)restartSession
{
    
}

- (NSData *)getSubmutToken
{
    NSString *randCode = [NSString stringWithFormat:@"%04d", abs(arc4random()) % 8000 + 1000];
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/dynamicJsAction.do?jsversion=%@&method=queryJs", randCode];
    NSURL *url = [NSURL URLWithString:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    return [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

- (NSData *)submutOrderRequestWithTrainInfo:(TDBTrainInfo *)train date:(NSString *)date tokenKey:(NSString *)tokenKey tokenValue:(NSString *)tokenValue
{
    NSLog(@"submutOrderRequestWithTrainInfo");
    [self assertLoggedIn];
    
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
    
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/querySingleAction.do?method=submutOrderRequest"];
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    return result;
}

- (BOOL)confirmSingleForQueue:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode
{
    NSLog(@"confirmSingleForQueue");
    [self assertLoggedIn];
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    
#define ORD @"orderRequest."
#define PAS @"passenger_1_"
    
    [argument setObject:apacheToken forKey:@"org.apache.struts.taglib.html.TOKEN"];
    [argument setObject:leftTicketStr forKey:@"leftTicketStr"];
    [argument setObject:@"中文或拼音首字母" forKey:@"textfield"];
    [argument setObject:date forKey:ORD @"train_date"];
    [argument setObject:[train getTrainCode] forKey:ORD @"train_no"];
    [argument setObject:[train getTrainNo] forKey:ORD @"station_train_code"];
    [argument setObject:[train getDepartStationTeleCode] forKey:ORD @"from_station_telecode"];
    [argument setObject:[train getArriveStationTeleCode] forKey:ORD @"to_station_telecode"];
    [argument setObject:@"" forKey:ORD @"seat_type_code"];
    [argument setObject:@"" forKey:ORD @"ticket_type_order_num"];
    [argument setObject:@"000000000000000000000000000000" forKey:ORD @"bed_level_order_num"];
    [argument setObject:[train getDepartTime] forKey:ORD @"start_time"];
    [argument setObject:[train getArriveTime] forKey:ORD @"end_time"];
    [argument setObject:[train getDapartStationName] forKey:ORD @"from_station_name"];
    [argument setObject:[train getArriveStationName] forKey:ORD @"to_station_name"];
    [argument setObject:@"1" forKey:ORD @"cancle_flag"];
    [argument setObject:@"Y" forKey:ORD @"id_mode"];
    [argument setObject:[passenger generateTicketString] forKey:@"passengerTickets"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:passenger.seat forKey:PAS @"seat"];
    [argument setObject:passenger.ticket forKey:PAS @"ticket"];
    [argument setObject:passenger.name forKey:PAS @"name"];
    [argument setObject:passenger.id_cardtype forKey:PAS @"cardtype"];
    [argument setObject:passenger.id_cardno forKey:PAS "cardno"];
    [argument setObject:passenger.mobileno forKey:PAS @"mobileno"];
    
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    
    [argument setObject:randCode forKey:@"randCode"];
    [argument setObject:@"A" forKey:ORD @"reserve_flag"];
    
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/confirmPassengerAction.do?method=confirmSingleForQueue"];
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setValue:SYSURL forHTTPHeaderField:@"Origin"];
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *html = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    NSError *jsonErr = nil;
    NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonErr];
    
    if (jsonErr) {
        NSLog(@"%@", html);
        return NO;
    } else {
        NSLog(@"%@", [dict objectForKey:@"errMsg"]);
        NSString *msg = [dict objectForKey:@"errMsg"];
        
        if ([msg isEqualToString:@"Y"])
            return YES;
        else
            return NO;
    }
}

- (NSString *)checkOrderInfo:(TDBTrainInfo *)train  passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode
{
    NSLog(@"checkOrderInfo");
    [self assertLoggedIn];
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    
#define ORD @"orderRequest."
#define PAS @"passenger_1_"
    
    [argument setObject:apacheToken forKey:@"org.apache.struts.taglib.html.TOKEN"];
    [argument setObject:leftTicketStr forKey:@"leftTicketStr"];
    
    NSLog(@"leftTicketStr=%@", leftTicketStr);
    [argument setObject:@"中文或拼音首字母" forKey:@"textfield"];
    [argument setObject:date forKey:ORD @"train_date"];
    [argument setObject:[train getTrainCode] forKey:ORD @"train_no"];
    [argument setObject:[train getTrainNo] forKey:ORD @"station_train_code"];
    [argument setObject:[train getDepartStationTeleCode] forKey:ORD @"from_station_telecode"];
    [argument setObject:[train getArriveStationTeleCode] forKey:ORD @"to_station_telecode"];
    [argument setObject:@"" forKey:ORD @"seat_type_code"];
    [argument setObject:@"" forKey:ORD @"ticket_type_order_num"];
    [argument setObject:@"000000000000000000000000000000" forKey:ORD @"bed_level_order_num"];
    [argument setObject:[train getDepartTime] forKey:ORD @"start_time"];
    [argument setObject:[train getArriveTime] forKey:ORD @"end_time"];
    [argument setObject:[train getDapartStationName] forKey:ORD @"from_station_name"];
    [argument setObject:[train getArriveStationName] forKey:ORD @"to_station_name"];
    [argument setObject:@"1" forKey:ORD @"cancle_flag"];
    [argument setObject:@"Y" forKey:ORD @"id_mode"];
    [argument setObject:[passenger generateTicketString] forKey:@"passengerTickets"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:passenger.seat forKey:PAS @"seat"];
    [argument setObject:passenger.ticket forKey:PAS @"ticket"];
    [argument setObject:passenger.name forKey:PAS @"name"];
    [argument setObject:passenger.id_cardtype forKey:PAS @"cardtype"];
    [argument setObject:passenger.id_cardno forKey:PAS "cardno"];
    [argument setObject:passenger.mobileno forKey:PAS @"mobileno"];
    
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    [argument setObject:@"" forKey:@"oldPassengers"];
    [argument setObject:@"Y" forKey:@"checkbox9"];
    
    [argument setObject:randCode forKey:@"randCode"];
    [argument setObject:@"A" forKey:ORD @"reserve_flag"];
    [argument setObject:@"dc" forKey:@"tFlag"];

    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/confirmPassengerAction.do?method=checkOrderInfo&rand=%@", randCode];
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setValue:SYSURL forHTTPHeaderField:@"Origin"];
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *html = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    NSError *jsonErr = nil;
    NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonErr];
    
    if (jsonErr) {
        NSLog(@"%@", html);
        return @"请求失败，请检查网络";
    } else {
        NSLog(@"%@", dict);
        NSString *msg = [dict objectForKey:@"msg"];
        NSString *errMsg = [dict objectForKey:@"errMsg"];
        
        if (msg.length != 0) {
            NSLog(@"msg: '%@'; errMsg: '%@'", msg, errMsg);
            return msg;
        } else if (![errMsg isEqualToString:@"Y"]) {
            NSLog(@"msg: '%@'; errMsg: '%@'", msg, errMsg);
            return errMsg;
        }
        
        // 未发生错误，提示购票成功
        // 实际上也会有失败的情况不能检测出来，例如无法购买学生票==，需要改进
        return nil;
    }
    
}

- (BOOL)getQueueCount:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketID:(NSString *)leftTicketID
{
    NSLog(@"getQueueCount");
    [self assertLoggedIn];
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    
    [argument setObject:@"getQueueCount" forKey:@"method"];
    [argument setObject:date forKey:@"train_date"];
    [argument setObject:[train getTrainCode] forKey:@"train_no"];
    [argument setObject:[train getTrainNo] forKey:@"station"];
    [argument setObject:passenger.seat forKey:@"seat"];
    [argument setObject:[train getDepartStationTeleCode] forKey:@"from"];
    [argument setObject:[train getArriveStationTeleCode] forKey:@"to"];
    [argument setObject:leftTicketID forKey:@"ticket"];
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/confirmPassengerAction.do?%@", [argument getFinalData]];
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *html = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    NSError *jsonErr = nil;
    NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonErr];
    
    if (jsonErr) {
        NSLog(@"%@", html);
        return NO;
    } else {
        NSLog(@"%@", dict);
        return YES;
    }
}

- (NSData *)cancleMyOrderNotComplete:(NSString *)sequenceNo apacheToken:(NSString *)apacheToken
{
    NSLog(@"cancleMyOrderNotComplete");
    [self assertLoggedIn];
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument setObject:apacheToken forKey:@"org.apache.struts.taglib.html.TOKEN"];
    [argument setObject:sequenceNo forKey:@"sequence_no"];
    [argument setObject:@"" forKey:@"orderRequest.tour_flag"];
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/orderAction.do?method=cancelMyOrderNotComplete"];
    NSURL *url = [NSURL URLWithString:path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SYSURL @"/otsweb/order/myOrderAction.do?method=queryMyOrderNotComplete&leftmenu=Y" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];

    return result;
}

- (void)assertLoggedIn
{
    NSAssert(YES, @"Before This Operation, You must Login");
}


@end
