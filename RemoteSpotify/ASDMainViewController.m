//
//  ASDMainViewController.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/4/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import "ASDMainViewController.h"
#import "ASDAppDelegate.h"
#import "CocoaLibSpotify.h"

@interface ASDMainViewController ()

@property (strong, nonatomic) NSArray *playlists;

@end

@implementation ASDMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.playbackManager addObserver:self forKeyPath:@"currentTrack.name" options:0 context:nil];
    [self.playbackManager addObserver:self forKeyPath:@"currentTrack.duration" options:0 context:nil];
    [self.playbackManager addObserver:self forKeyPath:@"trackPosition" options:0 context:nil];
    [self.playbackManager addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentTrack.name"]) {
        self.trackNameLabel.text = self.playbackManager.currentTrack.name;
    }
    else if ([keyPath isEqualToString:@"currentTrack.duration"]) {
        self.trackPositionSlider.maximumValue = self.playbackManager.currentTrack.duration;
    }
    else if ([keyPath isEqualToString:@"trackPosition"]) {
        if (!self.trackPositionSlider.highlighted)
            self.trackPositionSlider.value = self.playbackManager.trackPosition;
    }
    else if ([keyPath isEqualToString:@"isPlaying"]) {
        if ([self.playbackManager isPlaying] == YES) {
            [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        }
        else {
            [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playlists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell Identifier";
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    SPPlaylist *playlist = [self.playlists objectAtIndex:[indexPath row]];
    [cell.textLabel setText:[playlist name]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SPPlaylist *playlist = [self.playlists objectAtIndex:[indexPath row]];
    [self.playbackManager playPlaylist:playlist];
}

- (IBAction)trackPositionSliderChanged:(id)sender {
    [self.playbackManager updateTrackPosition:self.trackPositionSlider.value];
}

- (IBAction)playPauseClick:(id)sender {
    if ([self.playbackManager isPlaying] == YES) {
        [self.playbackManager pausePlayback];
    }
    else {
        [self.playbackManager resumePlayback];
    }
}

- (void)refreshView {
    SPPlaylistContainer *playlistContainer = [SPSession sharedSession].userPlaylists;
    [SPAsyncLoading waitUntilLoaded:playlistContainer timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
        self.playlists = [playlistContainer flattenedPlaylists];
        [SPAsyncLoading waitUntilLoaded:self.playlists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
            [self.playlistTableView reloadData];
        }];
    }];
}
@end
