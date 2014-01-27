//
//  TDBDateShower.m
//  12306
//
//  Created by Wenzhe Zhou on 14-1-17.
//  Copyright (c) 2014年 zwz. All rights reserved.
//

#import "TDBDateShower.h"
#import "CKCalendarView.h"
#import "TDBDatePickerView.h"
#import "TDBViewController.h"

@interface TDBDateShower() <CKCalendarDelegate>

@property (nonatomic, strong) TDBDatePickerView *pickerView;

@end

@implementation TDBDateShower

- (void)initialize {
    NSLog(@"init");
    [self addTarget:self action:@selector(datePressed:forEvent:) forControlEvents:UIControlEventTouchDown];
    [self setTitleColor:[UIColor purpleColor] forState:UIControlStateNormal];
    [self.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    self.orderDate = [NSDate date];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (TDBDatePickerView *)pickerView
{
    if (_pickerView == nil) {
        _pickerView = [[TDBDatePickerView alloc] initWithFrame:CGRectZero];
        _pickerView.delegate = self;
    }
    return _pickerView;
}

- (void)setOrderDate:(NSDate *)orderDate {
    if (_orderDate != orderDate) {
        _orderDate = orderDate;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yy-MM-dd"];
        NSString *dateInString = [formatter stringFromDate:orderDate];
        
        float width = self.frame.size.width;
        if (width > 120.f) {
            NSString *title = [NSString stringWithFormat:@"乘车日期 %@", dateInString];
            [self setTitle:title forState:UIControlStateNormal];
        } else {
            NSString *title = [NSString stringWithFormat:@"%@", dateInString];
            [self setTitle:title forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Event Handler

- (IBAction)datePressed:(id)sender forEvent:(UIEvent*)event {
    UIView *button = (UIView *)sender;
    
    [self.parentController.departStationField resignFirstResponder];
    [self.parentController.arriveStationField resignFirstResponder];
    
    CGRect frame = self.parentController.view.bounds;
    CGSize size = frame.size;
    frame.origin.y += self.parentController.tableView.contentInset.top;
    self.pickerView.frame = frame;
    
    if ( size.width > 400.f) {
        [self.pickerView setAnchor:CGPointMake(20.f, 5.f)];
    } else {
        CGPoint p = CGPointMake(0.f, button.frame.size.height);
        [self.pickerView setAnchor:[button convertPoint:p toView:self.parentController.view]];
    }
    [self.parentController.view addSubview:self.pickerView];
    [self.parentController.view bringSubviewToFront:self.pickerView];
}

#pragma mark -  CKCalendarDelegate

- (void)calendar:(CKCalendarView *)calendar didSelectDate:(NSDate *)date
{
    if (date) {
        self.orderDate = date;
        [self.pickerView removeFromSuperview];
    }
}

@end
