//
//  TDBDatapickSheet.m
//  12306
//
//  Created by macbook on 13-7-26.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBDatepickSheet.h"

@implementation TDBDatepickSheet

- (UIDatePicker *)pickView
{
    if (_pickView == nil) {
        _pickView = [[UIDatePicker alloc] init];
        _pickView.datePickerMode = UIDatePickerModeDate;
        _pickView.minimumDate = [NSDate date];
        
        [self addSubview:_pickView];
    }
    return _pickView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    CGSize size = self.bounds.size;
    
    if (size.width > 340.f) {
        /* 横屏模式下 */
        self.pickView.frame = CGRectMake(0.f, -10.f, size.width, 100.f);
    } else {
        /* 竖屏模式下 */
        self.pickView.frame = CGRectMake(0.f, 0.f, size.width, 200.f);
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
