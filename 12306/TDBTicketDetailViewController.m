//
//  TDBTicketDetailViewController.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBTicketDetailViewController.h"
#import "TDBTrainInfo.h"
#import "GlobalDataStorage.h"
#import "TDBSession.h"
#import "PassengerInfo.h"
#import "MBProgressHUD.h"
#import "TFHpple.h"
#import "TDBSeatDetailViewController.h"
#import "MTStatusBarOverlay.h"
#import "SVProgressHUD.h"
#import "UIButton+TDBAddition.h"
#import "TDBPassengerInfoViewController.h"
#import "MobClick.h"
#import "DataSerializeUtility.h"

#import "TDBHTTPClient.h"
#import "Macros.h"

#define CONFIRM_DATE_AV 0xf00001

@interface TDBTicketDetailViewController () <UIAlertViewDelegate, PassengerSelectorDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;

@property (nonatomic, copy) NSString *repeatSubmitToken;
@property (nonatomic, copy) NSString *leftTicketStr;
@property (nonatomic, copy) NSString *keyCheckIsChange;
@property (nonatomic, copy) NSString *trainLocation;
@property (nonatomic, copy) NSString *tourFlag;
@property (nonatomic, copy) NSString *purposeCodes;

@property (nonatomic) NSArray *ticketList; // 余票和票价
@property (nonatomic) NSArray *seatTypeList; // 一等座、二等、硬座等等
@property (nonatomic) NSArray *ticketTypeList; // 成人，学生，残军

@property (nonatomic, readonly) NSString *departDate;
@property (nonatomic, readonly) NSString *weekday;

@property (nonatomic) BOOL doNotBack;
@property (nonatomic) BOOL isLoadingFinished;

@end

@implementation TDBTicketDetailViewController

- (NSString *)departDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:self.orderDate];
}

- (NSString *)weekday
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE"];
    return [formatter stringFromDate:self.orderDate];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)configureView
{
    NSArray *date_split = [self.departDate componentsSeparatedByString:@"-"];
    self.detailTopLabel.text = [NSString stringWithFormat:@"%@次列车 | %@年 %@月 %@日",
                                [self.train getTrainNo],
                                [date_split objectAtIndex:0],
                                [date_split objectAtIndex:1],
                                [date_split objectAtIndex:2]];
    self.detailDepartLabel.text = [NSString stringWithFormat:@"%@ （%@开）", [self.train getDapartStationName], [self.train getDepartTime]];
    self.detailArriveLabel.text = [NSString stringWithFormat:@"%@ （%@到）", [self.train getArriveStationName], [self.train getArriveTime]];
    
    [self.seatTypeSelector removeAllSegments];
    [self.ticketTypeSelector removeAllSegments];
}

- (void)retriveEssentialInfoUsingGCD
{
    [SVProgressHUD show];
    [self.verifyCodeActivityIndicator startAnimating];
    
    WeakSelfDefine(wself);
    [[TDBHTTPClient sharedClient] submutOrderRequestWithTrainInfo:self.train date:self.departDate finish:^(NSDictionary *result) {
        CHECK_INSTANCE_EXIST(wself);
        if (result == nil || [[result objectForKey:@"messages"] count] > 0) {
            NSString *message = [[result objectForKey:@"messages"] firstObject];
            if (message == nil) {
                message = @"网络请求失败，请重新尝试";
            }
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法购票"
                                                                message:message
                                                               delegate:wself
                                                      cancelButtonTitle:@"取消"
                                                      otherButtonTitles:@"返回", nil];
                alert.tag = SUBMUTORDER_MSG_UNFINISHORDER_DETECTED;
                [alert show];
                [SVProgressHUD dismiss];
            });
        } else {
            [[TDBHTTPClient sharedClient] initDc:^(NSData *data) {
                [wself _parseHTML:data];
                CHECK_INSTANCE_EXIST(wself);
                
                [wself _retriveVerifyCodeUsingGCD];
                StrongSelf(sself, wself);
                if (sself) {
                }
            }];
        }
    }];
}

