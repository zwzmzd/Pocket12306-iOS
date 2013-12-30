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
    NSURL *url = [NSURL URLWithString:SYSURL @"/otsweb/"];
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
    [argument addValue:[train getTrainNo] forKey:@"station_train_code"];
    [argument addValue:date forKey:@"train_date"];
    [argument addValue:@"" forKey:@"seatstype_num"];
    [argument addValue:[train getDepartStationTeleCode] forKey:@"from_station_telecode"];
    [argument addValue:[train getArriveStationTeleCode] forKey:@"to_station_telecode"];
    [argument addValue:@"00" forKey:@"include_student"];
    [argument addValue:[train getDapartStationName] forKey:@"from_station_telecode_name"];
    [argument addValue:[train getArriveStationName] forKey:@"to_station_telecode_name"];
    [argument addValue:date forKey:@"round_train_date"];
    [argument addValue:@"00:00--00:24" forKey:@"round_start_time_str"];
    [argument addValue:@"1" forKey:@"single_round_trip"];
    [argument addValue:@"QB" forKey:@"train_pass_type"];
    [argument addValue:@"QB#D#Z#T#K#QT#" forKey:@"train_class_arr"];
    [argument addValue:@"00:00--00:24" forKey:@"start_time_str"];
    [argument addValue:[train getDuration] forKey:@"lishi"];
    [argument addValue:[train getDepartTime] forKey:@"train_start_time"];
    [argument addValue:[train getTrainCode] forKey:@"trainno4"];
    [argument addValue:[train getArriveTime] forKey:@"arrive_time"];
    [argument addValue:[train getDapartStationName] forKey:@"from_station_name"];
    [argument addValue:[train getArriveStationName] forKey:@"to_station_name"];
    [argument addValue:[train getDepartStationNo] forKey:@"from_station_no"];
    [argument addValue:[train getArriveStationNo] forKey:@"to_station_no"];
    [argument addValue:[train getYPInfoDetail] forKey:@"ypInfoDetail"];
    [argument addValue:[train getMMStr] forKey:@"mmStr"];
    [argument addValue:[train getLocationCode] forKey:@"locationCode"];
    [argument addValue:tokenValue forKey:tokenKey];
    [argument addValue:@"undefined" forKey:@"myversion"];
    
    
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
    
    [argument addValue:apacheToken forKey:@"org.apache.struts.taglib.html.TOKEN"];
    [argument addValue:leftTicketStr forKey:@"leftTicketStr"];
    [argument addValue:@"中文或拼音首字母" forKey:@"textfield"];
    [argument addValue:date forKey:ORD @"train_date"];
    [argument addValue:[train getTrainCode] forKey:ORD @"train_no"];
    [argument addValue:[train getTrainNo] forKey:ORD @"station_train_code"];
    [argument addValue:[train getDepartStationTeleCode] forKey:ORD @"from_station_telecode"];
    [argument addValue:[train getArriveStationTeleCode] forKey:ORD @"to_station_telecode"];
    [argument addValue:@"" forKey:ORD @"seat_type_code"];
    [argument addValue:@"" forKey:ORD @"ticket_type_order_num"];
    [argument addValue:@"000000000000000000000000000000" forKey:ORD @"bed_level_order_num"];
    [argument addValue:[train getDepartTime] forKey:ORD @"start_time"];
    [argument addValue:[train getArriveTime] forKey:ORD @"end_time"];
    [argument addValue:[train getDapartStationName] forKey:ORD @"from_station_name"];
    [argument addValue:[train getArriveStationName] forKey:ORD @"to_station_name"];
    [argument addValue:@"1" forKey:ORD @"cancle_flag"];
    [argument addValue:@"Y" forKey:ORD @"id_mode"];
    [argument addValue:[passenger generateTicketString] forKey:@"passengerTickets"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:passenger.seat forKey:PAS @"seat"];
    [argument addValue:passenger.ticket forKey:PAS @"ticket"];
    [argument addValue:passenger.name forKey:PAS @"name"];
    [argument addValue:passenger.id_cardtype forKey:PAS @"cardtype"];
    [argument addValue:passenger.id_cardno forKey:PAS "cardno"];
    [argument addValue:passenger.mobileno forKey:PAS @"mobileno"];
    
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    
    [argument addValue:randCode forKey:@"randCode"];
    [argument addValue:@"A" forKey:ORD @"reserve_flag"];
    
    
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
    
    [argument addValue:apacheToken forKey:@"org.apache.struts.taglib.html.TOKEN"];
    [argument addValue:leftTicketStr forKey:@"leftTicketStr"];
    
    NSLog(@"leftTicketStr=%@", leftTicketStr);
    [argument addValue:@"中文或拼音首字母" forKey:@"textfield"];
    [argument addValue:date forKey:ORD @"train_date"];
    [argument addValue:[train getTrainCode] forKey:ORD @"train_no"];
    [argument addValue:[train getTrainNo] forKey:ORD @"station_train_code"];
    [argument addValue:[train getDepartStationTeleCode] forKey:ORD @"from_station_telecode"];
    [argument addValue:[train getArriveStationTeleCode] forKey:ORD @"to_station_telecode"];
    [argument addValue:@"" forKey:ORD @"seat_type_code"];
    [argument addValue:@"" forKey:ORD @"ticket_type_order_num"];
    [argument addValue:@"000000000000000000000000000000" forKey:ORD @"bed_level_order_num"];
    [argument addValue:[train getDepartTime] forKey:ORD @"start_time"];
    [argument addValue:[train getArriveTime] forKey:ORD @"end_time"];
    [argument addValue:[train getDapartStationName] forKey:ORD @"from_station_name"];
    [argument addValue:[train getArriveStationName] forKey:ORD @"to_station_name"];
    [argument addValue:@"1" forKey:ORD @"cancle_flag"];
    [argument addValue:@"Y" forKey:ORD @"id_mode"];
    [argument addValue:[passenger generateTicketString] forKey:@"passengerTickets"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:passenger.seat forKey:PAS @"seat"];
    [argument addValue:passenger.ticket forKey:PAS @"ticket"];
    [argument addValue:passenger.name forKey:PAS @"name"];
    [argument addValue:passenger.id_cardtype forKey:PAS @"cardtype"];
    [argument addValue:passenger.id_cardno forKey:PAS "cardno"];
    [argument addValue:passenger.mobileno forKey:PAS @"mobileno"];
    
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    [argument addValue:@"" forKey:@"oldPassengers"];
    [argument addValue:@"Y" forKey:@"checkbox9"];
    
    [argument addValue:randCode forKey:@"randCode"];
    [argument addValue:@"A" forKey:ORD @"reserve_flag"];
    [argument addValue:@"dc" forKey:@"tFlag"];

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
    
    [argument addValue:@"getQueueCount" forKey:@"method"];
    [argument addValue:date forKey:@"train_date"];
    [argument addValue:[train getTrainCode] forKey:@"train_no"];
    [argument addValue:[train getTrainNo] forKey:@"station"];
    [argument addValue:passenger.seat forKey:@"seat"];
    [argument addValue:[train getDepartStationTeleCode] forKey:@"from"];
    [argument addValue:[train getArriveStationTeleCode] forKey:@"to"];
    [argument addValue:leftTicketID forKey:@"ticket"];
    
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

