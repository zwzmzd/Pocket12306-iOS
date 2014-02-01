//
//  TDBOrderListViewController.h
//  12306
//
//  Created by macbook on 13-7-28.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ORDER_PARSER_MSG_ERR = 0,
    ORDER_PARSER_MSG_SUCCESS
} ORDER_PARSER_MSG;

@interface TDBOrderListViewController : UITableViewController

@property (nonatomic, assign) BOOL delayBeforeRefresh;

- (IBAction)iWantReturn:(id)sender;

- (void)forceRefreshOrderList;

@end
