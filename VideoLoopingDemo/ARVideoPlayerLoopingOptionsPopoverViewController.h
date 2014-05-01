//
//  ARVideoPlayerLoopingOptionsPopoverViewController.h
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 4/30/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ARVideoPlayerLoopingOptionsDelegate <NSObject>
- (void)selectLoopingOption:(int)option;
@end

@interface ARVideoPlayerLoopingOptionsPopoverViewController : UITableViewController

@property (nonatomic, assign) BOOL includeRecommendedOption;
@property (nonatomic, assign) id delegate;

@end
