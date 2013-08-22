//
//  TDBDatePickerView.h
//  12306
//
//  Created by Wenzhe Zhou on 13-8-23.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKCalendarView.h"

@interface TDBDatePickerView : UIView

@property (nonatomic, weak) id<CKCalendarDelegate> delegate;

@end
