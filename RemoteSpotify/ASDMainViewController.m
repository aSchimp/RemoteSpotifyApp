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
#import "ScanViewController.h"
#import "RfduinoManager.h"

@interface ASDMainViewController ()
{
    RFduinoManager *rfduinoManager;
    ScanViewController *scanViewController;
    RFduino *currentRFduino;
}

@property (strong, nonatomic) NSArray *playlists;

@end

@implementation ASDMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[self navigationItem] setTitle:@"Remote Spotify"];
        [self setupConnectBtn];
        
        rfduinoManager = RFduinoManager.sharedRFduinoManager;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    rfduinoManager.delegate = self;
    
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
    
    // add the switch to toggle markedForOfflinePlayback on the playlist, and a download progress indicator
    UIView *accessoryView = [[UIView alloc] init];
    
    UISwitch *offlineSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    offlineSwitch.on = playlist.markedForOfflinePlayback;
    [offlineSwitch addTarget:self action:@selector(offlineSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    
    UILabel *progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(offlineSwitch.frame.size.width + 5.0f, 0.0f, 65.0f, offlineSwitch.frame.size.height)];
    if (playlist.markedForOfflinePlayback) {
        if (playlist.offlineStatus == SP_PLAYLIST_OFFLINE_STATUS_YES) {
            [progressLabel setText:@"Done"];
        }
        else if (playlist.offlineStatus == SP_PLAYLIST_OFFLINE_STATUS_WAITING) {
            [progressLabel setText:@"Queue"];
        }
        else if (playlist.offlineStatus == SP_PLAYLIST_OFFLINE_STATUS_DOWNLOADING) {
            [progressLabel setText:[NSString stringWithFormat:@"%.02f%%", playlist.offlineDownloadProgress * 100.0f]];
        }
    }
    
    
    accessoryView.frame = CGRectMake(0.0f, 0.0f, offlineSwitch.frame.size.width + 70.0f, offlineSwitch.frame.size.height);
    [accessoryView addSubview:offlineSwitch];
    [accessoryView addSubview:progressLabel];
    cell.accessoryView = accessoryView;
    
    return cell;
}

- (void)offlineSwitchChanged:(id)sender {
    UISwitch *theSwitch = (UISwitch*)sender;
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.playlistTableView];
    NSIndexPath *pathToCell = [self.playlistTableView indexPathForRowAtPoint:buttonPosition];
    SPPlaylist *playlist = [self.playlists objectAtIndex:[pathToCell row]];
    playlist.markedForOfflinePlayback = theSwitch.on;
    NSLog(@"Offline status change to %@ for %@", theSwitch.on ? @"YES" : @"NO", [playlist name]);
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

- (IBAction)prevClick:(id)sender {
    [self.playbackManager prevTrack];
}

- (IBAction)nextClick:(id)sender {
    [self.playbackManager nextTrack];
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

- (void)didReceive:(NSData *)data {
    if ([data length] > 0) {
        const unsigned char *bytes = [data bytes];
        NSLog(@"Received data: %d", (int)bytes[0]);
        switch (bytes[0])
        {
            case 0:
                [self.playbackManager nextTrack];
                break;
            case 1:
                [self.playbackManager prevTrack];
                break;
        }
    }
}

- (void)setupConnectBtn {
    UIBarButtonItem *connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Connect" style:UIBarButtonItemStylePlain target:self action:@selector(showScanView)];
    [[self navigationItem] setRightBarButtonItem:connectButton];
}

- (void)setupDisconnectBtn {
    UIBarButtonItem *connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect" style:UIBarButtonItemStylePlain target:self action:@selector(disconnectRFduino)];
    [[self navigationItem] setRightBarButtonItem:connectButton];
}

- (void) disconnectRFduino {
    [currentRFduino disconnect];
}

- (void)showScanView {
    scanViewController = [[ScanViewController alloc] init];
    [[self navigationController] pushViewController:scanViewController animated:YES];
}

- (void)didDiscoverRFduino:(RFduino *)rfduino
{
    if (scanViewController != nil && [scanViewController respondsToSelector:@selector(didDiscoverRFduino:)])
        [scanViewController didDiscoverRFduino:rfduino];
}

- (void)didUpdateDiscoveredRFduino:(RFduino *)rfduino
{
    if (scanViewController != nil && [scanViewController respondsToSelector:@selector(didUpdateDiscoveredRFduino:)])
        [scanViewController didUpdateDiscoveredRFduino:rfduino];
}

- (void)didConnectRFduino:(RFduino *)rfduino
{
    NSLog(@"didConnectRFduino");
    
    if (scanViewController != nil && [scanViewController respondsToSelector:@selector(didConnectRFduino:)])
        [scanViewController didConnectRFduino:rfduino];
    
    [rfduinoManager stopScan];
}

- (void)didLoadServiceRFduino:(RFduino *)rfduino
{
    if (scanViewController != nil && [scanViewController respondsToSelector:@selector(didLoadServiceRFduino:)])
        [scanViewController didLoadServiceRFduino:rfduino];
    
    currentRFduino = rfduino;
    currentRFduino.delegate = self;
    [[self navigationController] popViewControllerAnimated:YES];
    [self setupDisconnectBtn];
}

- (void)didDisconnectRFduino:(RFduino *)rfduino
{
    NSLog(@"didDisconnectRFduino");
    
    [rfduinoManager startScan];
    if (scanViewController != nil && [scanViewController respondsToSelector:@selector(didDisconnectRFduino:)])
        [scanViewController didDisconnectRFduino:rfduino];
    [self setupConnectBtn];
}


@end
