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
#import "KGStatusBar.h"

@interface TDBTicketDetailViewController () <UIAlertViewDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;

@property (nonatomic, copy) NSString *html;
@property (nonatomic, copy) NSString *leftTicketID;
@property (nonatomic, copy) NSString *apacheToken;
@property (nonatomic) NSArray *ticketList;
@property (nonatomic) NSArray *seatTypeList;
@property (nonatomic) NSArray *ticketTypeList;

@property (nonatomic) BOOL isLoadingFinished;

@end

@implementation TDBTicketDetailViewController

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
    
    range = [self.html rangeOfString:@"未处理的订单"];
    if (range.length > 0) {
        NSLog(@"还有未处理订单，无法继续订票");
        return SUBMUTORDER_MSG_UNFINISHORDER_DETECTED;
    }
    
    
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
            NSArray *e = [[NSArray alloc] initWithObjects:
                          [element.attributes objectForKey:@"value"],
                          [element.firstChild content],
                          nil];
            if (e)
                [array addObject:e];
        }
        self.ticketTypeList = [[NSArray alloc] initWithArray:array];
    }
    
    if (self.ticketTypeList.count == 0)
        return SUBMUTORDER_MSG_ERR;
    
    return SUBMUTORDER_MSG_SUCCESS;
}

- (void)retriveEssentialInfoUsingGCD
{
    [self retriveVerifyCodeUsingGCD];
    
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 traininfo", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        
        NSData *htmlData = [[GlobalDataStorage tdbss] submutOrderRequestWithTrainInfo:self.train date:self.departDate];
        SUBMUTORDER_MSG result = [self parseHTMLWithData:htmlData];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
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
                [alert show];
            } else {
                NSLog(@"PAGE NOT LOADING PROPERLY");
            }
        });
    });
}

- (void)retriveVerifyCodeUsingGCD
{
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 traininfo", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        
        NSData *image = [[GlobalDataStorage tdbss] getRandpImage];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
                self.verifyCodeImage.image = [UIImage imageWithData:image];
                [self.refreshVerifyCodeBtn setImage:[UIImage imageWithData:image] forState:UIControlStateNormal];
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
    [self setUpForDismissKeyboard];
    
    [self retriveEssentialInfoUsingGCD];
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

- (BOOL)checkTextField
{
    if (self.name.text.length == 0) {
        [KGStatusBar showErrorWithStatus:@"请正确填写您的姓名"];
        return NO;
    }
    if (self.idCardNo.text.length == 0) {
        [KGStatusBar showErrorWithStatus:@"请正确填写您的身份证号码"];
        return NO;
    }
    if (self.verifyCode.text.length == 0) {
        [KGStatusBar showErrorWithStatus:@"请填写验证码"];
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
    
    TDBSession *tdbss = [GlobalDataStorage tdbss];
    NSString *date = self.departDate;
    PassengerInfo *passenger = [[PassengerInfo alloc] init];
    
    passenger.seat = [[self.seatTypeList objectAtIndex:self.seatTypeSelector.selectedSegmentIndex] objectAtIndex:0];
    passenger.ticket = [[self.ticketTypeList objectAtIndex:self.ticketTypeSelector.selectedSegmentIndex] objectAtIndex:0];
    passenger.name = self.name.text;
    passenger.id_cardtype = @"1";
    passenger.id_cardno = self.idCardNo.text;
    passenger.mobileno = self.mobileno.text;
    NSString *verifyCode = self.verifyCode.text;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    [KGStatusBar showWithStatus:@"正在提交请求"];
    
    dispatch_queue_t orderQueue = dispatch_queue_create("12306 orderTicket", DISPATCH_QUEUE_SERIAL);
    dispatch_async(orderQueue, ^(void) {
        sleep(0.5);
        if ([tdbss checkOrderInfo:self.train passenger:passenger date:date
                    leftTicketStr:self.leftTicketID apacheToken:self.apacheToken randCode:verifyCode]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.progress = 0.33;
                [KGStatusBar showWithStatus:@"订单信息验证成功"];
            });
        }
        sleep(1);
    });
    dispatch_async(orderQueue, ^(void) {
        if ([tdbss getQueueCount:self.train passenger:passenger date:date leftTicketID:self.leftTicketID]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.progress = 0.66;
                [KGStatusBar showWithStatus:@"余票信息确认完毕"];
            });
        }
        sleep(2);
    });
    dispatch_async(orderQueue, ^(void) {
        
        if ([tdbss confirmSingleForQueue:self.train passenger:passenger date:date
                           leftTicketStr:self.leftTicketID apacheToken:self.apacheToken randCode:verifyCode]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.progress = 1;
                [KGStatusBar showSuccessWithStatus:@"订票信息已经确认，请继续完成支付"];
                self.navigationItem.rightBarButtonItem = nil;
            });
        }
    });
    
}

- (IBAction)refreshVerifyCode:(id)sender {
    [self retriveVerifyCodeUsingGCD];
}

- (void)setUpForDismissKeyboard
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [nc addObserverForName:UIKeyboardWillShowNotification object:nil queue:mainQueue
                usingBlock:^(NSNotification *note){
                    //NSLog(@"willlog");
                }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"SeatDetail"]) {
        TDBSeatDetailViewController *vc = [segue destinationViewController];
        vc.dataController = self.ticketList;
        [vc.tableView reloadData];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
#warning You should set alert's delegate properly
    [self.navigationController popViewControllerAnimated:YES];
}

@end
