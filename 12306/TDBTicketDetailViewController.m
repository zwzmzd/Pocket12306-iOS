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

#define CONFIRM_DATE_AV 0xf00001

@interface TDBTicketDetailViewController () <UIAlertViewDelegate, PassengerSelectorDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;

@property (nonatomic, copy) NSString *html;
@property (nonatomic, copy) NSString *leftTicketID;
@property (nonatomic, copy) NSString *apacheToken;
@property (nonatomic) NSArray *ticketList; // 余票和票价
@property (nonatomic) NSArray *seatTypeList; // 一等座、二等、硬座等等
@property (nonatomic) NSArray *ticketTypeList; // 成人，学生，残军

@property (nonatomic, readonly) NSString *departDate;
@property (nonatomic, readonly) NSString *weekday;

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

- (SUBMUTORDER_MSG)parseHTMLWithData:(NSData *)htmlData
{
    self.html = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    
    NSRange range = [self.html rangeOfString:@"车票预订"];
    if (range.length == 0) {
        NSLog(@"获取订票页面出错");
        return SUBMUTORDER_MSG_ERR;
    }
    
    range = [self.html rangeOfString:@"现在是系统例行维护时间"];
    if (range.length > 0) {
        NSLog(@"现在是系统例行维护时间");
        return SUBMUTORDER_MSG_OUT_OF_SERVICE;
    }
    
    range = [self.html rangeOfString:@"该车次在互联网已停止办理业务"];
    if (range.length > 0) {
        NSLog(@"该车次在互联网已停止办理业务");
        return SUBMUTORDER_MSG_EXPIRED;
    }
    
    range = [self.html rangeOfString:@"未处理的订单"];
    if (range.length > 0) {
        NSLog(@"还有未处理订单，无法继续订票");
        return SUBMUTORDER_MSG_UNFINISHORDER_DETECTED;
    }
    
    @try {
        TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData];
        
        self.leftTicketID = [self parseLeftTicketID:xpathParser];
        self.apacheToken = [self parseApacheToken:xpathParser];
        
        NSLog(@"leftTicketID = %@ ; apacheToken = %@", self.leftTicketID, self.apacheToken);
        
        /* 获取余票和票价 */
        {
            NSArray *elements = [xpathParser searchWithXPathQuery:@"//form[@id='confirmPassenger']/table"];
            NSMutableArray *array = [[NSMutableArray alloc] init];
            
            elements = [[[[elements objectAtIndex:0] children] objectAtIndex:6] children];
            
            for (TFHppleElement *element in elements) {
                NSString *ticket = [element.firstChild content];
                if (ticket)
                    [array addObject:ticket];
            }
            self.ticketList = [[NSArray alloc] initWithArray:array];
        }
        
        /* 获取可用的座位类型，比如硬座、硬卧 */
        {
            NSArray *elements = [xpathParser searchWithXPathQuery:@"//select[@name='passenger_1_seat']/option"];
            NSMutableArray *array = [[NSMutableArray alloc] init];
            
            for (TFHppleElement *element in elements) {
                NSArray *e = [[NSArray alloc] initWithObjects:
                              [element.attributes objectForKey:@"value"],
                              [element.firstChild content],
                              nil];
                if (e)
                    [array addObject:e];
            }
            self.seatTypeList = [[NSArray alloc] initWithArray:array];
        }
        if (self.seatTypeList.count == 0)
            return SUBMUTORDER_MSG_ERR;
        
        {
            NSArray *elements = [xpathParser searchWithXPathQuery:@"//select[@name='passenger_1_ticket']/option"];
            NSMutableArray *array = [[NSMutableArray alloc] init];
            
            for (TFHppleElement *element in elements) {
                NSArray *e = @[[element.attributes objectForKey:@"value"],[element.firstChild content]];
                NSString *title = [element.firstChild content];
                if ([title hasPrefix:@"儿童"]) {
                    // 儿童票由于不能单独购买，所以先省略
                } else {
                    [array addObject:e];
                }
            }
            self.ticketTypeList = [[NSArray alloc] initWithArray:array];
        }
        
        if (self.ticketTypeList.count == 0)
            return SUBMUTORDER_MSG_ERR;
        
        return SUBMUTORDER_MSG_SUCCESS;
    }
    @catch (NSException *exception) {
        // 主要用于识别登录超时的情况
        NSLog(@"[EXCEPTION] %@", exception);
        return SUBMUTORDER_MSG_ACCESS_FAILED;
    }
}

