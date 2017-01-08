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
#import "TDBHTTPClient.h"

@interface TDBEPayEntryViewController () <UIWebViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, copy) NSString *epayurl;

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
    
//    // 进入后，用户总览全局
//    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    
    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
    
    [self retriveEssentialInfoUsingGCD];
    
    
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
    [SVProgressHUD dismiss];
    [[TDBHTTPClient sharedClient] cancelAllHTTPRequest];
    [self.webView stopLoading];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)_parsePaycheck:(NSDictionary *)data {
    NSString *epayURLKey = @"epayurl";
    self.epayurl = [data objectForKey:epayURLKey];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSMutableArray *paramaters = [NSMutableArray new];
        NSMutableArray *wapParameters = [NSMutableArray new];
        
        NSEnumerator *enumerator = [data keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            if ([key isEqualToString:epayURLKey]) {
                continue;
            }
            [paramaters addObject:[NSString stringWithFormat:@"<input name=\"%@\" type=\"hidden\" value=\"%@\" />", key, [data objectForKey:key]]];
        }
        
        [wapParameters addObject:[NSString stringWithFormat:@"<input name=\"%@\" type=\"hidden\" value=\"%@\" />",
                                  @"interfaceName", @"WAP_SERVLET"]];
        [wapParameters addObject:[NSString stringWithFormat:@"<input name=\"%@\" type=\"hidden\" value=\"%@\" />",
                                  @"interfaceVersion", @"1.0"]];
        [wapParameters addObject:[NSString stringWithFormat:@"<input name=\"%@\" type=\"hidden\" value=\"%@\" />", @"tranData", [data objectForKey:@"tranData"]]];
        [wapParameters addObject:[NSString stringWithFormat:@"<input name=\"%@\" type=\"hidden\" value=\"%@\" />", @"merSignMsg", [data objectForKey:@"merSignMsg"]]];
        [wapParameters addObject:[NSString stringWithFormat:@"<input name=\"%@\" type=\"hidden\" value=\"%@\" />",
                                  @"appId", @"0001"]];
        [wapParameters addObject:[NSString stringWithFormat:@"<input name=\"%@\" type=\"hidden\" value=\"%@\" />",
                                  @"transType", @"01"]];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"epay" ofType:@"html"];
        NSString *templateHtml = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSString *webPages = [NSString stringWithFormat:templateHtml, self.totalPrice, self.epayurl, [paramaters componentsJoinedByString:@"\n"], [wapParameters componentsJoinedByString:@"\n"]];
        
        NSURL *baseURL = [[NSURL alloc] initWithString:@"https://epay.12306.cn"];
        [self.webView loadHTMLString:webPages baseURL:baseURL];
    });
}

- (void)retriveEssentialInfoUsingGCD
{
    [SVProgressHUD show];
    
    WeakSelf(wself, self);
    [[TDBHTTPClient sharedClient] continuePayNoCompleteMyOrder:self.orderSequenceNo success:^(NSDictionary *result) {
        CHECK_INSTANCE_EXIST(wself);
        if (result == nil || [[[result objectForKey:@"data"] objectForKey:@"existError"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [SVProgressHUD showErrorWithStatus:@"解析错误，可能是订单未在指定时间内支付，请刷新订单列表后重试"];
            });
            return;
        }
        [[TDBHTTPClient sharedClient] payOrderInit:^(NSData *data) {
            CHECK_INSTANCE_EXIST(wself);
            [[TDBHTTPClient sharedClient] paycheck:^(NSDictionary *result) {
                CHECK_INSTANCE_EXIST(wself);
                NSDictionary *data = [[result objectForKey:@"data"] objectForKey:@"payForm"];
                if (data == nil || [[[result objectForKey:@"data"] objectForKey:@"existError"] boolValue]) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [SVProgressHUD showErrorWithStatus:@"解析错误，可能是订单未在指定时间内支付，请刷新订单列表后重试"];
                    });
                    return;
                }
                [wself _parsePaycheck:data];
            }];
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    _webView.delegate = nil;
    [_webView stopLoading];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSLog(@"[dealloc] %@ %p", [self class], self);
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
//    NSCachedURLResponse *resp = [[NSURLCache sharedURLCache] cachedResponseForRequest:webView.request];
//    NSLog(@"%@", resp.response);
//    NSLog(@"%@",[self.webView stringByEvaluatingJavaScriptFromString:
//                 @"document.body.innerHTML"]);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    NSLog(@"%@ %@", request, [request allHTTPHeaderFields]);
//    NSLog(@"%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    return YES;
}

@end
