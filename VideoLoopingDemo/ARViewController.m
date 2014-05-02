//
//  ARViewController.m
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 4/30/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import "ARViewController.h"
#import "ARCustomVideoPlayerViewController.h"

@interface ARViewController ()
@property (nonatomic, weak) IBOutlet UIView* mainContentView;
@property (nonatomic, strong) ARCustomVideoPlayerViewController* mainVideoViewController;
@end

@implementation ARViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizesSubviews = YES;

    self.mainVideoViewController = [[ARCustomVideoPlayerViewController alloc] initWithNibName:@"ARCustomVideoPlayerViewController"
                                                                                       bundle:nil];
    [self addChildViewController:self.mainVideoViewController];
    self.mainVideoViewController.view.frame = self.mainContentView.bounds;
    [self.mainContentView addSubview:self.mainVideoViewController.view];
    [self.mainVideoViewController didMoveToParentViewController:self];

    [self playTestVideo];

    self.mainContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleHeight;
    self.mainVideoViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleHeight;
    self.mainVideoViewController.view.autoresizesSubviews = YES;
    
}

- (void)viewDidLayoutSubviews {
    
    self.mainVideoViewController.view.frame = self.mainContentView.bounds;
}


- (void)playTestVideo
{
    NSURL* fileURL = [[NSBundle mainBundle] URLForResource:@"Wildlife_512kb"
                                             withExtension:@"mp4"];
    [self.mainVideoViewController playVideo:fileURL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                            duration:duration];
}

@end
