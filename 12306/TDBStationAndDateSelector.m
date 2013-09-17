//
//  TDBStationAndDateSelector.m
//  12306
//
//  Created by macbook on 13-7-24.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBStationAndDateSelector.h"
#import "GlobalDataStorage.h"
#import "CKCalendarView.h"
#import "TDBDatePickerView.h"

@interface TDBStationAndDateSelector() <CKCalendarDelegate>

@property (nonatomic, strong) TDBDatePickerView *pickerView;

@end

@implementation TDBStationAndDateSelector

@synthesize userSelectedDate = _userSelectedDate;

- (UITextField *)departStationField
{
    if (_departStationField == nil) {
        _departStationField = [[UITextField alloc] init];
        _departStationField.returnKeyType = UIReturnKeyDone;
        _departStationField.autocorrectionType = UITextAutocorrectionTypeNo;
        _departStationField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _departStationField.borderStyle = UITextBorderStyleNone;
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
        _arriveStationField.borderStyle = UITextBorderStyleNone;
        _arriveStationField.font = [UIFont boldSystemFontOfSize:18];
        _arriveStationField.adjustsFontSizeToFitWidth = YES;
        _arriveStationField.minimumFontSize = 6;
        
        _arriveStationField.placeholder = @"终点站";
        [self addSubview:_arriveStationField];
    }
    return _arriveStationField;
}

- (UISwitch *)stationNameExactlyMatch
{
    if (_stationNameExactlyMatch == nil) {
        _stationNameExactlyMatch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self addSubview:_stationNameExactlyMatch];
    }
    return _stationNameExactlyMatch;
}

- (UIButton *)dateShower
{
    if (_dateShower == nil) {
        _dateShower = [[UIButton alloc] init];
        [_dateShower addTarget:self action:@selector(showDatepicker:) forControlEvents:UIControlEventTouchDown];
        [_dateShower setTitleColor:[UIColor purpleColor] forState:UIControlStateNormal];
        [_dateShower.titleLabel setAdjustsFontSizeToFitWidth:YES];
        
        [self addSubview:_dateShower];
    }
    return _dateShower;
}

- (TDBDatePickerView *)pickerView
{
    if (_pickerView == nil) {
        _pickerView = [[TDBDatePickerView alloc] initWithFrame:CGRectZero];
        _pickerView.delegate = self;
    }
    return _pickerView;
}


- (void)setUserSelectedDate:(NSDate *)userSelectedDate
{
    _userSelectedDate = userSelectedDate;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yy-MM-dd"];
    NSString *dateInString = [formatter stringFromDate:userSelectedDate];
    
    float width = self.dateShower.frame.size.width;
    if (width > 120.f) {
        NSString *title = [NSString stringWithFormat:@"乘车日期 %@", dateInString];
        [self.dateShower setTitle:title forState:UIControlStateNormal];
    } else {
        NSString *title = [NSString stringWithFormat:@"%@", dateInString];
        [self.dateShower setTitle:title forState:UIControlStateNormal];
    }
}

- (NSDate *)userSelectedDate
{
    if (_userSelectedDate == nil) {
        _userSelectedDate = [NSDate date];
    }
    return _userSelectedDate;
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
    
    CGSize switchSize = self.stationNameExactlyMatch.frame.size;
    self.stationNameExactlyMatch.frame = CGRectMake(size.width - 10.f - switchSize.width, size.height - 40.f - switchSize.height, switchSize.width, switchSize.height);
    
    // 将子view填充整个view，这样就能点击后消失
    self.pickerView.frame = self.bounds;
    [self.pickerView setAnchor:CGPointMake(size.width, size.height - 35.f)];
    
    /* 用于更新self.dateShower的显示和布局 */
    self.userSelectedDate = self.userSelectedDate;
}

#pragma mark - Event Handler

- (IBAction)showDatepicker:(id)sender
{
    [self.departStationField resignFirstResponder];
    [self.arriveStationField resignFirstResponder];
    
    [self addSubview:self.pickerView];
    
}

#pragma mark -  CKCalendarDelegate

- (void)calendar:(CKCalendarView *)calendar didSelectDate:(NSDate *)date
{
    if (date) {
        self.userSelectedDate = date;
        [self.pickerView removeFromSuperview];
    }
}

@end
