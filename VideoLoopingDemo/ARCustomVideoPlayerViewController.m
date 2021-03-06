//
//  ARCustomVideoPlayerViewController.m
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 4/30/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import "ARCustomVideoPlayerViewController.h"
#import "ARVideoPlayerLoopingOptionsPopoverViewController.h"
#import "VideoPreference.h"

#define TIMER_UPDATE_INTERVAL 0.65

typedef enum repeatModes {
    REPEAT_NONE = 0,
    REPEAT_ALL,
    REPEAT_CUSTOM,
    REPEAT_RECOMMENDED
} repeatModesType;

@interface ARCustomVideoPlayerViewController () {

    repeatModesType _currentRepeatMode;
    UIPopoverController* _popoverController;

    NSArray* _rewindFastForwardRates;
    int _currentRateIndex;

    NSNumber* _recommendedBeginLoopTime;
    NSNumber* _recommendedEndLoopTime;

    BOOL _playerEverStarted;
    BOOL _timerStarted;
    int _playbackProgress; // kludgy fix for multithreading issue

    int _progressBarStartX;
    int _progressBarWidth;
    int _progressBarHeight;
    int _buttonPaddingToRight;
    int _loopButtonStartX;
    CGSize _loopButtonSize;
}

@property (nonatomic, strong) NSURL* video;
@property (nonatomic, strong) IBOutlet UIButton* loopButton;

@end

@implementation ARCustomVideoPlayerViewController

// Define this constant for the key-value observation context.
static const NSString* ItemStatusContext;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:@"ARCustomVideoPlayerViewController"
                           bundle:nil];

    if (self) {
        // Custom initialization
        _playerEverStarted = NO;
        _timerStarted = NO;

        [self initScanRates];
    }
    return self;
}

/*
- (id)initWithVideoDict:(NSDictionary *)dict
{
    self = [super initWithNibName:@"ARVideoPlayerViewController" bundle:nil];
    if (self) {
        // Custom initialization
        NSString *s = [self fileForPath:[dict objectForKey:@"file"]];
        NSURL *u = [NSURL fileURLWithPath:s];
        
        self.video = u;
        
        _recommendedBeginLoopTime = [dict objectForKey:@"loopStartTime"];
        _recommendedEndLoopTime = [dict objectForKey:@"loopEndTime"];
        
        [self initScanRates];
    }
    return self;
}
 */

- (void)initScanRates
{
    _rewindFastForwardRates = @[
        @-16,
        @-8,
        @-4,
        @-2.2,
        @-1.5,
        @-1,
        @1,
        @1.5,
        @2.2,
        @4,
        @8,
        @16
    ];
    _currentRateIndex = 6;
}

- (void)increasePlaybackRate
{
    if (_currentRateIndex < _rewindFastForwardRates.count - 1)
        _currentRateIndex++;
    self.player.rate = [[_rewindFastForwardRates objectAtIndex:_currentRateIndex] doubleValue];
}

- (void)decreasePlaybackRate
{
    if (_currentRateIndex > 0)
        _currentRateIndex--;
    self.player.rate = [[_rewindFastForwardRates objectAtIndex:_currentRateIndex] doubleValue];
}

- (void)resetPlaybackRate
{
    _currentRateIndex = 6;
    self.player.rate = [[_rewindFastForwardRates objectAtIndex:_currentRateIndex] doubleValue];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.player pause];
    [self.playerItem removeObserver:self
                         forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.editableProgressBar.delegate = nil;
    [self.playerView removeFromSuperview];
    [self.topControlsOverrideView removeFromSuperview];
    [self.editableProgressBar removeFromSuperview];
    self.editableProgressBar.player = nil;
    self.player = nil;
    self.playerItem = nil;
    self.playerView = nil;
    self.editableProgressBar = nil;
    self.topControlsOverrideView = nil;
}

