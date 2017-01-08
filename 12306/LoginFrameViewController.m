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
#import "TDBHTTPClient.h"
#import "OLImageView.h"
#import "OLImage.h"
#import "SAMKeychain.h"

#define KEYCHAIN_SERVICE (@"12306_account")
#define KEYCHAIN_USERNAME_KEY (@"12306_account_username")
#define KEYCHAIN_PASSWORD_KEY (@"12306_account_password")
#define REMEMEBR_PROFILE_STATE_STOREAGE_KEY (@"rememberProfile_state")

@interface LoginFrameViewController ()

@property (nonatomic, strong) TDBSession *tdbss;

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
    else if (textField == self.password)
        [textField resignFirstResponder];
    else
        NSAssert(NO, @"here");
    
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [TDBSession resetSession];
    [GlobalDataStorage setTdbss:nil];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    BOOL isOn = [ud boolForKey:REMEMEBR_PROFILE_STATE_STOREAGE_KEY];
    [self.rememberProfile setOn:isOn];
    if (isOn) {
        self.username.text = [SAMKeychain passwordForService:KEYCHAIN_SERVICE account:KEYCHAIN_USERNAME_KEY];
        self.password.text = [SAMKeychain passwordForService:KEYCHAIN_SERVICE account:KEYCHAIN_PASSWORD_KEY];
    }
    
    WeakSelf(wself, self);
    
    [self.retriveVerifyActivityIndicator startAnimating];
    double delayInSeconds = 1.f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [wself retriveVerifyImageUsingGCD];
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    MobClickBeginLogPageView();
}

- (void)viewWillDisappear:(BOOL)animated {
    MobClickEndLogPageView();
    [super viewWillDisappear:animated];
}

- (IBAction)iWantCancle:(id)sender {
    [SVProgressHUD dismiss];
    [[[TDBHTTPClient sharedClient] operationQueue] cancelAllOperations];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)iWantLogin:(id)sender {
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
    
    if ([self.username.text length] && [self.password.text length]) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        
        NSString *username = [self.username.text copy];
        NSString *password = [self.password.text copy];
        NSString *verifyCode = @"";
        
        [[TDBHTTPClient sharedClient] loginWithName:username AndPassword:password andVerifyCode:verifyCode success:^(NSDictionary *result) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                BOOL loginSucceed = result && [[[result objectForKey:@"data"] objectForKey:@"loginCheck"] isEqualToString:@"Y"];
                if (loginSucceed) {
                    GlobalDataStorage.tdbss = self.tdbss;
                    
                    if (self.rememberProfile.isOn) {
                        [SAMKeychain setPassword:username forService:KEYCHAIN_SERVICE account:KEYCHAIN_USERNAME_KEY];
                        [SAMKeychain setPassword:password forService:KEYCHAIN_SERVICE account:KEYCHAIN_PASSWORD_KEY];
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:NULL];
                } else {
                    NSString *message = nil;
                    if (result) {
                        NSArray *list = [result objectForKey:@"messages"];
                        if ([list count] > 0) {
                            message = [list objectAtIndex:0];
                        }
                    }
                    
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.removeFromSuperViewOnHide = YES;
                    if (message != nil) {
                        hud.label.text = @"登录失败";
                        hud.detailsLabel.text = message;
                    }
                    self.navigationItem.rightBarButtonItem = sender;
                    
                    [hud hideAnimated:YES afterDelay:2];
                    [self iWantToRetriveVerifyCode:sender];
                }
            });
        }];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"请认真填写各个字段";
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:2];
    }
}

- (IBAction)switcherClicked:(id)sender {
    BOOL isOn = [sender isOn];
    if (isOn == NO) {
        [SAMKeychain deletePasswordForService:KEYCHAIN_SERVICE account:KEYCHAIN_USERNAME_KEY];
        [SAMKeychain deletePasswordForService:KEYCHAIN_SERVICE account:KEYCHAIN_PASSWORD_KEY];
        [SVProgressHUD showSuccessWithStatus:@"保存的用户名密码已被清除"];
    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:isOn forKey:REMEMEBR_PROFILE_STATE_STOREAGE_KEY];
}

- (void)retriveVerifyImageUsingGCD
{
    [self.retriveVerifyActivityIndicator startAnimating];
    WeakSelf(wself, self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [[TDBHTTPClient sharedClient] getVerifyImage:^(NSData *imageRawData) {
            NSData *parsedData = imageRawData;
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIImage *image = [OLImage imageWithData:parsedData];
                StrongSelf(sself, wself);
                if (sself) {
                    sself.imageView.image = image;
                    [sself.retriveVerifyActivityIndicator stopAnimating];
                }
            });
        }];
    });
}

- (IBAction)iWantToRetriveVerifyCode:(id)sender {
    [[TDBHTTPClient sharedClient] cancelAllHTTPRequest];
    [self retriveVerifyImageUsingGCD];
}

- (IBAction)iWantResetSession:(id)sender {
    //[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.tdbss = [[TDBSession alloc] init];
    [self iWantToRetriveVerifyCode:sender];
}
- (void)viewDidUnload {
    [self setRememberProfile:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    NSLog(@"dealloc %@", [self class]);
}
@end
