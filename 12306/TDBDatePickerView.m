//
//  TDBDatePickerView.m
//  12306
//
//  Created by Wenzhe Zhou on 13-8-23.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBDatePickerView.h"

#define PADDING 5.f

@interface TDBDatePickerView()

@property (nonatomic, strong) CKCalendarView *ckView;

@end

@implementation TDBDatePickerView

- (CKCalendarView *)ckView
{
    if (_ckView == nil) {
        _ckView = [[CKCalendarView alloc] init];
        _ckView.frame = CGRectMake(0.f, 0.f, 250.f, 150.f);
        [self addSubview:_ckView];
    }
    return _ckView;
}

- (void)setDelegate:(id<CKCalendarDelegate>)delegate
{
    self.ckView.delegate = delegate;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (void)_initialize
{
    UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapped:)];
    [self addGestureRecognizer:tapgr];
}

- (void)setAnchor:(CGPoint)rightBottomAnchor
{
    NSLog(@"%f %f", rightBottomAnchor.x, rightBottomAnchor.y);
    CGSize size = self.ckView.frame.size;
    CGRect rect = CGRectMake(rightBottomAnchor.x - PADDING - size.width, rightBottomAnchor.y - PADDING - size.height, size.width, size.height);
    NSLog(@"%f %f %f %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    self.ckView.frame = rect;
}

-(IBAction)_tapped:(id)sender
{
    [self removeFromSuperview];
}

@end
