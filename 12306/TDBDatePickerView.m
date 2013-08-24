//
//  TDBDatePickerView.m
//  12306
//
//  Created by Wenzhe Zhou on 13-8-23.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBDatePickerView.h"

#define PADDING 15.f

@interface TDBDatePickerView()

@property (nonatomic, strong) CKCalendarView *ckView;

@end

@implementation TDBDatePickerView

- (CKCalendarView *)ckView
{
    if (_ckView == nil) {
        _ckView = [[CKCalendarView alloc] init];
        // width和height有一定相关性，无法随意设置
        _ckView.frame = CGRectMake(0.f, 0.f, 280.f, 261.f);
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
    CGSize size = self.ckView.frame.size;
    CGRect rect = CGRectMake(rightBottomAnchor.x - PADDING - size.width, rightBottomAnchor.y - PADDING - size.height, size.width, size.height);
    self.ckView.frame = rect;
}

-(IBAction)_tapped:(id)sender
{
    [self removeFromSuperview];
}

@end