- (void)calculatePositions
{
    double percentToUseForProgressBar = 0.65;
    _progressBarHeight = 50;
    _progressBarWidth = self.view.frame.size.width * percentToUseForProgressBar;
    _progressBarStartX = (self.view.frame.size.width / 2) - (_progressBarWidth / 2);
    _buttonPaddingToRight = 30;

    _loopButtonStartX = self.view.frame.size.width - _loopButtonSize.width - _buttonPaddingToRight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _currentRepeatMode = REPEAT_NONE;

    [self calculatePositions];
    self.editableProgressBar = [[ARVideoProgressBarView alloc] initWithFrame:CGRectMake(_progressBarStartX, 0, _progressBarWidth, _progressBarHeight)];
    self.editableProgressBar.delegate = self;
    self.editableProgressBar.player = self.player;

    // If we have a navigation bar, add the progress bar to that - otherwise add somewhere at top
    if (self.navigationController) {
        [self.navigationController.navigationBar addSubview:self.editableProgressBar];
    } else {
        if (self.topControlsOverrideView) {
            [self.editableProgressBar setFrame:CGRectMake(_progressBarStartX, 0, _progressBarWidth, _progressBarHeight)];
            [self.topControlsOverrideView addSubview:self.editableProgressBar];
        }
    }

    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.loopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIImage* buttonImage = [UIImage imageNamed:@"button_no-loop.png"];
    [self.loopButton setBackgroundImage:buttonImage
                               forState:UIControlStateNormal];
    _loopButtonSize = buttonImage.size;
    int loopButtonStartX = self.view.frame.size.width - buttonImage.size.width - _buttonPaddingToRight;
    self.loopButton.frame = CGRectMake(loopButtonStartX, 5, buttonImage.size.width, buttonImage.size.height);

    [self.loopButton addTarget:self
                        action:@selector(displayLoopingMenu:)
              forControlEvents:UIControlEventTouchUpInside];

    if (self.navigationController) {
        [self.navigationController.navigationBar addSubview:self.loopButton];
    } else {
        if (self.topControlsOverrideView) {
            [self.loopButton setFrame:CGRectMake(loopButtonStartX, 5, buttonImage.size.width, buttonImage.size.height)];
            [self.topControlsOverrideView addSubview:self.loopButton];
        }
    }

    [self.volumeView setVolumeThumbImage:[UIImage imageNamed:@"icon_slider-position-indicator.png"]
                                forState:UIControlStateNormal];

    [self syncUI];

    // Turn off the loop button for phones (popovers don't work anyway)
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        self.loopButton.hidden = YES;
    }
}

