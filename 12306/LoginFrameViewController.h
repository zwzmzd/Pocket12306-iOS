//
//  LoginFrameViewController.h
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginFrameViewController : UITableViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *verifyCode;
@property (weak, nonatomic) IBOutlet UIImageView *verifyImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *retriveVerifyCodeButton;
@property (weak, nonatomic) IBOutlet UISwitch *rememberProfile;

- (IBAction)iWantCancle:(id)sender;
- (IBAction)iWantLogin:(id)sender;
- (IBAction)switcherClicked:(id)sender;
- (IBAction)iWantToRetriveVerifyCode:(id)sender;
- (IBAction)iWantResetSession:(id)sender;

@end