- (void)_parseHTML:(NSData *)html {
    NSMutableArray *scripts = [NSMutableArray new];
    
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:html];
    NSArray *elements = [xpathParser searchWithXPathQuery:@"//script"];
    [scripts addObject:[[[elements firstObject] firstChild] raw]];
    [scripts addObject:[[[elements objectAtIndex:4] firstChild] raw]];

    NSString *code = [scripts componentsJoinedByString:@"\n"];
    code = [code stringByReplacingOccurrencesOfString:@"<![CDATA[" withString:@""];
    code = [code stringByReplacingOccurrencesOfString:@"]]>" withString:@""];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIWebView *jsEngine = [[UIWebView alloc] initWithFrame:CGRectZero];
        
        [jsEngine stringByEvaluatingJavaScriptFromString:code];
        
        self.repeatSubmitToken = [jsEngine stringByEvaluatingJavaScriptFromString:@"globalRepeatSubmitToken"];
        
        NSString *ticketInfoForPassengerFormStr = [jsEngine stringByEvaluatingJavaScriptFromString:@"JSON.stringify(ticketInfoForPassengerForm)"];
        NSDictionary *ticketInfoForPassengerForm = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:[ticketInfoForPassengerFormStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        
        self.ticketList = [ticketInfoForPassengerForm objectForKey:@"leftDetails"];
        self.leftTicketStr = [ticketInfoForPassengerForm objectForKey:@"leftTicketStr"];
        self.keyCheckIsChange = [ticketInfoForPassengerForm objectForKey:@"key_check_isChange"];
        self.trainLocation = [ticketInfoForPassengerForm objectForKey:@"train_location"];
        self.tourFlag = [ticketInfoForPassengerForm objectForKey:@"tour_flag"];
        self.purposeCodes = [ticketInfoForPassengerForm objectForKey:@"purpose_codes"];
        NSLog(@"[info] %@ %@ %@ %@", self.repeatSubmitToken, self.keyCheckIsChange, self.leftTicketStr, self.trainLocation);
        
        NSDictionary *limitBuySeatTicketDTO = [ticketInfoForPassengerForm objectForKey:@"limitBuySeatTicketDTO"];
        
        NSMutableArray *seatTypeList = [NSMutableArray new];
        NSArray *seats = [limitBuySeatTicketDTO objectForKey:@"seat_type_codes"];
        for (NSDictionary *seat in seats) {
            NSArray *e = @[[seat objectForKey:@"id"], [seat objectForKey:@"value"]];
            [seatTypeList addObject:e];
        }
        self.seatTypeList = seatTypeList;
        
        NSMutableArray *ticketTypeList = [NSMutableArray new];
        NSArray *ticketTypes = [limitBuySeatTicketDTO objectForKey:@"ticket_type_codes"];
        for (NSDictionary *ticketType in ticketTypes) {
            NSArray *e = @[[ticketType objectForKey:@"id"], [ticketType objectForKey:@"value"]];
            [ticketTypeList addObject:e];
        }
        self.ticketTypeList = ticketTypeList;
        
        for (NSUInteger i = 0; i < [self.seatTypeList count]; i++) {
            NSString *title = [[self.seatTypeList objectAtIndex:i] objectAtIndex:1];
            [self.seatTypeSelector insertSegmentWithTitle:title atIndex:i animated:YES];
        }
        self.seatTypeSelector.selectedSegmentIndex = 0;
        
        for (NSUInteger i = 0; i < [self.ticketTypeList count]; i++) {
            NSString *title = [[self.ticketTypeList objectAtIndex:i] objectAtIndex:1];
            [self.ticketTypeSelector insertSegmentWithTitle:title atIndex:i animated:YES];
        }
        self.ticketTypeSelector.selectedSegmentIndex = 0;


    });
}

- (void)_retriveVerifyCodeUsingGCD
{
    [self.verifyCodeActivityIndicator startAnimating];
    WeakSelfDefine(wself);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [[TDBHTTPClient sharedClient] getRandpImage:^(NSData *image) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [SVProgressHUD dismiss];
                StrongSelf(sself, wself);
                if (sself) {
                    [sself.refreshVerifyCodeBtn setImage:[UIImage imageWithData:image] forState:UIControlStateNormal];
                    [sself.verifyCodeActivityIndicator stopAnimating];
                    sself.isLoadingFinished = YES;
                }
            });
        }];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.doNotBack = NO;
    self.isLoadingFinished = NO;
    [self configureView];
    [self retriveEssentialInfoUsingGCD];
    
    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
}

