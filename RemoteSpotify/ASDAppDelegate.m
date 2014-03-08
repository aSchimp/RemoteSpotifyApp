//
//  ASDAppDelegate.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/3/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import "ASDAppDelegate.h"
#import "RFduinoManager.h"

#define SP_LIBSPOTIFY_DEBUG_LOGGING 1

// add your own appkey.c file!!!
#include "appkey.c"

@implementation ASDAppDelegate
{
    RFduinoManager *rfduinoManager;
    bool wasScanning;
    ASDPlaybackManager *playbackManager;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // initialize spotify session w/ app key, etc.
    NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes: &g_appkey length: g_appkey_size] userAgent:@"com.alexsoftwaredevelopment.RemoteSpotify" loadingPolicy:SPAsyncLoadingManual error:&error];
    [[SPSession sharedSession] setDelegate:self];
    
    if (error != nil) {
        NSLog(@"CocoaLibSpotify init failed: %@", error);
    }

    // rfduino
    rfduinoManager = RFduinoManager.sharedRFduinoManager;
    
    // initialize playbackManager
    playbackManager = [[ASDPlaybackManager alloc] init];

    // initialize main view
    self.mainViewController = [[ASDMainViewController alloc] init];
    self.mainViewController.playbackManager = playbackManager;

    // initialize nav controller
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    [self.window setRootViewController:navController];
    navController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    
    // register for remote control events
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    // login to spotify
    [self performSelector:@selector(attemptLogin) withObject:nil afterDelay:0.0];
    
    return YES;
}

// this is necessary in order to become the first responder to remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    NSMutableDictionary *songInfo;
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            if ([playbackManager isPlaying])
                [playbackManager pausePlayback];
            else
                [playbackManager resumePlayback];
            break;
        case UIEventSubtypeRemoteControlPause:
            [playbackManager pausePlayback];
            songInfo = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
            [songInfo setObject:[NSNumber numberWithDouble:0.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
            [songInfo setObject:[NSNumber numberWithDouble:playbackManager.trackPosition] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
            break;
        case UIEventSubtypeRemoteControlPlay:
            [playbackManager resumePlayback];
            songInfo = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
            [songInfo setObject:[NSNumber numberWithDouble:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
            [songInfo setObject:[NSNumber numberWithDouble:playbackManager.trackPosition] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            [playbackManager nextTrack];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            [playbackManager prevTrack];
            break;
        default:
            break;
    }
}

- (void) attemptLogin
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *storedCredentials = [defaults valueForKey:@"SpotifyUsers"];
    
    if (storedCredentials == nil) {
        [self showLogin];
    }
    else {
        NSString *userName = [storedCredentials objectForKey:@"LastUser"];
        [[SPSession sharedSession] attemptLoginWithUserName:userName existingCredential:[storedCredentials objectForKey:userName]];
    }
}

- (void)showLogin
{
    NSLog(@"Entered showLogin method");
    SPLoginViewController *controller = [SPLoginViewController loginControllerForSession:[SPSession sharedSession]];
    controller.allowsCancel = NO;
    
    [self.mainViewController presentViewController:controller animated:YES completion:nil];
}

- (void)session:(SPSession *)aSession didGenerateLoginCredentials:(NSString *)credential forUserName:(NSString *)userName {
    NSLog(@"Stored Spotify Credentials");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *storedCredentials = [[defaults valueForKey:@"SpotifyUsers"] mutableCopy];
    
    if (storedCredentials == nil)
        storedCredentials = [NSMutableDictionary dictionary];
    
    [storedCredentials setValue:credential forKey:userName];
    [storedCredentials setValue:userName forKey:@"LastUser"];
    [defaults setValue:storedCredentials forKey:@"SpotifyUsers"];
    [defaults synchronize];
}

- (void)sessionDidLoginSuccessfully:(SPSession *)aSession {
    // wait until session info is loaded, then refresh the main view
    [SPAsyncLoading waitUntilLoaded:aSession timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
        [self.mainViewController refreshView];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    wasScanning = false;

    if (rfduinoManager.isScanning) {
        wasScanning = true;
        [rfduinoManager stopScan];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    __block UIBackgroundTaskIdentifier identifier = [application beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }];
    
    [[SPSession sharedSession] flushCaches:^{
        if (identifier != UIBackgroundTaskInvalid)
            [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    if (wasScanning) {
        [rfduinoManager startScan];
        wasScanning = false;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //[[SPSession sharedSession] logout: ^{}];
}

- (void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error {
    if (SP_LIBSPOTIFY_DEBUG_LOGGING != 0)
        NSLog(@"CocoaLS NETWORK ERROR: %@", error);
}

- (void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage {
    if (SP_LIBSPOTIFY_DEBUG_LOGGING != 0)
        NSLog(@"CocoaLS DEBUG: %@", aMessage);
}

@end
