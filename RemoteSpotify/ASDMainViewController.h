//
//  ASDMainViewController.h
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/4/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CocoaLibSpotify.h"

@interface ASDMainViewController : UIViewController {
    SPPlaybackManager *_playbackManager;
}

@property (strong, nonatomic) IBOutlet UITextField *trackURIField;
@property (strong, nonatomic) SPPlaybackManager *playbackManager;

- (IBAction)playTrack:(id)sender;


@end