- (NSData *)queryMyOrderNotComplete
{
    NSLog(@"queryMyOrderNotComplete");
    [self assertLoggedIn];
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/myOrderAction.do?method=queryMyOrderNotComplete&leftmenu=Y"];
    NSURL *url = [NSURL URLWithString:path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    return result;
}

- (NSData *)queryMyOrder
{
    NSLog(@"queryMyOrder");
    [self assertLoggedIn];
    
#define QDO @"queryOrderDTO."
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument addValue:@"_1" forKey:QDO @"location_code"];
    [argument addValue:@"Y" forKey:@"leftmenu"];
    [argument addValue:@"1" forKey:@"queryDataFlag"];
    [argument addValue:@"" forKey:QDO @"from_order_date"];
    [argument addValue:@"" forKey:QDO @"end_order_date"];
    [argument addValue:@"" forKey:QDO @"sequence_no"];
    [argument addValue:@"" forKey:QDO @"train_code"];
    [argument addValue:@"" forKey:QDO @"name"];
    
#undef QDO
    
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/myOrderAction.do?method=queryMyOrder&pageIndex=0&pageSize=50"];
    NSURL *url = [NSURL URLWithString:path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    return result;
}

- (NSData *)queryMyOrderWithFromOrderDate:(NSString *)fromOrderDate endOrderDate:(NSString *)endOrderDate
{
    // 这个方法不会被使用
    NSLog(@"queryMyOrder");
    [self assertLoggedIn];
    
#define QDO @"queryOrderDTO."
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument addValue:@"_1" forKey:QDO @"location_code"];
    [argument addValue:@"Y" forKey:@"leftmenu"];
    [argument addValue:@"1" forKey:@"queryDataFlag"];
    [argument addValue:fromOrderDate forKey:QDO @"from_order_date"];
    [argument addValue:endOrderDate forKey:QDO @"end_order_date"];
    [argument addValue:@"" forKey:QDO @"sequence_no"];
    [argument addValue:@"" forKey:QDO @"train_code"];
    [argument addValue:@"" forKey:QDO @"name"];
    
#undef QDO
    
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/myOrderAction.do?method=queryMyOrder"];
    NSURL *url = [NSURL URLWithString:path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[argument getFinalData] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    return result;
}

- (NSDictionary *)loginAysnSuggest
{
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/loginAction.do?method=loginAysnSuggest"];
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    ADD_UA();
    
    NSData *json = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSError *jsonErr = nil;
    NSDictionary *result = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:json options:0 error:&jsonErr];
    
    return result;
}

