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
        _departStationField.returnKeyType = UIReturnKeyDone;
        _departStationField.autocorrectionType = UITextAutocorrectionTypeNo;
        _departStationField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _departStationField.borderStyle = UITextBorderStyleBezel;
        _departStationField.font = [UIFont boldSystemFontOfSize:22];
        
        _departStationField.placeholder = @"起点站";
        [self addSubview:_departStationField];
    }
    return _departStationField;
}

- (UITextField *)arriveStationField
{
    if (_arriveStationField == nil) {
        _arriveStationField = [[UITextField alloc] init];
        _arriveStationField.returnKeyType = UIReturnKeyDone;
        _arriveStationField.autocorrectionType = UITextAutocorrectionTypeNo;
        _arriveStationField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _arriveStationField.borderStyle = UITextBorderStyleBezel;
        _arriveStationField.font = [UIFont boldSystemFontOfSize:22];
        
        _arriveStationField.placeholder = @"终点站";
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
    
    self.departStationField.frame = CGRectMake(0.025f * size.width, size.height - 45, 0.4f * size.width, 35.f);
    self.arriveStationField.frame = CGRectMake(0.45f * size.width, size.height - 45, 0.4f * size.width, 35.f);
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