- (void)viewWillLayoutSubviews
{

    [self calculatePositions];
    [self.editableProgressBar setFrame:CGRectMake(_progressBarStartX, 0, _progressBarWidth, _progressBarHeight)];
    [self.loopButton setFrame:CGRectMake(_loopButtonStartX, 5, _loopButtonSize.width, _loopButtonSize.height)];

    NSLog(@"Device rotated - width=%f, height=%f", self.view.frame.size.width, self.view.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateTime:(NSTimer*)timer
{
    [self.editableProgressBar updateTime:timer];
    _playbackProgress++;
    //    self.currentTimeSlider.value = CMTimeGetSeconds(self.player.currentTime);
}

- (void)updateProgressBarMaxTime
{
    [self.editableProgressBar setMaximumTime:CMTimeGetSeconds(self.player.currentItem.duration)];
}

- (void)playVideo:(NSURL*)videoURL
{
    self.video = videoURL;
    [self loadAssetFromURL:videoURL];

    [self performSelector:@selector(playStartingAtTime:)
               withObject:0
               afterDelay:0.5];
}

- (void)playStartingAtTime:(NSNumber*)startTimeInSeconds
{
    CMTime seekTime = CMTimeMake([startTimeInSeconds intValue], 1);
    [self.player seekToTime:seekTime];

    [self play];
}

- (void)play
{
    [self.player play];
    [self resetPlaybackRate];
    _playerEverStarted = YES;

    self.pauseButton.hidden = NO;
    self.playButton.hidden = YES;

    [self performSelector:@selector(updateProgressBarMaxTime)
               withObject:nil
               afterDelay:0.5];

    if (!_timerStarted) {
        [NSTimer scheduledTimerWithTimeInterval:TIMER_UPDATE_INTERVAL
                                         target:self
                                       selector:@selector(updateTime:)
                                       userInfo:nil
                                        repeats:YES];
        _timerStarted = YES;
    }
}

- (IBAction)play:sender
{
    [self play];
}

// Use this to pause the player - play will start where it left off
- (IBAction)pause:(id)sender
{
    [self.player pause];

    self.playButton.hidden = NO;
    self.pauseButton.hidden = YES;
}

- (IBAction)fastforward:(id)sender
{
    self.pauseButton.hidden = YES;
    self.playButton.hidden = NO;

    [self increasePlaybackRate];
}

- (IBAction)rewind:(id)sender
{
    self.pauseButton.hidden = YES;
    self.playButton.hidden = NO;

    [self decreasePlaybackRate];
}

- (void)syncUI
{
    if ((self.player.currentItem != nil) && ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    } else {
        self.playButton.enabled = NO;
    }
}

- (void)loadAssetFromURL:(NSURL*)fileURL
{

    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:fileURL
                                            options:nil];
    NSString* tracksKey = @"tracks";

    [asset loadValuesAsynchronouslyForKeys:@[
                                              tracksKey
                                           ]
                         completionHandler:
                             ^{
         // The completion block goes here.
         
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            NSError *error;
                            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
                            
                            if (status == AVKeyValueStatusLoaded) {
                                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                [self.playerItem addObserver:self forKeyPath:@"status"
                                                     options:0 context:&ItemStatusContext];
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:self.playerItem];
                                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                                [self.playerView setPlayer:self.player];
                                self.editableProgressBar.player = self.player;
                                
                                
                                if (self.playerView.player.status == AVPlayerStatusReadyToPlay) {
                                    if([((AVPlayerLayer *)[self.playerView layer]).videoGravity isEqualToString:AVLayerVideoGravityResizeAspect])
                                        ((AVPlayerLayer *)[self.playerView layer]).videoGravity = AVLayerVideoGravityResizeAspectFill;
                                    else
                                        ((AVPlayerLayer *)[self.playerView layer]).videoGravity = AVLayerVideoGravityResizeAspect;
                                    
                                    //           ((AVPlayerLayer *)[self.playerView layer]).bounds = ((AVPlayerLayer *)[self.playerView layer]).bounds;
                                }
                                
                                
                                
                            }
                            else {
                                // You should deal with the error appropriately.
                                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                            }
                        });
                             }];
}

- (void)playerItemDidReachEnd:(NSNotification*)notification
{

    if (_currentRepeatMode == REPEAT_NONE) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification
                                                            object:nil];
    } else if (_currentRepeatMode == REPEAT_ALL) {
        [self.player seekToTime:kCMTimeZero];

        [self.player play];
    } else if (_currentRepeatMode == REPEAT_CUSTOM) {
        [self.player seekToTime:CMTimeMake([self.editableProgressBar.beginTrimTimeInSeconds intValue], 1)];

        [self.player play];
    } else if (_currentRepeatMode == REPEAT_RECOMMENDED) {
        [self.player seekToTime:CMTimeMake([_recommendedBeginLoopTime intValue], 1)];

        [self.player play];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{

    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncUI];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
    return;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
    //    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
}

- (IBAction)displayLoopingMenu:(id)sender
{
    ARVideoPlayerLoopingOptionsPopoverViewController* popoverVC = [[ARVideoPlayerLoopingOptionsPopoverViewController alloc] initWithNibName:nil
                                                                                                                                     bundle:nil];
    popoverVC.delegate = self;
    if (_recommendedBeginLoopTime && _recommendedEndLoopTime) {
        popoverVC.includeRecommendedOption = YES;
    }
    if (_popoverController) {
        _popoverController = nil;
    }

    _popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverVC];
    [_popoverController presentPopoverFromRect:CGRectMake(self.loopButton.frame.origin.x,
                                                          self.loopButton.frame.origin.y,
                                                          self.loopButton.frame.size.width,
                                                          self.loopButton.frame.size.height)
                                        inView:self.loopButton.superview
                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                      animated:YES];
}

