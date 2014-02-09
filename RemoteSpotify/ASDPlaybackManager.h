//
//  ASDPlaybackManager.h
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/8/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CocoaLibSpotify.h"

@protocol ASDPlaybackManager <NSObject>

@property (readonly, strong, nonatomic) SPTrack *currentTrack;
@property (readonly, assign, nonatomic) NSTimeInterval trackPosition;
@property (readonly, assign, nonatomic) BOOL isPlaying;

- (void)playTrack:(NSURL *)trackUrl;
- (void)updateTrackPosition:(NSTimeInterval) position;
- (void)playPlaylist:(SPPlaylist *)playlist;
- (void)pausePlayback;
- (void)resumePlayback;
- (void)nextTrack;
- (void)prevTrack;

@end
