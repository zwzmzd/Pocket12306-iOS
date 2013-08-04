//
//  TDBEPayEntryViewController.m
//  12306
//
//  Created by macbook on 13-7-28.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBEPayEntryViewController.h"
#import "TDBSession.h"
#import "GlobalDataStorage.h"
#import "TFHpple.h"

@interface TDBEPayEntryViewController () <UIAlertViewDelegate>

@end

@implementation TDBEPayEntryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self retriveEssentialInfoUsingGCD];
}

- (NSString *)parseHTMLWithData:(NSData *)htmlData
{
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData];
    NSArray *elements = [xpathParser searchWithXPathQuery:@"//form[@id='epayForm']"];
    return [[elements objectAtIndex:0] raw];
}

- (void)retriveEssentialInfoUsingGCD
{
    
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 Epay", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        
        NSData *htmlData = [[GlobalDataStorage tdbss] laterEpayWithOrderSequenceNo:self.orderSequenceNo apacheToken:self.apacheToken ticketKey:self.ticketKey];
        NSString *result = [self parseHTMLWithData:htmlData];
        
        NSUInteger length = result.length;
        
        if (length > 0) { // 防止订单正好超时，导致result为空造成系统崩溃问题
            NSRange range = NSMakeRange(0, length - @"</form>".length);
            result = [result substringWithRange:range];
            
            NSString *htmlCode = [NSString stringWithFormat:@"<html><body>%@<input type='submit' value='点此按钮进入支付页面' /></form></body></html>", result];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.webView loadHTMLString:htmlCode baseURL:nil];
            });
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)iWantCancle:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSData *result = [[GlobalDataStorage tdbss] cancleMyOrderNotComplete:self.orderSequenceNo apacheToken:self.apacheToken];
        NSString *html = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        NSRange range = [html rangeOfString:@"取消订单成功"];
        BOOL success = (range.length > 0);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (success) {
                [[[UIAlertView alloc] initWithTitle:@"取消成功" message:@"您已成功取消订单" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"取消失败" message:@"无法取消订单" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
            }
        });
    });
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
