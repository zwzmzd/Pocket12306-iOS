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
    
    
    
    //[self setUpForDismissKeyboard];
}

- (void)viewWillAppear:(BOOL)animated
{
#warning need to revert the logical
    static UIBarButtonItem *buyTicket = nil;
    [super viewWillAppear:animated];
    if ([GlobalDataStorage tdbss]) {
        self.navigationItem.leftBarButtonItem = nil;
        self.title = @"车票查询";
        
        //if (buyTicket)
            //self.navigationItem.rightBarButtonItem = buyTicket;
    } else {
        //if (self.navigationItem.rightBarButtonItem)
            //buyTicket = self.navigationItem.rightBarButtonItem;
        //self.navigationItem.rightBarButtonItem = nil;
    }
    
    if (self.selectorView == nil) {
        TDBStationAndDateSelector *customView = [[TDBStationAndDateSelector alloc] initWithDelegate:self];
        customView.frame = CGRectMake(0.f, 100.f, self.view.bounds.size.width, 300.f);
        
        [self.view addSubview:customView];
        self.selectorView = customView;
    }
    
    TDBKeybordNotificationManager *manager = [TDBKeybordNotificationManager getSharedManager];
    [manager addNotificationHandler:self];
    
    [self initStationNameControllerUsingGCD];

}

- (void)viewWillDisappear:(BOOL)animated
{
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
        lv.departStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.selectorView.departStationField.text];
        lv.arriveStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.selectorView.arriveStationField.text];
        
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

- (void)keyboardEvent:(BOOL)visible
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
    }
}

@end
