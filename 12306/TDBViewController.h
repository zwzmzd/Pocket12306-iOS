//
//  TDBViewController.h
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBKeybordNotificationManager.h"

@interface TDBViewController : UIViewController <UITextFieldDelegate, KeyboardNotificationDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buyTicket;
- (IBAction)cancleLogin:(UIStoryboard *)segue;

@end