- (IBAction)_backPressed:(id)sender
{
    // UIAlertView存在临界区问题，所以使用这个变量标记
    if (!self.doNotBack) {
        [SVProgressHUD dismiss];
        [[TDBHTTPClient sharedClient] cancelAllHTTPRequest];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)ValidateIDCardNo:(NSString *)idCardNo
{
    // 之前的校验算法有问题
    // 目前参考 http://www.xixiaoxi.com/2009/06/%E8%BA%AB%E4%BB%BD%E8%AF%81%E5%8F%B7%E7%A0%81%E8%A7%A3%E5%AF%86%E8%BA%AB%E4%BB%BD%E8%AF%81%E5%B0%BE%E6%95%B0%E6%A0%A1%E9%AA%8C%E7%A0%81%E7%AE%97%E6%B3%95id-card-information.html
    static const NSUInteger weight[] = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};
    static const char checkcode[] = {'1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'};
    
    // 先全部转化成大写，主要针对末尾的X
    idCardNo = [idCardNo uppercaseString];
    if (idCardNo.length != 18) {
        return NO;
    }
    
    NSUInteger acc = 0;
    for (NSUInteger i = 0; i < 17; i++) {
        unichar c = [idCardNo characterAtIndex:i];
        if (c == 'X') {
            acc += 10 * weight[i];
            acc %= 11;
        } else if (c >= '0' && c <= '9') {
            acc += (c - '0') * weight[i];
            acc %= 11;
        } else {
            return NO;
        }
    }
    
    unichar lastChar = [idCardNo characterAtIndex:17];
    return (lastChar == checkcode[acc]);
}

- (BOOL)checkTextField
{
    MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
    overlay.hidesActivity = YES;
    if (self.name.text.length == 0) {
        [overlay postMessage:@"请填写您的姓名" duration:2.f];
        return NO;
    }
    if (self.idCardNo.text.length == 0) {
        [overlay postErrorMessage:@"请正确填写您的身份证号码" duration:2.f];
        return NO;
    }
    if (![self ValidateIDCardNo:self.idCardNo.text]) {
        [overlay postErrorMessage:@"身份证号码有误,请检查" duration:2.f];
        return NO;
    }
    if (self.verifyCode.text.length == 0) {
        [overlay postErrorMessage:@"请填写验证码" duration:2.f];
        return NO;
    }
    
    return YES;
}

- (IBAction)iWantOrder:(id)sender {
    if (!self.isLoadingFinished) {
        NSLog(@"loading fail");
        return;
    }
    
    if (![self checkTextField ]) {
        return;
    }
    
    NSString *seatType = [[self.seatTypeList objectAtIndex:self.seatTypeSelector.selectedSegmentIndex] objectAtIndex:1];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确认日期和车次"
                                                    message:[NSString stringWithFormat:@"%@ %@\n%@次列车 %@", self.departDate, self.weekday, [self.train getTrainNo], seatType]
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles:@"确认", nil];
    alert.tag = CONFIRM_DATE_AV;
    [alert show];
}

- (IBAction)refreshVerifyCode:(id)sender {
    [[TDBHTTPClient sharedClient] cancelAllHTTPRequest];
    [self _retriveVerifyCodeUsingGCD];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - UITablbeViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"SelectPassenger" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isLoadingFinished) {
        // 显示票价和余票
        if (indexPath.section == 0 && indexPath.row == 3) {
            [self performSegueWithIdentifier:@"SeatDetail" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"SeatDetail"]) {
        TDBSeatDetailViewController *vc = [segue destinationViewController];
        vc.dataController = self.ticketList;
        [vc.tableView reloadData];
    } else if ([segue.identifier isEqualToString:@"SelectPassenger"]) {
        TDBPassengerInfoViewController *vc = [segue destinationViewController];
        vc.delegate = self;
    }
}

