//
//  UIButton+TDBAddition.m
//  12306
//
//  Created by Wenzhe Zhou on 13-8-22.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "UIButton+TDBAddition.h"

@implementation UIButton (TDBAddition)

+ (UIButton *)arrowBackButtonWithSelector:(SEL)selector target:(id)target
{
    UIImage *backButtonImageForNormalState  = [UIImage imageNamed:@"header_leftbtn_nor"];
    UIImage *backButtonImageForHighlightedState = [UIImage imageNamed:@"header_leftbtn_press"];
    
    UIButton *button = [[UIButton alloc] init];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    
    [button setBackgroundImage:backButtonImageForNormalState forState:UIControlStateNormal];
    [button setBackgroundImage:backButtonImageForHighlightedState forState:UIControlStateHighlighted];
    button.frame = CGRectMake(0.f, 0.f, backButtonImageForNormalState.size.width, backButtonImageForHighlightedState.size.height);
    return button;
}

@end
