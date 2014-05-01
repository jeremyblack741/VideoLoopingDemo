//
//  ARVideoProgressBarView.m
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 4/30/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import "ARVideoProgressBarView.h"
#import <CoreMedia/CoreMedia.h>

#define fudgeOffset 0

@interface ARVideoProgressBarView() {
    UILabel *_timeElapsedLabel;
    UILabel *_timeRemainingLabel;
    UIImageView *_beginTrimmer;
    UIImageView *_endTrimmer;
    
    CGPoint _startLocation;
    UIView *_viewToMove;
}
@end

@implementation ARVideoProgressBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews {
    
    // TODO: switch to auto layout
    self.currentTimeSlider = [[UISlider alloc]initWithFrame:CGRectMake(60, 0, 400, 50)];
    self.currentTimeSlider.continuous = YES;
    //    self.currentTimeSlider.maximumValue = self.player.  ;
    //    slider.maximumValue = CMTimeGetSeconds([player duration]);
    self.currentTimeSlider.value = CMTimeGetSeconds(self.player.currentTime);
    //    player.currentTime = CMTimeMakeWithSeconds((int)slider.value,1);
    //    self.currentTimeSlider.maximumValue = self.player.du
    [self.currentTimeSlider setThumbImage:[UIImage imageNamed:@"icon_slider-position-indicator.png"] forState:UIControlStateNormal];
    [self.currentTimeSlider addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.currentTimeSlider];
    
    _timeElapsedLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 3, 60, 40)];
    _timeElapsedLabel.text = @"";
    _timeElapsedLabel.textAlignment = UITextAlignmentLeft;
    [_timeElapsedLabel setFont:[UIFont fontWithName:@"Smith&NephewTF" size:16]];
    _timeElapsedLabel.textColor = [UIColor grayColor];
    _timeElapsedLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_timeElapsedLabel];
    
    _timeRemainingLabel = [[UILabel alloc]initWithFrame:CGRectMake(500, 3, 60, 40)];
    _timeRemainingLabel.text = @"";
    _timeRemainingLabel.textAlignment = UITextAlignmentLeft;
    [_timeRemainingLabel setFont:[UIFont fontWithName:@"Smith&NephewTF" size:16]];
    _timeRemainingLabel.textColor = [UIColor grayColor];
    _timeRemainingLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_timeRemainingLabel];
    
    _beginTrimmer = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_slider-drag-black-bar.png"]];
    _endTrimmer = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_slider-drag-black-bar.png"]];
    [self addSubview:_beginTrimmer];
    [self addSubview:_endTrimmer];
    _beginTrimmer.hidden = YES;
    _endTrimmer.hidden = YES;
}

- (int)computeTrimmerXPositionFromTime:(int)seconds {
    // Maybe move all of this into a compute scale function
    int sliderStartX = self.currentTimeSlider.frame.origin.x;
    int sliderEndX = sliderStartX + self.currentTimeSlider.frame.size.width;
    int pixelRange = sliderEndX - sliderStartX;
    double percentComplete = (double)seconds / self.currentTimeSlider.maximumValue;
    
    NSLog(@"seconds=%i, SliderStartX=%i, SliderEndX=%i, percentComplete=%f, targetX=%i", seconds, sliderStartX, sliderEndX, percentComplete,
          (int)(sliderStartX + (pixelRange * percentComplete) - fudgeOffset));
    return sliderStartX + (pixelRange * percentComplete) - fudgeOffset;
}

- (void)updateBeginAndEndTimesBasedOnTrimmers {
    int sliderStartX = self.currentTimeSlider.frame.origin.x;
    int sliderEndX = sliderStartX + self.currentTimeSlider.frame.size.width;
    int pixelRange = sliderEndX - sliderStartX;
    int totalTime = CMTimeGetSeconds(self.player.currentItem.duration);
    
    double percentComplete = (double)(_beginTrimmer.center.x - sliderStartX) / pixelRange;
    self.beginTrimTimeInSeconds = [NSNumber numberWithDouble:(percentComplete * totalTime)];
    
    percentComplete = (double)(_endTrimmer.center.x - sliderStartX) / pixelRange;
    self.endTrimTimeInSeconds = [NSNumber numberWithDouble:(percentComplete * totalTime)];
    
    [self.delegate saveTrimmerUpdates];
    self.player.currentItem.forwardPlaybackEndTime = CMTimeMake([self.endTrimTimeInSeconds intValue], 1);
    
}


