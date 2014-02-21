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
#import "NSMutableArray_Shuffling.h"

#define SP_LIBSPOTIFY_DEBUG_LOGGING 1

#include "appkey.c"

@interface ASDAppDelegate ()
@property (strong, nonatomic) SPPlaybackManager *playbackManager;
@property (readwrite, strong, nonatomic) SPTrack *currentTrack;
@property (readwrite, assign, nonatomic) NSTimeInterval trackPosition;
@property (readwrite, assign, nonatomic) BOOL isPlaying;
@property (strong, nonatomic) SPPlaylist *currentPlaylist;
@property (strong, nonatomic) NSMutableArray *playlistTrackQueue;
@property (assign, nonatomic) int playlistTrackQueueIndex;
@end

@implementation ASDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.isPlaying = NO;
    
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
    
    // initialize playbackManager
    self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
    
    // initialize main view
    self.mainViewController = [[ASDMainViewController alloc] init];
    self.mainViewController.playbackManager = self;
    self.window.rootViewController = self.mainViewController;
    
    [self addObserver:self forKeyPath:@"playbackManager.trackPosition" options:0 context:nil];
    [self addObserver:self forKeyPath:@"playbackManager.currentTrack" options:0 context:nil];
    [self addObserver:self forKeyPath:@"playbackManager.isPlaying" options:0 context:nil];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    // login
    [self performSelector:@selector(attemptLogin) withObject:nil afterDelay:0.0];
    
    return YES;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    NSMutableDictionary *songInfo;
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            if ([self isPlaying])
                [self pausePlayback];
            else
                [self resumePlayback];
            break;
        case UIEventSubtypeRemoteControlPause:
            [self pausePlayback];
            songInfo = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
            [songInfo setObject:[NSNumber numberWithDouble:0.01] forKey:MPNowPlayingInfoPropertyPlaybackRate];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
            break;
        case UIEventSubtypeRemoteControlPlay:
            [self resumePlayback];
            songInfo = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
            [songInfo setObject:[NSNumber numberWithDouble:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            [self nextTrack];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self prevTrack];
            break;
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"playbackManager.trackPosition"]) {
        self.trackPosition = self.playbackManager.trackPosition;
    }
    else if ([keyPath isEqualToString:@"playbackManager.currentTrack"]) {
        // current track has ended... play the next track
        if (self.playbackManager.currentTrack == nil) {
            [self nextTrack];
        }
    }
    else if ([keyPath isEqualToString:@"playbackManager.isPlaying"]) {
        self.isPlaying = [self.playbackManager isPlaying];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
                        Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
                        if (playingInfoCenter) {
                            NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
                            [songInfo setObject:track.name forKey:MPMediaItemPropertyTitle];
                            [songInfo setObject:track.album.name forKey:MPMediaItemPropertyAlbumTitle];
                            [songInfo setObject:[NSNumber numberWithDouble:track.duration] forKey:MPMediaItemPropertyPlaybackDuration];
                            [songInfo setObject:[NSNumber numberWithDouble:self.playbackManager.trackPosition] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                            [songInfo setObject:[NSNumber numberWithDouble:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
                        }
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
        self.playlistTrackQueue = [NSMutableArray arrayWithArray:[playlist items]];
        [self.playlistTrackQueue shuffle];
        self.playlistTrackQueueIndex = 0;
        SPPlaylistItem *item = [self.playlistTrackQueue objectAtIndex:0];
        [self playTrack:[item itemURL]];
    }];
}

- (void)nextTrack {
    if (self.currentPlaylist != nil && self.playlistTrackQueue != nil
        && self.playlistTrackQueueIndex < [self.playlistTrackQueue count]) {
        self.playlistTrackQueueIndex++;
        SPPlaylistItem *item = [self.playlistTrackQueue objectAtIndex:self.playlistTrackQueueIndex];
        [self playTrack:[item itemURL]];
    }
}

- (void)prevTrack {
    if (self.currentPlaylist != nil && self.playlistTrackQueue != nil
        && self.playlistTrackQueueIndex > 0 && [self.playlistTrackQueue count] > 0) {
        self.playlistTrackQueueIndex--;
        SPPlaylistItem *item = [self.playlistTrackQueue objectAtIndex:self.playlistTrackQueueIndex];
        [self playTrack:[item itemURL]];
    }
}

- (void)pausePlayback {
    [self.playbackManager setIsPlaying:NO];
}

- (void)resumePlayback {
    [self.playbackManager setIsPlaying:YES];
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
