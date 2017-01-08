//
//  TDBSession.m
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBSession.h"
#import "DataSerializeUtility.h"
#import "TDBTrainInfo.h"
#import "PassengerInfo.h"

#define ADD_UA() \
    [request setValue:USER_AGENT_STR forHTTPHeaderField:@"User-Agent"]

@interface TDBSession()

@property (nonatomic, strong) NSHTTPCookieStorage *cookieManager;
@property (nonatomic) BOOL isLoggedIn;

@end

@implementation TDBSession

+ (void)resetSession
{
    NSHTTPCookieStorage *cookieMgr = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSURL *url = [NSURL URLWithString:SYSURL @"/otn/"];
    NSArray *cookies = [cookieMgr cookiesForURL:url];
    NSEnumerator *enumerator = [cookies objectEnumerator];
    NSHTTPCookie *cookie;
    while (cookie = [enumerator nextObject]) {
        //NSLog(@"Del Cookie{%@ %@}", cookie.name, cookie.value);
        [cookieMgr deleteCookie:cookie];
    }
    NSLog(@"session reseted");
}

- (id)init
{
    self = [super init];
    if (self){
        _cookieManager = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        _isLoggedIn = NO;
    }
    
    return self;
}

- (void)restartSession
{
}

- (void)assertLoggedIn
{
    NSAssert(YES, @"Before This Operation, You must Login");
}


@end
