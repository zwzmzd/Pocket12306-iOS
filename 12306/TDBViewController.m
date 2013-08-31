//
//  TDBViewController.m
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBViewController.h"
#import "LoginFrameViewController.h"
#import "GlobalDataStorage.h"
#import "TDBStationName.h"
#import "TDBStationAndDateSelector.h"
#import "TDBKeybordNotificationManager.h"
#import "TDBListViewController.h"

#define USER_LAST_INPUT_DEPART_STATION_NAME (@"__userLastInputDepartStationName")
#define USER_LAST_INPUT_ARRIVE_STATION_NAME (@"__userLastInputArriveStationName")
#define USER_SELECT_STATION_NAME_EXACTLY_MATCH (@"__userSelectStationNameExactlyMatch")

@interface TDBViewController ()

@property (nonatomic) TDBStationName *stationNameController;
@property (nonatomic) TDBStationAndDateSelector *selectorView;

@end

@implementation TDBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    static UIBarButtonItem *buyTicket = nil;
//    if ([GlobalDataStorage tdbss]) {
//        self.navigationItem.leftBarButtonItem.title = @"注销/更换账户";
//        self.title = @"车票查询";
//        
//        if (buyTicket)
//            self.navigationItem.rightBarButtonItem = buyTicket;
//        
//        
//    } else {
//        if (self.navigationItem.rightBarButtonItem)
//            buyTicket = self.navigationItem.rightBarButtonItem;
//        self.navigationItem.rightBarButtonItem = nil;
//    }
    
    if (_selectorView == nil) {
        TDBStationAndDateSelector *customView = [[TDBStationAndDateSelector alloc] initWithDelegate:self];
        
        [self.view addSubview:customView];
        /*
         这个方法结束后，self.view会被设置，所以只要好好实现viewDidLayoutSubviews，这里不需要
         设置customView.fram
         */
        self.selectorView = customView;
        
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        self.selectorView.departStationField.text = [ud stringForKey:USER_LAST_INPUT_DEPART_STATION_NAME];
        self.selectorView.arriveStationField.text = [ud stringForKey:USER_LAST_INPUT_ARRIVE_STATION_NAME];
        [self.selectorView.stationNameExactlyMatch setOn:[ud boolForKey:USER_SELECT_STATION_NAME_EXACTLY_MATCH]];
    }
    
    [self initStationNameControllerUsingGCD];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    TDBKeybordNotificationManager *manager = [TDBKeybordNotificationManager getSharedManager];
    [manager addNotificationHandler:self];
    
    // 下面是专门为iOS 6+准备的，是系统一个奇怪的特性
    // 在键盘的中文输入状态下，键盘上方有个中文输入的框，如果此时push（或者present）一个页面，再返回时
    // 这个中文框就会消失，键盘变动的消息会在viewDidAppear之前发生，只能在这里多计算一次
    
    [self resizeSubMainView];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    TDBKeybordNotificationManager *manager = [TDBKeybordNotificationManager getSharedManager];
    [manager removeNotificationHandler:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initStationNameControllerUsingGCD
{
    if (self.stationNameController == nil) {
        dispatch_queue_t orderQueue = dispatch_queue_create("12306 fetchStationName", DISPATCH_QUEUE_SERIAL);
        dispatch_async(orderQueue, ^(void) {
            
            TDBStationName *dataController = [[TDBStationName alloc] init];
            [dataController fetchStationNameRawTextFromNet];
            [dataController parseRawText];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.stationNameController = dataController;
            });
        });
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToListView"]) {
        TDBListViewController *lv = [segue destinationViewController];
        
        NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        self.selectorView.departStationField.text = [self.selectorView.departStationField.text stringByTrimmingCharactersInSet:characterSet];
        self.selectorView.arriveStationField.text = [self.selectorView.arriveStationField.text stringByTrimmingCharactersInSet:characterSet];
        
        // 记录下目前输入的信息，在购票详情页面校验起点和终点站是否一致
        [GlobalDataStorage setUserInputArriveStation:self.selectorView.arriveStationField.text];
        [GlobalDataStorage setUserInputDepartStation:self.selectorView.departStationField.text];
        
        // 标识用户是否需要精确匹配站名
        BOOL stationNameExactlyMatch = self.selectorView.stationNameExactlyMatch.isOn;
        
        // 保存用户偏好
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:self.selectorView.departStationField.text forKey:USER_LAST_INPUT_DEPART_STATION_NAME];
        [ud setObject:self.selectorView.arriveStationField.text forKey:USER_LAST_INPUT_ARRIVE_STATION_NAME];
        [ud setBool:stationNameExactlyMatch forKey:USER_SELECT_STATION_NAME_EXACTLY_MATCH];
        [ud synchronize];
        
        lv.departStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.selectorView.departStationField.text];
        lv.arriveStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.selectorView.arriveStationField.text];
        lv.orderDate = self.selectorView.userSelectedDate;
        // 设置精确匹配站名
        lv.stationNameExactlyMatch = stationNameExactlyMatch;
        
        NSLog(@"%@ %@", lv.departStationTelecode, lv.arriveStationTelecode);
    }
}



- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    /**
     这个方法在self.view.frame变化的时候会被调用，作用相当于[self.view layoutSubviews]
     
     在键盘没有开启的状态下，self.view.frame会被自动设置成为可用窗口的大小。
     但键盘的开启会遮挡部分试图，输入控件可能会位于键盘下方，所以要在别的地方侦听
     键盘开启关闭消息，并设置正确的self.view.frame
     **/

    // 这里更改了控制，现在是保证主界面的size不变，子界面根据主界面size和当前keyboard高度计算出自己的size
    [self resizeSubMainView];
}

- (void)resizeSubMainView
{
//    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
//    BOOL isLandscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
    
    CGSize size = self.view.frame.size;
    self.selectorView.frame = CGRectMake(0,0, size.width ,
                                 size.height - [TDBKeybordNotificationManager getSharedManager].keyboardHeight);
}

- (IBAction)cancleLogin:(UIStoryboard *)segue
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField selectAll:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - KeyboardNotificationDelegate

- (void)keyboardEvent:(BOOL)visible withAnimationDurationTime:(NSTimeInterval)timeInterval
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:timeInterval];
    
    [self resizeSubMainView];
    
    [UIView commitAnimations];
}

@end
