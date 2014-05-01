//
//  ARVideoProgressBarView.h
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 4/30/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol ARVideoPlayerLoopingOptionsDelegate <NSObject>
- (void)saveTrimmerUpdates;
@end

@interface ARVideoProgressBarView : UIView

@property (nonatomic, strong) UISlider* currentTimeSlider;
@property (nonatomic, strong) NSNumber* beginTrimTimeInSeconds;
@property (nonatomic, strong) NSNumber* endTrimTimeInSeconds;
@property (nonatomic, strong) AVPlayer* player;
@property (nonatomic, assign) BOOL trimMode;
@property (nonatomic, assign) BOOL allowCustomTrim;

@property (nonatomic, assign) id delegate;

- (void)updateTime:(NSTimer*)timer;
- (void)setMaximumTime:(double)time;

@end