- (void)retriveEssentialInfoUsingGCD
{
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        NSData *htmlData = [[GlobalDataStorage tdbss] submutOrderRequestWithTrainInfo:self.train date:self.departDate];
        SUBMUTORDER_MSG result = [self parseHTMLWithData:htmlData];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self retriveVerifyCodeUsingGCD];
            
            if (result == SUBMUTORDER_MSG_SUCCESS) {
                
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
                
                self.isLoadingFinished = YES;
            } else if (result == SUBMUTORDER_MSG_UNFINISHORDER_DETECTED) {

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法购票"
                                           message:@"您尚有未处理的订单，要前往查看吗"
                                          delegate:self
                                 cancelButtonTitle:@"暂时不用"
                                 otherButtonTitles:@"查看", nil];
                alert.tag = SUBMUTORDER_MSG_UNFINISHORDER_DETECTED;
                [alert show];
                 
            } else if (result == SUBMUTORDER_MSG_OUT_OF_SERVICE) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法购票" message:@"每天23点到次日7点是系统维护时间" delegate:self
                                                      cancelButtonTitle:@"好的" otherButtonTitles: nil];
                alert.tag = SUBMUTORDER_MSG_OUT_OF_SERVICE;
                [alert show];
            } else if (result == SUBMUTORDER_MSG_EXPIRED) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法购票" message:@"该车次已停止办理互联网售票业务" delegate:self
                                                      cancelButtonTitle:@"好的" otherButtonTitles: nil];
                alert.tag = SUBMUTORDER_MSG_OUT_OF_SERVICE;
                [alert show];
            } else if (result == SUBMUTORDER_MSG_ACCESS_FAILED) {
                // 主要用于提示登录超时出现的问题
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"登录超时" message:@"请重新登录" delegate:self
                                                      cancelButtonTitle:@"好的" otherButtonTitles: nil];
                alert.tag = SUBMUTORDER_MSG_OUT_OF_SERVICE;
                [alert show];
            } else {
                NSLog(@"PAGE NOT LOADING PROPERLY");
            }
        });
    });
}

- (void)retriveVerifyCodeUsingGCD
{
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSData *image = [[GlobalDataStorage tdbss] getRandpImage];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.verifyCodeImage.image = [UIImage imageWithData:image];
            [self.refreshVerifyCodeBtn setImage:[UIImage imageWithData:image] forState:UIControlStateNormal];
            [SVProgressHUD dismiss];
        });
    });
}

- (NSString *)parseLeftTicketID:(TFHpple *)xpathParser
{
    NSArray *elements = [xpathParser searchWithXPathQuery:@"//input[@name='leftTicketStr']"];
    TFHppleElement *element = [elements objectAtIndex:0];
    
    return [element.attributes objectForKey:@"value"];
}

- (NSString *)parseApacheToken:(TFHpple *)xpathParser
{
    
    NSArray *elements = [xpathParser searchWithXPathQuery:@"//input[@name='org.apache.struts.taglib.html.TOKEN']"];
    TFHppleElement *element = [elements objectAtIndex:0];
    
    return [element.attributes objectForKey:@"value"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isLoadingFinished = NO;
    [self configureView];
    [self retriveEssentialInfoUsingGCD];
    
    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
}

- (IBAction)_backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
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
    [self retriveVerifyCodeUsingGCD];
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
            
            TDBSession *tdbss = [GlobalDataStorage tdbss];
            NSString *date = self.departDate;
            PassengerInfo *passenger = [[PassengerInfo alloc] init];
            
            passenger.seat = [[self.seatTypeList objectAtIndex:self.seatTypeSelector.selectedSegmentIndex] objectAtIndex:0];
            passenger.ticket = [[self.ticketTypeList objectAtIndex:self.ticketTypeSelector.selectedSegmentIndex] objectAtIndex:0];
            passenger.name = self.name.text;
            passenger.id_cardtype = @"1";
            passenger.id_cardno = [self.idCardNo.text uppercaseString];
            passenger.mobileno = self.mobileno.text;
            NSString *verifyCode = self.verifyCode.text;
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            UIBarButtonItem *submitBtn = self.navigationItem.rightBarButtonItem;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
            
            MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
            overlay.hidesActivity = NO;
            [overlay postMessage:@"正在提交请求"];
            
            __block BOOL haveError = NO;
            dispatch_queue_t orderQueue = dispatch_queue_create("12306 orderTicket", DISPATCH_QUEUE_SERIAL);
            dispatch_async(orderQueue, ^(void) {
                
                sleep(0.5);
                NSString *returnMsg = [tdbss checkOrderInfo:self.train passenger:passenger date:date
                                              leftTicketStr:self.leftTicketID apacheToken:self.apacheToken randCode:verifyCode];
                if (returnMsg == nil) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressView.progress = 0.33;
                        [overlay postMessage:@"订单信息验证成功" duration:2.f];
                    });
                    
                } else {
                    haveError = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressView.progress = 0.33;
                        [overlay postErrorMessage:returnMsg duration:2.f];
                        self.navigationItem.rightBarButtonItem = submitBtn;
                    });
                }
                
            });
            
            dispatch_async(orderQueue, ^(void) {
                
                if (!haveError) {
                    sleep(1);
                    if ([tdbss getQueueCount:self.train passenger:passenger date:date leftTicketID:self.leftTicketID]) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.progressView.progress = 0.66;
                            [overlay postMessage:@"余票信息确认完毕" duration:2.f];
                        });
                    } else {
                        haveError = YES;
                    }
                }
                
            });
            
            dispatch_async(orderQueue, ^(void) {
                
                if (!haveError) {
                    sleep(2);
                    if (!haveError && [tdbss confirmSingleForQueue:self.train passenger:passenger date:date
                                                     leftTicketStr:self.leftTicketID apacheToken:self.apacheToken randCode:verifyCode]) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.progressView.progress = 1;
                            [overlay postImmediateFinishMessage:@"订票信息已经确认，请继续完成支付" duration:2.f animated:YES];
                            self.navigationItem.rightBarButtonItem = nil;
                        });
                    }
                }
                
            });
            
            break;
        }
    }
}

@end
