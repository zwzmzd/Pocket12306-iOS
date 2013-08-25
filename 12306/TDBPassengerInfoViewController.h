//
//  TDBPassengerInfoViewController.h
//  12306
//
//  Created by Wenzhe Zhou on 13-8-25.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PassengerSelectorDelegate;
@interface TDBPassengerInfoViewController : UITableViewController

@property (nonatomic, weak) id<PassengerSelectorDelegate> delegate;

- (IBAction)retrivePassengerList:(UIBarButtonItem *)sender;

@end

@protocol PassengerSelectorDelegate <NSObject>

@required
- (void)didSelectPassenger:(NSArray *)passengerInfoList;

@end
