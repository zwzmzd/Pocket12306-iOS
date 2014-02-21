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
#import "TDBHTTPClient.h"
#import "TDBDateShower.h"
#import "MobClick.h"

#define USER_LAST_INPUT_DEPART_STATION_NAME (@"__userLastInputDepartStationName")
#define USER_LAST_INPUT_ARRIVE_STATION_NAME (@"__userLastInputArriveStationName")
#define USER_SELECT_STATION_NAME_EXACTLY_MATCH (@"__userSelectStationNameExactlyMatch")

@interface TDBViewController () <UITextFieldDelegate>

@property (nonatomic) TDBStationName *stationNameController;
@property (nonatomic, strong) UIView *mask;

@end

@implementation TDBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [MobClick event:@"MainViewControllerLoad"];
    
    self.dateShower.parentController = self;
    
    self.departStationField.delegate = self;
    self.arriveStationField.delegate = self;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    self.departStationField.text = [ud stringForKey:USER_LAST_INPUT_DEPART_STATION_NAME];
    self.arriveStationField.text = [ud stringForKey:USER_LAST_INPUT_ARRIVE_STATION_NAME];
    [self.stationNameExactlyMatch setOn:[ud boolForKey:USER_SELECT_STATION_NAME_EXACTLY_MATCH]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    static UIBarButtonItem *buyTicket = nil;
    
    if ([GlobalDataStorage tdbss]) {
        self.navigationItem.leftBarButtonItem.title = @"更换账户";
        self.title = @"购票";
        
        if (buyTicket)
            self.navigationItem.rightBarButtonItem = buyTicket;
        
        [self.mask removeFromSuperview];
    } else {
        self.navigationItem.leftBarButtonItem.title = @"请登录";
        if (self.navigationItem.rightBarButtonItem)
            buyTicket = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
        
        self.mask.frame = self.view.bounds;
        UIView *wrapperView = self.view.superview;
        [wrapperView addSubview:self.mask];
        [wrapperView bringSubviewToFront:self.mask];
    }
    
    [self initStationNameControllerUsingGCD];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIView *wrapperView = self.view.superview;
    self.mask.frame = wrapperView.bounds;
}

- (void)initStationNameControllerUsingGCD
{
    self.stationNameController = [[TDBStationName alloc] init];
    [self.stationNameController fetchStationNameRawTextFromNet];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToListView"]) {
        TDBListViewController *lv = [segue destinationViewController];
        
        NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        self.departStationField.text = [self.departStationField.text stringByTrimmingCharactersInSet:characterSet];
        self.arriveStationField.text = [self.arriveStationField.text stringByTrimmingCharactersInSet:characterSet];
        
        // 记录下目前输入的信息，在购票详情页面校验起点和终点站是否一致
        [GlobalDataStorage setUserInputArriveStation:self.arriveStationField.text];
        [GlobalDataStorage setUserInputDepartStation:self.departStationField.text];
        
        // 标识用户是否需要精确匹配站名
        BOOL stationNameExactlyMatch = self.stationNameExactlyMatch.isOn;
        
        // 保存用户偏好
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:self.departStationField.text forKey:USER_LAST_INPUT_DEPART_STATION_NAME];
        [ud setObject:self.arriveStationField.text forKey:USER_LAST_INPUT_ARRIVE_STATION_NAME];
        [ud setBool:stationNameExactlyMatch forKey:USER_SELECT_STATION_NAME_EXACTLY_MATCH];
        [ud synchronize];
        
        lv.departStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.departStationField.text];
        lv.arriveStationTelecode = [self.stationNameController
                                    getTelecodeUsingName:self.arriveStationField.text];
        lv.orderDate = self.dateShower.orderDate;
        // 设置精确匹配站名
        lv.stationNameExactlyMatch = stationNameExactlyMatch;
    }
}

- (UIView *)mask {
    if (_mask == nil) {
        _mask = [[UIView alloc] initWithFrame:CGRectZero];
        _mask.backgroundColor = [UIColor whiteColor];
    }
    return _mask;
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)doQuery:(id)sender {
    [self.departStationField resignFirstResponder];
    [self.arriveStationField resignFirstResponder];
    [self performSegueWithIdentifier:@"PushToListView" sender:sender];
}
@end
