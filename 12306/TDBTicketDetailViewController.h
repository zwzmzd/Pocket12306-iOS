//
//  TDBTicketDetailViewController.h
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDBTrainInfo;

@interface TDBTicketDetailViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic) TDBTrainInfo *train;
@property (nonatomic) NSString *departDate;
@property (weak, nonatomic) IBOutlet UILabel *detailTopLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailDepartLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailArriveLabel;

@property (weak, nonatomic) IBOutlet UIImageView *verifyCodeImage;
@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *idCardNo;
@property (weak, nonatomic) IBOutlet UITextField *mobileno;
@property (weak, nonatomic) IBOutlet UISegmentedControl *seatTypeSelector;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ticketTypeSelector;
@property (weak, nonatomic) IBOutlet UIButton *refreshVerifyCodeBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

- (IBAction)iWantOrder:(id)sender;
- (IBAction)refreshVerifyCode:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *verifyCode;

@end
