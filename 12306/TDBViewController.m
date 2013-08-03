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

@interface TDBViewController ()

@property (nonatomic) TDBStationName *stationNameController;
@property (nonatomic) TDBStationAndDateSelector *selectorView;

@end

@implementation TDBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    static UIBarButtonItem *buyTicket = nil;
    if ([GlobalDataStorage tdbss]) {
        self.navigationItem.leftBarButtonItem = nil;
        self.title = @"车票查询";
        
        if (buyTicket)
            self.navigationItem.rightBarButtonItem = buyTicket;
        
        
    } else {
        if (self.navigationItem.rightBarButtonItem)
            buyTicket = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    if (_selectorView == nil) {
        TDBStationAndDateSelector *customView = [[TDBStationAndDateSelector alloc] initWithDelegate:self];
        
        [self.view addSubview:customView];
        self.selectorView = customView;
        
        /*
         这个方法结束后，self.view会被设置，所以只要好好实现viewDidLayoutSubviews，这里不需要
         设置customView.fram
         */
    }
    
    [self initStationNameControllerUsingGCD];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    TDBKeybordNotificationManager *manager = [TDBKeybordNotificationManager getSharedManager];
    [manager addNotificationHandler:self];
    
    // 用于后台唤醒程序时键盘遮挡处理
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resizeMainViewAfterADelay)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self resizeMainView];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    TDBKeybordNotificationManager *manager = [TDBKeybordNotificationManager getSharedManager];
    [manager removeNotificationHandler:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        lv.departStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.selectorView.departStationField.text];
        lv.arriveStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.selectorView.arriveStationField.text];
        lv.orderDate = self.selectorView.userSelectedDate;
        
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
    
    CGSize size = self.view.bounds.size;
    self.selectorView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)resizeMainViewAfterADelay
{
    // 主要用于从后台唤醒时的键盘遮挡处理
    // 只能这么办了，此时接收不到键盘的通知。系统在发出UIApplicationDidBecomeActiveNotification后，
    // 还会将self.view设置成不含键盘的高度，所以延迟一段时间后作调整
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        sleep(0.5);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self resizeMainView];
        });
    });
}
- (void)resizeMainView
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isLandscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
    
    if (isLandscape) {
        CGSize size = [[UIScreen mainScreen] bounds].size;
        self.view.frame = CGRectMake(0,0, size.height ,
                                     size.width - self.navigationController.navigationBar.frame.size.height - 20 - [TDBKeybordNotificationManager getSharedManager].keyboardHeight);
    } else {
        CGSize size = [[UIScreen mainScreen] bounds].size;
        self.view.frame = CGRectMake(0,0, size.width , size.height - self.navigationController.navigationBar.frame.size.height - 20 - [TDBKeybordNotificationManager getSharedManager].keyboardHeight);
        
        size = self.view.bounds.size;
    }
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
    
    [self resizeMainView];
    
    [UIView commitAnimations];
}

@end
