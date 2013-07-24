//
//  TDBStationAndDateSelector.m
//  12306
//
//  Created by macbook on 13-7-24.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBStationAndDateSelector.h"

@implementation TDBStationAndDateSelector

- (UITextField *)departStationField
{
    if (_departStationField == nil) {
        _departStationField = [[UITextField alloc] init];
        _departStationField.placeholder = @"nihao";
        _arriveStationField.returnKeyType = UIReturnKeyDone;
        [self addSubview:_departStationField];
    }
    return _departStationField;
}

- (UITextField *)arriveStationField
{
    if (_arriveStationField == nil) {
        _arriveStationField = [[UITextField alloc] init];
        _arriveStationField.placeholder = @"hello";
        _arriveStationField.returnKeyType = UIReturnKeyDone;
        [self addSubview:_arriveStationField];
    }
    return _arriveStationField;
}

- (id)initWithDelegate:(id<UITextFieldDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.arriveStationField.delegate = delegate;
        self.departStationField.delegate = delegate;
    }
    
    return self;
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
    CGSize size = self.frame.size;
    //NSLog(@"%f, %f", size.width, size.height);
    self.departStationField.frame = CGRectMake(0.05125f * size.width, size.height - 40, 0.25f * size.width, 30.f);
    self.arriveStationField.frame = CGRectMake(0.375f * size.width, size.height - 40, 0.25f * size.width, 30.f);
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
