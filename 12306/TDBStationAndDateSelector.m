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
        _departStationField.font = [UIFont boldSystemFontOfSize:18];
        _departStationField.adjustsFontSizeToFitWidth = YES;
        _departStationField.minimumFontSize = 6;
        
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
        _arriveStationField.font = [UIFont boldSystemFontOfSize:18];
        _arriveStationField.adjustsFontSizeToFitWidth = YES;
        _arriveStationField.minimumFontSize = 6;
        
        _arriveStationField.placeholder = @"终点站";
        [self addSubview:_arriveStationField];
    }
    return _arriveStationField;
}

- (UIButton *)dateShower
{
    if (_dateShower == nil) {
        _dateShower = [[UIButton alloc] init];
        [_dateShower addTarget:self action:@selector(showDatepicker:) forControlEvents:UIControlEventAllTouchEvents];
        [_dateShower setTitleColor:[UIColor purpleColor] forState:UIControlStateNormal];
        
        NSDate *today = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yy-MM-dd"];
        [_dateShower setTitle:[formatter stringFromDate:today] forState:UIControlStateNormal];
        
        [self addSubview:_dateShower];
    }
    return _dateShower;
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
    
    self.departStationField.frame = CGRectMake(0.025f * size.width, size.height - 35, 0.3f * size.width, 30.f);
    self.arriveStationField.frame = CGRectMake(0.35f * size.width, size.height - 35, 0.3f * size.width, 30.f);
    self.dateShower.frame = CGRectMake(0.675f * size.width, size.height - 35, 0.3f * size.width, 30.f);
}

- (IBAction)showDatepicker:(id)sender
{
    [self.departStationField resignFirstResponder];
    [self.arriveStationField resignFirstResponder];
}


@end