- (void)setAllowCustomTrim:(BOOL)allowCustomTrim {
    [_beginTrimmer setUserInteractionEnabled:allowCustomTrim];
    [_endTrimmer setUserInteractionEnabled:allowCustomTrim];
}

- (void)displayTrimmers {
    _beginTrimmer.hidden = !self.trimMode;
    _endTrimmer.hidden = !self.trimMode;
    
    int beginX = [self computeTrimmerXPositionFromTime:[self.beginTrimTimeInSeconds intValue]];
    int endX = [self computeTrimmerXPositionFromTime:[self.endTrimTimeInSeconds intValue]];
    _beginTrimmer.center = CGPointMake(beginX, 24);
    _endTrimmer.center = CGPointMake(endX, 24);
    _beginTrimmer.backgroundColor = [UIColor clearColor]; // NOTE - I made the images 4 times as wide to make easier to grab
    _endTrimmer.backgroundColor = [UIColor clearColor]; // If have issues - change background color to yellow or something to make easy to see
}


- (void)setTrimMode:(BOOL)trimMode {
    _trimMode = trimMode;
    
    if (!self.beginTrimTimeInSeconds)
        self.beginTrimTimeInSeconds = 0;
    if (!self.endTrimTimeInSeconds)
        self.endTrimTimeInSeconds = [NSNumber numberWithInt:self.currentTimeSlider.maximumValue];
    
    [self displayTrimmers];
}


- (IBAction)sliderValueChangedAction:(id)sender {
    //    self.player.currentTime = self.currentTimeSlider.value;
    [self.player seekToTime:CMTimeMakeWithSeconds((int)self.currentTimeSlider.value, 1)];
}

- (void)updateTime:(NSTimer *)timer {
    self.currentTimeSlider.value = CMTimeGetSeconds(self.player.currentTime);
    
    int elapsed = self.currentTimeSlider.value;
    int minutes = floor(elapsed/60);
    int seconds = round(elapsed - (minutes * 60));
    NSString * timeStr = [NSString stringWithFormat:@"%i:%02i",minutes,seconds];
    
    _timeElapsedLabel.text = [NSString stringWithFormat:@"%@", timeStr];
    
    int remaining = self.currentTimeSlider.maximumValue - elapsed;
    minutes = floor(remaining/60);
    seconds = round(remaining - (minutes * 60));
    timeStr = [NSString stringWithFormat:@"-%i:%02i",minutes,seconds];
    
    _timeRemainingLabel.text = [NSString stringWithFormat:@"%@", timeStr];
    
}

- (void)setMaximumTime:(double)time {
    self.currentTimeSlider.maximumValue = time;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    // Retrieve the touch point
    CGPoint pt = [[touches anyObject] locationInView:self];
    
    if (CGRectContainsPoint(_beginTrimmer.frame, pt)) {
        _viewToMove = _beginTrimmer;
        //        [self bringSubviewToFront:_viewToMove];
    }
    else if (CGRectContainsPoint(_endTrimmer.frame, pt)) {
        _viewToMove = _endTrimmer;
        //        [self bringSubviewToFront:_viewToMove];
    }
    else {
        _viewToMove = nil;
    }
    //    [self bringSubviewToFront:_viewToMove];
    
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    // Move relative to the original touch point
    CGPoint pt = [[touches anyObject] locationInView:_viewToMove];
    CGRect frame = [_viewToMove frame];
    frame.origin.x += pt.x;// - _startLocation.x;
    //    frame.origin.y += pt.y - _startLocation.y;
    
    int minX = self.currentTimeSlider.frame.origin.x;
    int maxX = minX + self.currentTimeSlider.frame.size.width;
    
    // Tighten minX/maxX further to not cross the other trimmer
    if (_viewToMove == _endTrimmer)
    {
        minX = _beginTrimmer.frame.origin.x + 30;
    }
    else if (_viewToMove == _beginTrimmer) {
        maxX = _endTrimmer.frame.origin.x - 30;
    }
    
    // clip to edges
    if (frame.origin.x >= maxX)
        frame.origin.x = maxX - 12;
    if (frame.origin.x <= minX)
        frame.origin.x = minX - 12;
    
    [_viewToMove setFrame:frame];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // update the begin and end times based on new positions
    [self updateBeginAndEndTimesBasedOnTrimmers];
    
}

- (void)dealloc
{
    [self.currentTimeSlider removeFromSuperview];
    [_timeElapsedLabel removeFromSuperview];
    [_timeRemainingLabel removeFromSuperview];
    self.player = nil;
}


@end