- (void)selectLoopingOption:(int)option
{
    if (_popoverController && [_popoverController isPopoverVisible]) {
        [_popoverController dismissPopoverAnimated:YES];
    }

    _currentRepeatMode = option;

    self.editableProgressBar.trimMode = NO;

    self.player.currentItem.forwardPlaybackEndTime = self.player.currentItem.duration;

    if (_currentRepeatMode == REPEAT_NONE) {
        UIImage* buttonImage = [UIImage imageNamed:@"button_no-loop.png"];
        [self.loopButton setBackgroundImage:buttonImage
                                   forState:UIControlStateNormal];
    } else {
        UIImage* buttonImage = [UIImage imageNamed:@"button_loop.png"];
        [self.loopButton setBackgroundImage:buttonImage
                                   forState:UIControlStateNormal];

        self.editableProgressBar.trimMode = NO;

        if (_currentRepeatMode == REPEAT_CUSTOM) {
            [self loadCustomTrimmer];

            self.player.currentItem.forwardPlaybackEndTime = CMTimeMake([self.editableProgressBar.endTrimTimeInSeconds intValue], 1);
            self.editableProgressBar.allowCustomTrim = YES;
            self.editableProgressBar.trimMode = YES;
        } else if (_currentRepeatMode == REPEAT_RECOMMENDED) {
            self.editableProgressBar.beginTrimTimeInSeconds = _recommendedBeginLoopTime;
            self.editableProgressBar.endTrimTimeInSeconds = _recommendedEndLoopTime;
            self.player.currentItem.forwardPlaybackEndTime = CMTimeMake([self.editableProgressBar.endTrimTimeInSeconds intValue], 1);
            self.editableProgressBar.trimMode = YES;
            self.editableProgressBar.allowCustomTrim = NO;
        }
    }
}

- (VideoPreference*)findVideoPreference
{
    VideoPreference* found = nil;
    NSString* filename = [[self.video pathComponents] lastObject];
    NSLog(@"looking for path %@", filename);
    NSArray* matching = [VideoPreference MR_findByAttribute:@"videoPath"
                                                  withValue:filename];
    if (matching && matching.count >= 1) {
        found = [matching objectAtIndex:0];
    }
    return found;
}

- (void)saveTrimmerUpdates
{
    NSString* filename = [[self.video pathComponents] lastObject];
    NSLog(@"Saving trim times for %@: %i to %i", filename, [self.editableProgressBar.beginTrimTimeInSeconds intValue],
          [self.editableProgressBar.endTrimTimeInSeconds intValue]);

    // Get the local context
    NSManagedObjectContext* localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    VideoPreference* videoPreference = [self findVideoPreference];
    if (!videoPreference) {
        videoPreference = [VideoPreference MR_createInContext:localContext];
        videoPreference.videoPath = filename;
        videoPreference.loopStartTime = self.editableProgressBar.beginTrimTimeInSeconds;
        videoPreference.loopEndTime = self.editableProgressBar.endTrimTimeInSeconds;
        [localContext MR_saveToPersistentStoreAndWait];
    } else {
        videoPreference.loopStartTime = self.editableProgressBar.beginTrimTimeInSeconds;
        videoPreference.loopEndTime = self.editableProgressBar.endTrimTimeInSeconds;
        [localContext MR_saveToPersistentStoreAndWait];
    }
}

- (void)loadCustomTrimmer
{
    VideoPreference* videoPreference = [self findVideoPreference];
    if (videoPreference) {
        self.editableProgressBar.beginTrimTimeInSeconds = videoPreference.loopStartTime;
        self.editableProgressBar.endTrimTimeInSeconds = videoPreference.loopEndTime;
    }
    NSLog(@"Loading trim times for %@: %i to %i", self.video, [self.editableProgressBar.beginTrimTimeInSeconds intValue],
          [self.editableProgressBar.endTrimTimeInSeconds intValue]);
}

- (NSString*)documentsDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    return [paths objectAtIndex:0];
}

- (NSString*)fileForPath:(NSString*)filePath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return filePath;
    }

    NSString* file = [NSString stringWithFormat:@"%@/%@", [self documentsDirectory], filePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
        file = nil;
        file = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], filePath];
    }

    return file;
}

@end
