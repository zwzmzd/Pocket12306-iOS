//
//  TDBDateShower.h
//  12306
//
//  Created by Wenzhe Zhou on 14-1-17.
//  Copyright (c) 2014年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  TDBViewController;
@interface TDBDateShower : UIButton

@property (nonatomic, strong) NSDate *orderDate;
@property (nonatomic, weak) TDBViewController *parentController;

@end
