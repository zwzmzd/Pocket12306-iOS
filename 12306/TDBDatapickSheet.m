//
//  TDBDatapickSheet.m
//  12306
//
//  Created by macbook on 13-7-26.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBDatapickSheet.h"

@implementation TDBDatapickSheet

- (UIPickerView *)pickView
{
    if (_pickView == nil) {
        _pickView = [[UIPickerView alloc] init];
        _pickView.showsSelectionIndicator = YES;
        
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
