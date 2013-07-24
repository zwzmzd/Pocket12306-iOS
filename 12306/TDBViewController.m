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

@interface TDBViewController ()

@property (nonatomic) TDBStationName *stationNameController;
@property (nonatomic) TDBStationAndDateSelector *selectorView;

@end

@implementation TDBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    TDBStationAndDateSelector *customView = [[TDBStationAndDateSelector alloc] initWithDelegate:self];
    customView.frame = CGRectMake(0.f, 100.f, self.view.bounds.size.width, 300.f);

    [self.view addSubview:customView];
    self.selectorView = customView;
    
    //[self setUpForDismissKeyboard];
}

- (void)viewWillAppear:(BOOL)animated
{
    static UIBarButtonItem *buyTicket = nil;
    [super viewWillAppear:animated];
    if ([GlobalDataStorage tdbss]) {
        self.navigationItem.leftBarButtonItem = nil;
        self.title = @"车票查询";
        
        if (buyTicket)
            self.navigationItem.rightBarButtonItem = buyTicket;\
        
        [self initStationNameControllerUsingGCD];
    } else {
        if (self.navigationItem.rightBarButtonItem)
            buyTicket = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    TDBKeybordNotificationManager *manager = [TDBKeybordNotificationManager getSharedManager];
    [manager addNotificationHandler:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    TDBKeybordNotificationManager *manager = [TDBKeybordNotificationManager getSharedManager];
    [manager addNotificationHandler:self];
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

- (void)setUpForDismissKeyboard
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [nc addObserverForName:UIKeyboardDidShowNotification object:nil queue:mainQueue
                usingBlock:^(NSNotification *note){
                    NSLog(@"disappear");
                }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize size = self.view.bounds.size;
    self.selectorView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (IBAction)cancleLogin:(UIStoryboard *)segue
{
    [self dismissViewControllerAnimated:YES completion:NULL];
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

#pragma mark - KeyboardNotificationDelegate

- (void)keyboardEvent:(BOOL)visible
{
    if (visible) {
        CGSize size = [[UIScreen mainScreen] bounds].size;
        self.view.frame = CGRectMake(0,0, size.width , size.height -  self.navigationController.navigationBar.frame.size.height - 20 - [TDBKeybordNotificationManager getSharedManager].keyboardHeight);
    } else {
        CGSize size = [[UIScreen mainScreen] bounds].size;
        self.view.frame = CGRectMake(0,0, size.width, size.height - self.navigationController.navigationBar.frame.size.height - 20);
    }
}

@end
