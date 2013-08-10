//
//  TDBTrainTimetableCell.m
//  12306
//
//  Created by macbook on 13-8-10.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBTrainTimetableCell.h"

@implementation TDBTrainTimetableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:NO animated:animated];

    // Configure the view for the selected state
}

- (void)drawRect:(CGRect)rect
{
    UIFont *font;
    if (self.is_enabled) {
        [[UIColor blackColor] set];
        font = [UIFont boldSystemFontOfSize:15];
    } else {
        [[UIColor grayColor] set];
        font = [UIFont systemFontOfSize:15];
    }
    
    [self.station_no drawAtPoint:CGPointMake(10.f, 10.f) withFont:font];
    [self.station_name drawAtPoint:CGPointMake(50.f, 10.f) withFont:font];
    [self.arrive_time drawAtPoint:CGPointMake(130.f, 10.f) withFont:font];
    [self.start_time drawAtPoint:CGPointMake(190.f, 10.f) withFont:font];
    [self.stopover_time drawAtPoint:CGPointMake(260.f, 10.f) withFont:font];
}

+ (CGFloat)heightForCell
{
    return 40.f;
}

@end


@implementation TDBTrainTimetableSection

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor grayColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    UIFont *font = [UIFont boldSystemFontOfSize:13];
    [[UIColor whiteColor] set];
    [@"序号" drawAtPoint:CGPointMake(10.f, 2.f) withFont:font];
    [@"车站名称" drawAtPoint:CGPointMake(50.f, 2.f) withFont:font];
    [@"到达时间" drawAtPoint:CGPointMake(130.f, 2.f) withFont:font];
    [@"开车时间" drawAtPoint:CGPointMake(190.f, 2.f) withFont:font];
    [@"停站时长" drawAtPoint:CGPointMake(260.f, 2.f) withFont:font];
}

+ (CGFloat)heightForSection
{
    return 20.f;
}

@end