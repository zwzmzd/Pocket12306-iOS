//
//  TDBListViewController.h
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDBTrainInfoController;

@interface TDBListViewController : UITableViewController

@property (nonatomic) NSString *departStationTelecode;
@property (nonatomic) NSString *arriveStationTelecode;
@property (nonatomic) NSDate *orderDate;

@end
