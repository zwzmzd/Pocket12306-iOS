//
//  TDBViewController.h
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBKeybordNotificationManager.h"
#import "TDBDateShower.h"

@interface TDBViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *departStationField;
@property (weak, nonatomic) IBOutlet UITextField *arriveStationField;
@property (weak, nonatomic) IBOutlet UISwitch *stationNameExactlyMatch;
@property (weak, nonatomic) IBOutlet UITableViewCell *dateSelectContainer;
@property (weak, nonatomic) IBOutlet TDBDateShower *dateShower;
- (IBAction)doQuery:(id)sender;

@end
