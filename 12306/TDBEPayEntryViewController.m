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
#import "UIButton+TDBAddition.h"
#import "SVProgressHUD.h"
#import "MobClick.h"

#import "Macros.h"
#import "TDBHTTPClient.h"

@interface TDBEPayEntryViewController () <UIWebViewDelegate>

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
    [MobClick event:@"EPayEntry"];
	// Do any additional setup after loading the view.
//    
//    // 进入后，用户总览全局
//    self.webView.scalesPageToFit = YES;
//    self.webView.delegate = self;
//    
//    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
//    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
//    
//    [self retriveEssentialInfoUsingGCD];
    [[TDBHTTPClient sharedClient] payOrderInit:^(NSData *data) {
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }];
}

- (IBAction)_backPressed:(id)sender
{
    [SVProgressHUD dismiss];
    [[[TDBHTTPClient sharedClient] operationQueue] cancelAllOperations];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)_parseHTMLWithData:(TFHpple *)parser
{
    NSArray *elements = [parser searchWithXPathQuery:@"//form[@id='epayForm']"];
    if (elements.count == 0) {
        return nil;
    } else {
        return [[elements objectAtIndex:0] raw];
    }
}

- (NSString *)_retriveBoxWrapHtml:(TFHpple *)parser
{
    NSArray *elements = [parser searchWithXPathQuery:@"//div[@class='box-wrap']"];
    if (elements.count == 0) {
        // 这个不是很重要，如果找不到设置为空字串即可
        return @"";
    } else {
        return [[elements objectAtIndex:0] raw];
    }
}

- (NSString *)_retriveOrderTableHtml:(TFHpple *)parser
{
    NSArray *elements = [parser searchWithXPathQuery:@"//table[@class='table_list']"];
    if (elements.count == 0) {
        return nil;
    } else {
        return [[elements objectAtIndex:0] raw];
    }
}

- (NSString *)_parseLeaseTime:(NSString *)html
{
    NSString *result = nil;
    @try {
        NSRange start = [html rangeOfString:@"var loseTime"];
        NSRange end = [html rangeOfString:@"var epayurl"];
        NSRange range = NSMakeRange(start.location, end.location - start.location);
        result = [html substringWithRange:range];
    }
    @catch (NSException *exception) {
        // do nothing
    }
    return result;
}

- (void)retriveEssentialInfoUsingGCD
{
    [SVProgressHUD show];
    
    WeakSelf(wself, self);
    [[TDBHTTPClient sharedClient] laterEpayWithOrderSequenceNo:self.orderSequenceNo apacheToken:self.apacheToken ticketKey:self.ticketKey
        success:^(NSData *htmlData) {
            CHECK_INSTANCE_EXIST(wself);
            
            NSString *html = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
            
            TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData];
            NSString *leaseTimeJS = [wself _parseLeaseTime:html];
            NSString *epayCode = [wself _parseHTMLWithData:xpathParser];
            NSString *boxWrapper = [wself _retriveBoxWrapHtml:xpathParser];
            NSString *orderHtml = [wself _retriveOrderTableHtml:xpathParser];
            
            NSString *styleSheet = @"";
            
            CHECK_INSTANCE_EXIST(wself);
            
            if (epayCode && orderHtml) { // 防止订单正好超时，导致result为空造成系统崩溃问题
                NSRange range = NSMakeRange(0, epayCode.length - @"</form>".length);
                epayCode = [epayCode substringWithRange:range];
                
                NSString *filePath = [[NSBundle mainBundle] pathForResource:@"epay" ofType:@"html"];
                NSString *templateHtml = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                NSString *htmlCode = [NSString stringWithFormat:templateHtml, styleSheet, leaseTimeJS, boxWrapper, orderHtml, epayCode];
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    StrongSelf(sself, wself);
                    if (sself) {
                        NSURL *baseURL = [NSURL URLWithString:@"http://dynamic.12306.cn/otsweb/order/myOrderAction.do"];
                        [sself.webView loadHTMLString:htmlCode baseURL:baseURL];
                    }
                });
            } else {
#warning 订单支付时发现超时或已被取消的提示
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [SVProgressHUD showErrorWithStatus:@"网络异常，请重新进入"];
                    NSLog(@"网络异常，请重新进入");
                });
            }

        }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [SVProgressHUD dismiss];
}

@end
