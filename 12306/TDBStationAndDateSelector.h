//
//  TDBStationAndDateSelector.h
//  12306
//
//  Created by macbook on 13-7-24.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDBStationAndDateSelector : UIView

@property (nonatomic) UIScrollView *autocompleteList;
@property (nonatomic) UITextField *departStationField;
@property (nonatomic) UITextField *arriveStationField;

- (id)initWithDelegate:(id<UITextFieldDelegate>)delegate;

@end
