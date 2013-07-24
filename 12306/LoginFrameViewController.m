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

@interface LoginFrameViewController ()

@property (nonatomic, strong) TDBSession *tdbss;

@end

@implementation LoginFrameViewController

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
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 verify", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        NSData *imageRawData = [self.tdbss getVerifyImage];
        NSData *parsedData = imageRawData;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            UIImage *image = [UIImage imageWithData:parsedData];
            self.verifyImage.image = image;
        });
    });

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (IBAction)iWantCancle:(id)sender {
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
            LOGIN_MSG_TYPE result = [self.tdbss loginWithName:username AndPassword:password andVerifyCode:verifyCode];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result == LOGIN_MSG_SUCCESS) {
                    GlobalDataStorage.tdbss = self.tdbss;
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

- (IBAction)iWantToRetriveVerifyCode:(id)sender {
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 verify", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        NSData *imageRawData = [self.tdbss getVerifyImage];
        NSData *parsedData = imageRawData;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            UIImage *image = [UIImage imageWithData:parsedData];
            self.verifyImage.image = image;
            self.verifyCode.text = @"";
        });
    });

}

- (IBAction)iWantResetSession:(id)sender {
    //[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.tdbss = [[TDBSession alloc] init];
    [self iWantToRetriveVerifyCode:sender];
}
@end
