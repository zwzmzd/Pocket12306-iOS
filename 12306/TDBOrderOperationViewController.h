//
//  TDBOrderOperationViewController.h
//  12306
//
//  Created by macbook on 13-8-4.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDBOrder;
@class TDBOrderListViewController;

@interface TDBOrderOperationViewController : UITableViewController
- (IBAction)iWantToRefresh:(id)sender;
- (IBAction)iWantToCancleOrder:(id)sender;

@property (nonatomic) NSString *apacheToken;
@property (nonatomic) TDBOrder *order;
@property (nonatomic, weak) TDBOrderListViewController *receiver;

@end
