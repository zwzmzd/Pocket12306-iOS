//
//  TDBKeybordNotificationManager.h
//  12306
//
//  Created by macbook on 13-7-24.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KeyboardNotificationDelegate <NSObject>

- (void)keyboardEvent:(BOOL)visible;

@end

@interface TDBKeybordNotificationManager : NSObject

@property (nonatomic) BOOL keyboardVisible;
@property (nonatomic) float keyboardHeight;

+ (TDBKeybordNotificationManager *)getSharedManager;

- (void)registerSelfToNotificationCenter;
- (void)addNotificationHandler:(id<KeyboardNotificationDelegate>)delegate;
- (void)removeNotificationHandler:(id<KeyboardNotificationDelegate>)delegate;

@end
