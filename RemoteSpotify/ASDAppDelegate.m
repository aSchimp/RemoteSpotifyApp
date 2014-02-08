//
//  ASDAppDelegate.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/3/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import "ASDAppDelegate.h"
#import "ASDMainViewController.h"
#import "CocoaLibSpotify.h"

#include "appkey.c"

@implementation ASDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // initialize spotify session w/ app key, etc.
    NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes: &g_appkey length: g_appkey_size] userAgent:@"com.alexsoftwaredevelopment.TestEmptyApp" loadingPolicy:SPAsyncLoadingManual error:&error];
    
    if (error != nil) {
        NSLog(@"CocoaLibSpotify init failed: %@", error);
    }
    
    self.mainViewController = [[ASDMainViewController alloc] init];
    self.window.rootViewController = self.mainViewController;
    
    [self performSelector:@selector(showLogin) withObject:nil afterDelay:0.0];
    
    return YES;
}

- (void)showLogin
{
    NSLog(@"Entered showLogin method");
    SPLoginViewController *controller = [SPLoginViewController loginControllerForSession:[SPSession sharedSession]];
    controller.allowsCancel = NO;
    
    [self.mainViewController presentViewController:controller animated:YES completion:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[SPSession sharedSession] logout: ^{}];
}

@end
