//
//  ARCustomVideoPlayerViewController.h
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 4/30/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ARPlayerView.h"
#import "ARVideoProgressBarView.h"

@interface ARCustomVideoPlayerViewController : UIViewController

@property (nonatomic, strong) AVPlayer* player;
@property (nonatomic, strong) AVPlayerItem* playerItem;
@property (nonatomic, strong) IBOutlet ARPlayerView* playerView;
@property (nonatomic, strong) IBOutlet UIButton* playButton;
@property (nonatomic, strong) IBOutlet UIButton* pauseButton;
@property (nonatomic, strong) IBOutlet UIButton* fastforwardButton;
@property (nonatomic, strong) IBOutlet UIButton* rewindButton;
@property (nonatomic, strong) IBOutlet MPVolumeView* volumeView;
@property (nonatomic, strong) IBOutlet ARVideoProgressBarView* editableProgressBar;
@property (nonatomic, strong) IBOutlet UIView* topControlsOverrideView;

- (void)playVideo:(NSURL*)videoURL;
- (IBAction)stop:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)play:sender;
- (IBAction)fastforward:(id)sender;
- (IBAction)rewind:(id)sender;
- (IBAction)sliderValueChangedAction:(id)sender;

@end
