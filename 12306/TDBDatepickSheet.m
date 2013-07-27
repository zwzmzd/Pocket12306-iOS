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

- (void)setInitialDate:(NSDate *)initialDate
{
    _initialDate = initialDate;
    self.pickView.date = _initialDate;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

@end
