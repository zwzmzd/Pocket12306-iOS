//
//  TDBOrderOperationViewController.m
//  12306
//
//  Created by macbook on 13-8-4.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBOrderOperationViewController.h"
#import  "GlobalDataStorage.h"
#import "TDBSession.h"
#import "TDBOrder.h"
#import "TDBEPayEntryViewController.h"
#import "TDBOrderListViewController.h"
#import "UIButton+TDBAddition.h"
#import "TDBHTTPClient.h"

typedef enum {
    TAGLIST_BEFORE_CANCLE = 1,
    TAGLIST_AFTER_CANCLE
} TAGLIST;

@interface TDBOrderOperationViewController () <UIAlertViewDelegate>

@end

@implementation TDBOrderOperationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.orderSequenceNo.text = self.order.orderSequence_no;
    self.orderPrice.text = self.order.totalPrice;
    
    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    MobClickBeginLogPageView();
}

- (void)viewWillDisappear:(BOOL)animated {
    MobClickEndLogPageView();
    [super viewWillDisappear:animated];
}

- (IBAction)_backPressed:(id)sender
{
    [[TDBHTTPClient sharedClient] cancelAllHTTPRequest];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)popAndRefresh
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.receiver forceRefreshOrderList];
    });
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EPaySegue"]) {
        TDBEPayEntryViewController *epayViewController = segue.destinationViewController;
        epayViewController.totalPrice = self.order.totalPrice;
        epayViewController.orderSequenceNo = self.order.orderSequence_no;
        
    }
}

- (IBAction)iWantToRefresh:(id)sender {
    [self popAndRefresh];
}

- (IBAction)iWantToCancleOrder:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请注意" message:@"若一日累计三次取消未完成订单，该账号今日不能继续购票" delegate:self cancelButtonTitle:@"算了" otherButtonTitles:@"务必帮我取消", nil];
    alert.tag = TAGLIST_BEFORE_CANCLE;
    [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == TAGLIST_BEFORE_CANCLE && buttonIndex != alertView.cancelButtonIndex) {
        // 用户试图取消订单
        WeakSelf(wself, self);
        [[TDBHTTPClient sharedClient] queryMyOrderNoComplete:^(NSArray *_nouse) {
            CHECK_INSTANCE_EXIST(wself);
            [[TDBHTTPClient sharedClient] cancelNoCompleteMyOrder:wself.order.orderSequence_no success:^(BOOL result, NSArray *messages) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    StrongSelf(sself, wself);
                    if (sself) {
                        UIAlertView *alert;
                        if (result) {
                            alert = [[UIAlertView alloc] initWithTitle:@"取消成功" message:@"您已成功取消订单" delegate:sself cancelButtonTitle:@"确定" otherButtonTitles: nil];
                        } else {
                            alert = [[UIAlertView alloc] initWithTitle:@"取消失败" message:[messages firstObject] delegate:sself cancelButtonTitle:@"确定" otherButtonTitles: nil];
                        }
                        alert.tag = TAGLIST_AFTER_CANCLE;
                        [alert show];
                    }
                });
            }];
        }];
    } else if (alertView.tag == TAGLIST_AFTER_CANCLE) {
        // 用户订单取消后的反馈
        [self popAndRefresh];
    }
}

- (void)viewDidUnload {
    [self setOrderSequenceNo:nil];
    [super viewDidUnload];
}
@end
