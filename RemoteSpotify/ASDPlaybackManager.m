//
//  ASDPlaybackManager.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 3/8/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import "ASDPlaybackManager.h"
#import "NSMutableArray_Shuffling.h"

@interface ASDPlaybackManager ()
{
    SPPlaybackManager *spPlaybackManager;
    SPPlaylist *currentPlaylist;
    NSMutableArray *playlistTrackQueue;
    int playlistTrackQueueIndex;
}

@property (readwrite, strong, nonatomic) SPTrack *currentTrack;
@property (readwrite, assign, nonatomic) NSTimeInterval trackPosition;
@property (readwrite, assign, nonatomic) BOOL isPlaying;

@end

@implementation ASDPlaybackManager

- (id)init
{
    self = [super init];
    if (self)
    {
        self.isPlaying = NO;
        
        // initialize spPlaybackManager
        spPlaybackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
        
        [self addObserver:self forKeyPath:@"spPlaybackManager.trackPosition" options:0 context:nil];
        [self addObserver:self forKeyPath:@"spPlaybackManager.currentTrack" options:0 context:nil];
        [self addObserver:self forKeyPath:@"spPlaybackManager.isPlaying" options:0 context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"spPlaybackManager.trackPosition"]) {
        self.trackPosition = spPlaybackManager.trackPosition;
    }
    else if ([keyPath isEqualToString:@"spPlaybackManager.currentTrack"]) {
        // current track has ended... play the next track
        if (spPlaybackManager.currentTrack == nil) {
            [self nextTrack];
        }
    }
    else if ([keyPath isEqualToString:@"spPlaybackManager.isPlaying"]) {
        self.isPlaying = [spPlaybackManager isPlaying];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)playTrack:(NSURL *)trackUrl {
    [[SPSession sharedSession] trackForURL:trackUrl callback:^(SPTrack *track) {
        if (track != nil) {
            [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
                [spPlaybackManager playTrack:track callback:^(NSError *error) {
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Play Track" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        
                        [alert show];
                    }
                    else {
                        self.currentTrack = track;
                        
                        // set the "now playing" info if that feature is available
                        Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
                        if (playingInfoCenter) {
                            NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
                            [songInfo setObject:track.name forKey:MPMediaItemPropertyTitle];
                            [songInfo setObject:track.album.name forKey:MPMediaItemPropertyAlbumTitle];
                            [songInfo setObject:[NSNumber numberWithDouble:track.duration] forKey:MPMediaItemPropertyPlaybackDuration];
                            [songInfo setObject:[NSNumber numberWithDouble:spPlaybackManager.trackPosition] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
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
    [spPlaybackManager seekToTrackPosition:position];
}

- (void)playPlaylist:(SPPlaylist *)playlist {
    [SPAsyncLoading waitUntilLoaded:playlist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
        currentPlaylist = playlist;
        playlistTrackQueue = [NSMutableArray arrayWithArray:[playlist items]];
        [playlistTrackQueue shuffle];
        playlistTrackQueueIndex = 0;
        SPPlaylistItem *item = [playlistTrackQueue objectAtIndex:0];
        [self playTrack:[item itemURL]];
    }];
}

- (void)nextTrack {
    if (currentPlaylist != nil && playlistTrackQueue != nil
        && playlistTrackQueueIndex < [playlistTrackQueue count]) {
        playlistTrackQueueIndex++;
        SPPlaylistItem *item = [playlistTrackQueue objectAtIndex:playlistTrackQueueIndex];
        [self playTrack:[item itemURL]];
    }
}

- (void)prevTrack {
    if (currentPlaylist != nil && playlistTrackQueue != nil
        && playlistTrackQueueIndex > 0 && [playlistTrackQueue count] > 0) {
        playlistTrackQueueIndex--;
        SPPlaylistItem *item = [playlistTrackQueue objectAtIndex:playlistTrackQueueIndex];
        [self playTrack:[item itemURL]];
    }
}

- (void)pausePlayback {
    [spPlaybackManager setIsPlaying:NO];
}

- (void)resumePlayback {
    [spPlaybackManager setIsPlaying:YES];
}

@end