#pragma mark - PassengerSelectorDelegate

- (void)didSelectPassenger:(NSArray *)passengerInfoList
{
    NSDictionary *passenger = [passengerInfoList objectAtIndex:0];
    self.name.text = [passenger objectForKey:@"name"];
    self.mobileno.text = [passenger objectForKey:@"mobile_no"];
    self.idCardNo.text = [passenger objectForKey:@"passenger_id_no"];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.doNotBack = NO;
    
    switch (alertView.tag) {
        case SUBMUTORDER_MSG_UNFINISHORDER_DETECTED: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
        case SUBMUTORDER_MSG_OUT_OF_SERVICE: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
        case CONFIRM_DATE_AV: {
            if (buttonIndex == alertView.cancelButtonIndex) {
                break;
            }
            
            NSString *date = self.departDate;
            NSString *verifyCode = self.verifyCode.text;
            
            PassengerInfo *passenger = [[PassengerInfo alloc] init];
            passenger.seat = [[self.seatTypeList objectAtIndex:self.seatTypeSelector.selectedSegmentIndex] objectAtIndex:0];
            passenger.ticket = [[self.ticketTypeList objectAtIndex:self.ticketTypeSelector.selectedSegmentIndex] objectAtIndex:0];
            passenger.name = self.name.text;
            passenger.id_cardtype = @"1";
            passenger.id_cardno = [self.idCardNo.text uppercaseString];
            passenger.mobileno = self.mobileno.text;
            
            // limit_tickets[ao].seat_type + ",0," + limit_tickets[ao].ticket_type + "," + limit_tickets[ao].name + "," + limit_tickets[ao].id_type + "," + limit_tickets[ao].id_no + "," + (limit_tickets[ao].phone_no == null ? "" : limit_tickets[ao].phone_no) + "," + (limit_tickets[ao].save_status == "" ? "N" : "Y");
            NSString *passengerTicketStr = [NSString stringWithFormat:@"%@,0,%@,%@,%@,%@,%@,N", passenger.seat, passenger.ticket, passenger.name, passenger.id_cardtype, passenger.id_cardno, passenger.mobileno];
            
            // an.name + "," + an.id_type + "," + an.id_no + "," + an.passenger_type;
            NSString *oldPassengerStr = [NSString stringWithFormat:@"%@,%@,%@,%@_", passenger.name, passenger.id_cardtype, passenger.id_cardno, passenger.ticket];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            UIBarButtonItem *submitBtn = self.navigationItem.rightBarButtonItem;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
            
            MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
            overlay.hidesActivity = NO;
            [overlay postMessage:@"正在提交请求"];
            
            WeakSelf(wself, self);
            
            StrongSelf(sself, self);
            POSTDataConstructor *arguments = [[POSTDataConstructor alloc] init];
            [arguments setObject:@"2" forKey:@"cancel_flag"];
            [arguments setObject:@"000000000000000000000000000000" forKey:@"bed_level_order_num"];
            [arguments setObject:passengerTicketStr forKey:@"passengerTicketStr"];
            [arguments setObject:oldPassengerStr forKey:@"oldPassengerStr"];
            [arguments setObject:sself.tourFlag forKey:@"tour_flag"];
            [arguments setObject:verifyCode forKey:@"randCode"];
            [arguments setObject:@"" forKey:@"_json_att"];
            [arguments setObject:sself.repeatSubmitToken forKey:@"REPEAT_SUBMIT_TOKEN"];
            
            [[TDBHTTPClient sharedClient] checkOrderInfo:[arguments getFinalData] finish:^(NSDictionary *result) {
                CHECK_INSTANCE_EXIST(wself);
                NSLog(@"checkOrderInfo %@", result);
                
                if (!(result && [[[result objectForKey:@"data"] objectForKey:@"submitStatus"] boolValue])) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        StrongSelf(sself, wself);
                        if (sself) {
                            sself.progressView.progress = 0.33;
                            [overlay postErrorMessage:[[result objectForKey:@"data"] objectForKey:@"errMsg"] duration:2.f];
                            sself.navigationItem.rightBarButtonItem = submitBtn;
                        }
                        
                    });
                    return;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(sself, wself);
                    if (sself) {
                        sself.progressView.progress = 0.33;
                        [overlay postMessage:@"订单信息验证成功"];
                    }
                });
                [NSThread sleepForTimeInterval:1.f];
                CHECK_INSTANCE_EXIST(wself);
                
                StrongSelf(sself, wself);
                POSTDataConstructor *arguments = [[POSTDataConstructor alloc] init];
                [arguments setObject:@"" forKey:@"train_date"];
                [arguments setObject:[sself.train getTrainCode] forKey:@"train_no"];
                [arguments setObject:[sself.train getTrainNo] forKey:@"stationTrainCode"];
                [arguments setObject:passenger.seat forKey:@"seatType"];
                [arguments setObject:[sself.train getDepartStationTeleCode] forKey:@"fromStationTelecode"];
                [arguments setObject:[sself.train getArriveStationTeleCode] forKey:@"toStationTelecode"];
                [arguments setObject:sself.leftTicketStr forKey:@"leftTicket"];
                [arguments setObject:sself.purposeCodes forKey:@"purpose_codes"];
                [arguments setObject:@"" forKey:@"_json_att"];
                [arguments setObject:sself.repeatSubmitToken forKey:@"REPEAT_SUBMIT_TOKEN"];
                
                [[TDBHTTPClient sharedClient] getQueueCount:[arguments getFinalData] finish:^(NSDictionary *result) {
                    CHECK_INSTANCE_EXIST(wself);
                    NSLog(@"checkOrderInfo %@", result);
                    // 这个GetQueueCount暂时不检查结果，因为结果返回错误，也能正确地订票
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        StrongSelf(sself, wself);
                        if (sself) {
                            sself.progressView.progress = 0.33;
                            [overlay postMessage:@"余票确认完毕"];
                        }
                    });
                    [NSThread sleepForTimeInterval:1.f];
                    CHECK_INSTANCE_EXIST(wself);
                    
                    StrongSelf(sself, wself);
                    POSTDataConstructor *arguments = [[POSTDataConstructor alloc] init];
                    [arguments setObject:passengerTicketStr forKey:@"passengerTicketStr"];
                    [arguments setObject:oldPassengerStr forKey:@"oldPassengerStr"];
                    [arguments setObject:verifyCode forKey:@"randCode"];
                    [arguments setObject:sself.purposeCodes forKey:@"purpose_codes"];
                    [arguments setObject:sself.keyCheckIsChange forKey:@"key_check_isChange"];
                    [arguments setObject:sself.leftTicketStr forKey:@"leftTicketStr"];
                    [arguments setObject:sself.trainLocation forKey:@"train_location"];
                    [arguments setObject:@"" forKey:@"_json_att"];
                    [arguments setObject:sself.repeatSubmitToken forKey:@"REPEAT_SUBMIT_TOKEN"];
                    
                    [[TDBHTTPClient sharedClient] confirmSingleForQueue:[arguments getFinalData] finish:^(NSDictionary *result) {
                        CHECK_INSTANCE_EXIST(wself);
                        NSLog(@"confirmSingleForQueue %@", result);
                        
                        if (!(result && [[[result objectForKey:@"data"] objectForKey:@"submitStatus"] boolValue])) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                StrongSelf(sself, wself);
                                if (sself) {
                                    sself.progressView.progress = 0.33;
                                    [overlay postErrorMessage:[[result objectForKey:@"data"] objectForKey:@"errMsg"] duration:2.f];
                                    sself.navigationItem.rightBarButtonItem = submitBtn;
                                }
                                
                            });
                            return;
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            StrongSelf(sself, wself);
                            if (sself) {
                                sself.progressView.progress = 1;
                                [MobClick event:@"ticket order successfully"];
                                [overlay postImmediateFinishMessage:@"订票信息已经确认，请继续完成支付" duration:5.f animated:YES];
                                sself.navigationItem.rightBarButtonItem = nil;
                            }
                        });
                    }];
                }];
            }];
            
            break;
        }
    }
}

- (void)dealloc {
    NSLog(@"dealloc %@", [self class]);
}

@end
