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

@interface TDBEPayEntryViewController ()

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
        NSRange range = NSMakeRange(0, length - @"</form>".length);
        result = [result substringWithRange:range];
        
        
        NSString *htmlCode = [NSString stringWithFormat:@"<html><body>%@<input type='submit' value='点此按钮进入支付页面' /></form></body></html>", result];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            [self.webView loadHTMLString:htmlCode baseURL:nil];
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
