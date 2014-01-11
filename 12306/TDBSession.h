//
//  TDBSession.h
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDBTrainInfo;
@class PassengerInfo;

typedef enum {
    LOGIN_MSG_SUCCESS = 0,
    LOGIN_MSG_USERNAME_ERR,
    LOGIN_MSG_PASSWORD_ERR,
    LOGIN_MSG_OUTOFSERVICE,
    LOGIN_MSG_UNEXPECTED
} LOGIN_MSG_TYPE;

@interface TDBSession : NSObject

+ (void)resetSession;
- (void)restartSession;

@end
