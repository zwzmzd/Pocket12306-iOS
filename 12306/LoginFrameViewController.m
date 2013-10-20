//
//  LoginFrameViewController.m
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "LoginFrameViewController.h"
#import "TDBSession.h"
#import "GlobalDataStorage.h"
#import "MBProgressHUD.h"
#import "SVProgressHUD.h"
#import "SSKeychain.h"
#import "TDBHTTPClient.h"
#import "Macros.h"

#define KEYCHAIN_SERVICE (@"12306_account")
#define KEYCHAIN_USERNAME_KEY (@"12306_account_username")
#define KEYCHAIN_PASSWORD_KEY (@"12306_account_password")
#define REMEMEBR_PROFILE_STATE_STOREAGE_KEY (@"rememberProfile_state")

@interface LoginFrameViewController ()

@property (nonatomic, strong) TDBSession *tdbss;
@property (nonatomic, strong) NSString *tokenValue;
@property (nonatomic, strong) NSString *tokenKey;

@end

@implementation LoginFrameViewController

# pragma mark - setter & getter

- (TDBSession *)tdbss
{
    if (_tdbss == nil){
        _tdbss = [[TDBSession alloc] init];
    }
    return _tdbss;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{     
    if (textField == self.username)
        [self.password becomeFirstResponder];
    else if (textField == self.password) {
        [self.verifyCode becomeFirstResponder];
    }
    else if (textField == self.verifyCode)
        [textField resignFirstResponder];
    else
        NSAssert(NO, @"here");
    
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [GlobalDataStorage setTdbss:nil];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    BOOL isOn = [ud boolForKey:REMEMEBR_PROFILE_STATE_STOREAGE_KEY];
    [self.rememberProfile setOn:isOn];
    if (isOn) {
        self.username.text = [SSKeychain passwordForService:KEYCHAIN_SERVICE account:KEYCHAIN_USERNAME_KEY];
        self.password.text = [SSKeychain passwordForService:KEYCHAIN_SERVICE account:KEYCHAIN_PASSWORD_KEY];
    }
    
    WeakSelf(wself, self);
    [self retriveLoginPassTokenUsingGCD];
    double delayInSeconds = 2.f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [wself retriveVerifyImageUsingGCD];
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (IBAction)iWantCancle:(id)sender {
    [SVProgressHUD dismiss];
    [[[TDBHTTPClient sharedClient] operationQueue] cancelAllOperations];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)iWantLogin:(id)sender {
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
    [self.verifyCode resignFirstResponder];
    
    if ([self.username.text length] && [self.password.text length] && [self.verifyCode.text length]) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        
        NSString *username = [self.username.text copy];
        NSString *password = [self.password.text copy];
        NSString *verifyCode = [self.verifyCode.text copy];
        
        dispatch_queue_t downloadQueue = dispatch_queue_create("12306 Login", NULL);
        dispatch_async(downloadQueue, ^{
            LOGIN_MSG_TYPE result = [self.tdbss loginWithName:username AndPassword:password
                                                andVerifyCode:verifyCode
                                                      tokenKey:self.tokenKey tokenValue:self.tokenValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result == LOGIN_MSG_SUCCESS) {
                    GlobalDataStorage.tdbss = self.tdbss;
                    
                    if (self.rememberProfile.isOn) {
                        [SSKeychain setPassword:username forService:KEYCHAIN_SERVICE account:KEYCHAIN_USERNAME_KEY];
                        [SSKeychain setPassword:password forService:KEYCHAIN_SERVICE account:KEYCHAIN_PASSWORD_KEY];
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:NULL];
                } else {
                    float latency;
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.removeFromSuperViewOnHide = YES;
                    if (result == LOGIN_MSG_OUTOFSERVICE) {
                        hud.labelText = @"系统维护中";
                        hud.detailsLabelText = @"每日23点-7点是维护时间";
                        latency = 3;
                    } else {
                        hud.labelText = @"登录失败";
                        hud.detailsLabelText = @"请检查";
                        latency = 2;
                    }
                    self.navigationItem.rightBarButtonItem = sender;
                    
                    
                    [hud hide:YES afterDelay:latency];
                    
                    [self iWantToRetriveVerifyCode:sender];
                }
            });
        });
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"请认真填写各个字段";
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:2];
    }
}

- (IBAction)switcherClicked:(id)sender {
    BOOL isOn = [sender isOn];
    if (isOn == NO) {
        [SSKeychain deletePasswordForService:KEYCHAIN_SERVICE account:KEYCHAIN_USERNAME_KEY];
        [SSKeychain deletePasswordForService:KEYCHAIN_SERVICE account:KEYCHAIN_PASSWORD_KEY];
        [SVProgressHUD showSuccessWithStatus:@"保存的用户名密码已被清除"];
    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:isOn forKey:REMEMEBR_PROFILE_STATE_STOREAGE_KEY];
}

- (void)retriveVerifyImageUsingGCD
{
    WeakSelf(wself, self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [[TDBHTTPClient sharedClient] getVerifyImage:^(NSData *imageRawData) {
            NSData *parsedData = imageRawData;
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIImage *image = [UIImage imageWithData:parsedData];
                
                StrongSelf(sself, wself);
                if (sself) {
                    sself.verifyImage.image = image;
                    sself.verifyCode.text = @"";
                }
            });
        }];
    });
}

- (void)retriveLoginPassTokenUsingGCD
{
    WeakSelfDefine(wself);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [NSThread sleepForTimeInterval:1.f];
        CHECK_INSTANCE_EXIST(wself);
        
        [[TDBHTTPClient sharedClient] getLoginToken:^(NSData *data) {
            NSString *rawJs = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *key = nil;
            @try {
                NSRange range = [rawJs rangeOfString:@"var key='"];
                rawJs = [rawJs substringFromIndex:range.location + range.length];
                range = [rawJs rangeOfString:@"';"];
                key = [rawJs substringToIndex:range.location];
            }
            @catch (NSException *exception) {
                NSLog(@"[loginToken] fetchFail");
            }
            
            CHECK_INSTANCE_EXIST(wself);
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIWebView *jsEngine = [[UIWebView alloc] initWithFrame:CGRectZero];
                NSString *filePath = [[NSBundle mainBundle] pathForResource:@"login_encode" ofType:@"js"];
                NSString *loginJS = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                [jsEngine stringByEvaluatingJavaScriptFromString:loginJS];
                
                NSString *command = [NSString stringWithFormat:@"encode64(bin216(Base32.encrypt('1111', '%@')))", key];
                
                StrongSelf(sself, wself);
                if (sself) {
                    sself.tokenValue = [jsEngine stringByEvaluatingJavaScriptFromString:command];
                    sself.tokenKey = key;
                    NSLog(@"[loginToken] %@: %@", sself.tokenKey, sself.tokenValue);
                }
            });
        }];
    });
}

- (IBAction)iWantToRetriveVerifyCode:(id)sender {
    [self retriveVerifyImageUsingGCD];
}

- (IBAction)iWantResetSession:(id)sender {
    //[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.tdbss = [[TDBSession alloc] init];
    [self iWantToRetriveVerifyCode:sender];
    [self retriveLoginPassTokenUsingGCD];
}
- (void)viewDidUnload {
    [self setRememberProfile:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    NSLog(@"dealloc %@", [self class]);
}
@end