- (NSArray *)queryaTrainStopTimeByTrainNo:(NSString *)trainNo fromStationTelecode:(NSString *)fromStationTelecode toStationTelecode:(NSString *)toStationTelecode departDate:(NSString *)departDate
{
    NSLog(@"queryaTrainStopTimeByTrainNo");
    [self assertLoggedIn];
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument addValue:@"queryaTrainStopTimeByTrainNo" forKey:@"method"];
    [argument addValue:trainNo forKey:@"train_no"];
    [argument addValue:fromStationTelecode forKey:@"from_station_telecode"];
    [argument addValue:toStationTelecode forKey:@"to_station_telecode"];
    [argument addValue:departDate forKey:@"depart_date"];
    
    NSString *path = [NSString stringWithFormat:SYSURL @"/otsweb/order/querySingleAction.do?%@", [argument getFinalData]];
    NSURL *url = [NSURL URLWithString:path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SYSURL @"/otsweb/querySingleAction.do?method=init" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    ADD_UA();
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSError *jsonErr = nil;
    NSArray *dict = (NSArray *)[NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonErr];
    
    if (jsonErr) {
        return nil;
    } else {
        return dict;
    }
}

- (NSData *)cancleMyOrderNotComplete:(NSString *)sequenceNo apacheToken:(NSString *)apacheToken
{
    NSLog(@"cancleMyOrderNotComplete");
    [self assertLoggedIn];
    
    POSTDataConstructor *argument = [[POSTDataConstructor alloc] init];
    [argument addValue:apacheToken forKey:@"org.apache.struts.taglib.html.TOKEN"];
    [argument addValue:sequenceNo forKey:@"sequence_no"];
    [argument addValue:@"" forKey:@"orderRequest.tour_flag"];
    
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
