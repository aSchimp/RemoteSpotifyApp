//
//  ASDMainViewController.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/4/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import "ASDMainViewController.h"
#import "CocoaLibSpotify.h"

@interface ASDMainViewController ()

@end

@implementation ASDMainViewController

@synthesize playbackManager = _playbackManager;

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
    self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playTrack:(id)sender {
    if (self.trackURIField.text.length > 0) {
        NSURL *trackUrl = [NSURL URLWithString:self.trackURIField.text];
        [[SPSession sharedSession] trackForURL:trackUrl callback:^(SPTrack *track) {
            if (track != nil) {
                [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
                    [self.playbackManager playTrack:track callback:^(NSError *error) {
                        if (error) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Play Track" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            
                            [alert show];
                        }
                        else {
                            NSLog(@"Callback success");
                        }
                    }];
                }];
            }
        }];
        
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Play Track" message:@"Please enter a track url." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
}
@end
