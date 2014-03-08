//
//  ASDMainViewController.h
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/4/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASDPlaybackManager.h"
#import "CocoaLibSpotify.h"
#import "RFduino.h"
#import "RFduinoManagerDelegate.h"

@interface ASDMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RFduinoManagerDelegate, RFduinoDelegate>

@property (strong, nonatomic) IBOutlet UILabel *trackNameLabel;
@property (strong, nonatomic) IBOutlet UISlider *trackPositionSlider;
@property (strong, nonatomic) IBOutlet UITableView *playlistTableView;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;

@property (strong, nonatomic) ASDPlaybackManager *playbackManager;

- (IBAction)trackPositionSliderChanged:(id)sender;
- (IBAction)playPauseClick:(id)sender;
- (IBAction)prevClick:(id)sender;
- (IBAction)nextClick:(id)sender;

- (void)refreshView;

@end
