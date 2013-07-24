//
//  TDBKeybordNotificationManager.m
//  12306
//
//  Created by macbook on 13-7-24.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBKeybordNotificationManager.h"

static TDBKeybordNotificationManager *_manager = nil;

@interface TDBKeybordNotificationManager()

@property (nonatomic) NSMutableArray *eventHandlerList;

@end

@implementation TDBKeybordNotificationManager

+ (TDBKeybordNotificationManager *)getSharedManager
{
    if (_manager == nil) {
        _manager = [[TDBKeybordNotificationManager alloc] init];
    }
    
    return _manager;
}

- (NSMutableArray *)eventHandlerList
{
    if (_eventHandlerList == nil) {
        _eventHandlerList = [[NSMutableArray alloc] init];
    }
    
    return _eventHandlerList;
}

- (id)init
{
    self = [super init];
    if (self) {
        _keyboardVisible = NO;
        _keyboardHeight = 0;
    }
    
    return self;
}

- (void)registerSelfToNotificationCenter
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(keyboardWillShowHandle:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHideHandle:) name:UIKeyboardWillHideNotification object:nil];

    /*
    [nc addObserverForName:UIKeyboardWillShowNotification object:nil queue:mainQueue
                usingBlock:^(NSNotification *note){
                    [self keyboardWillShowHandle:note];
                }];
    
    [nc addObserverForName:UIKeyboardWillHideNotification object:nil queue:mainQueue
                usingBlock:^(NSNotification *note){
                    [self keyboardWillHideHandle:note];
                }];
     */
}

#pragma mark - add or remove a delegate for event handler
- (void)addNotificationHandler:(id<KeyboardNotificationDelegate>)delegate
{
    if ([self.eventHandlerList indexOfObject:delegate] == NSNotFound)
        [self.eventHandlerList addObject:delegate];
    else
        NSLog(@"duplicate");
}

- (void)removeNotificationHandler:(id<KeyboardNotificationDelegate>)delegate
{
    [self.eventHandlerList removeObject:delegate];
}

#pragma mark - method for handling the keyboard notification

- (void)keyboardWillShowHandle:(NSNotification *)note
{
    //NSLog(@"keyboard appear or size changed");
    self.keyboardVisible = YES;
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
    NSValue *keyboardBoundsValue = [[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
#else
    NSValue *keyboardBoundsValue = [[note userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
#endif
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    self.keyboardHeight = keyboardBounds.size.height;
    
    for (id<KeyboardNotificationDelegate> handler in self.eventHandlerList) {
        [handler keyboardEvent:YES];
    }
}

- (void)keyboardWillHideHandle:(NSNotification *)note
{
    //NSLog(@"disappear");
    self.keyboardVisible = NO;
    self.keyboardHeight = 0;
    
    for (id<KeyboardNotificationDelegate> handler in self.eventHandlerList) {
        [handler keyboardEvent:NO];
    }
}

@end
