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
        
        TDBOrder *order = self.order;
        epayViewController.apacheToken = self.apacheToken;
        epayViewController.ticketKey = order.ticketKey;
        epayViewController.orderSequenceNo = order.orderSquence_no;
    }
}

#pragma mark - Table view data source

- (void)viewDidUnload {
    [super viewDidUnload];
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSData *result = [[GlobalDataStorage tdbss] cancleMyOrderNotComplete:self.order.orderSquence_no apacheToken:self.apacheToken];
            NSString *html = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
            NSRange range = [html rangeOfString:@"取消订单成功"];
            BOOL success = (range.length > 0);
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIAlertView *alert;
                if (success) {
                    alert = [[UIAlertView alloc] initWithTitle:@"取消成功" message:@"您已成功取消订单" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
                } else {
                    alert = [[UIAlertView alloc] initWithTitle:@"取消失败" message:@"无法取消订单" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
                }
                alert.tag = TAGLIST_AFTER_CANCLE;
                [alert show];
            });
        });
    } else if (alertView.tag == TAGLIST_AFTER_CANCLE) {
        // 用户订单取消后的反馈
        [self popAndRefresh];
    }
}

@end
