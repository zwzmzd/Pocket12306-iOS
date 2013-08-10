//
//  TDBTrainTimetableCell.h
//  12306
//
//  Created by macbook on 13-8-10.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDBTrainTimetableCell : UITableViewCell

@property (nonatomic) NSString *station_no;
@property (nonatomic) NSString *station_name;
@property (nonatomic) NSString *arrive_time;
@property (nonatomic) NSString *start_time;
@property (nonatomic) NSString *stopover_time;
@property (nonatomic) BOOL is_enabled;

+ (CGFloat)heightForCell;

@end


@interface TDBTrainTimetableSection : UIView

+ (CGFloat)heightForSection;

@end
