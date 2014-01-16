//
//  TDBAppDelegate.m
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBAppDelegate.h"
#import "TDBKeybordNotificationManager.h"
#import "MobClick.h"

@implementation TDBAppDelegate

- (void)_customGlobalUserInterface
{
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // 设置uiwebview的User-Agent
    NSDictionary *dictionary = [NSDictionary
                                dictionaryWithObjectsAndKeys:
                                @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0_2 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A400 Safari/6531.22.7",
                                @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:4 * 1024 * 1024
                                                             diskPath:@"AppCacheDir2013"];
    [NSURLCache setSharedURLCache:URLCache];
    //NSLog(@"%@", NSHomeDirectory());
    
    [[TDBKeybordNotificationManager getSharedManager] registerSelfToNotificationCenter];
    
    [self _customGlobalUserInterface];
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    }
    
    [MobClick startWithAppkey:@"526f924a56240b9043005378"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"Resign Active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"WillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"DidBecomeActive");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"WillTerminate");
}

@end
