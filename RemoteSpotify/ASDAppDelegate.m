//
//  ASDAppDelegate.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/3/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import "ASDAppDelegate.h"

#include "appkey.c"

@interface ASDAppDelegate ()
@property (strong, nonatomic) SPPlaybackManager *playbackManager;
@property (readwrite, strong, nonatomic) SPTrack *currentTrack;
@property (readwrite, assign, nonatomic) NSTimeInterval trackPosition;
@property (strong, nonatomic) SPPlaylist *currentPlaylist;
@end

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
    
    // initialize playbackManager
    self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
    
    // initialize main view
    self.mainViewController = [[ASDMainViewController alloc] init];
    self.mainViewController.playbackManager = self;
    self.window.rootViewController = self.mainViewController;
    
    [self addObserver:self forKeyPath:@"playbackManager.trackPosition" options:0 context:nil];
    
    // show login screen
    [self performSelector:@selector(showLogin) withObject:nil afterDelay:0.0];
    
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"playbackManager.trackPosition"]) {
        self.trackPosition = self.playbackManager.trackPosition;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)showLogin
{
    NSLog(@"Entered showLogin method");
    SPLoginViewController *controller = [SPLoginViewController loginControllerForSession:[SPSession sharedSession]];
    controller.allowsCancel = NO;
    controller.loginDelegate = self;
    
    [self.mainViewController presentViewController:controller animated:YES completion:nil];
}

- (void)playTrack:(NSURL *)trackUrl {
    [[SPSession sharedSession] trackForURL:trackUrl callback:^(SPTrack *track) {
        if (track != nil) {
            [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
                [self.playbackManager playTrack:track callback:^(NSError *error) {
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Play Track" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        
                        [alert show];
                    }
                    else {
                        self.currentTrack = track;
                    }
                }];
            }];
        }
    }];
}

- (void)updateTrackPosition:(NSTimeInterval) position {
    [self.playbackManager seekToTrackPosition:position];
}

- (void)playPlaylist:(SPPlaylist *)playlist {
    [SPAsyncLoading waitUntilLoaded:playlist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
        self.currentPlaylist = playlist;
        SPPlaylistItem *item = [playlist.items objectAtIndex:0];
        [self playTrack:[item itemURL]];
    }];
}

- (void)loginViewController:(SPLoginViewController *)controller didCompleteSuccessfully:(BOOL)didLogin {
    // called after Spotify login
    if (didLogin) {
        [self.mainViewController refreshView];
    }
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
