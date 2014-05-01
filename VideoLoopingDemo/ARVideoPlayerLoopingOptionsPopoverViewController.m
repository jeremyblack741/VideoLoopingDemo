//
//  ARVideoPlayerLoopingOptionsPopoverViewController.m
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 4/30/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import "ARVideoPlayerLoopingOptionsPopoverViewController.h"

@interface ARVideoPlayerLoopingOptionsPopoverViewController ()

@property (nonatomic, strong) NSArray* menuOptions;

@end

@implementation ARVideoPlayerLoopingOptionsPopoverViewController

- (id)initWithFrame:(UITableViewStyle)style
{
    self = [super initWithStyle:(UITableViewStyle)style];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    if (self.includeRecommendedOption) {
        self.preferredContentSize = CGSizeMake(220, 170);
        self.menuOptions = @[
            @"No loop",
            @"Full video loop",
            @"Custom loop",
            @"Recommended"
        ];
    } else {
        self.preferredContentSize = CGSizeMake(220, 140);
        self.menuOptions = @[
            @"No loop",
            @"Full video loop",
            @"Custom loop"
        ];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.menuOptions.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* CellIdentifier = @"VideoLoopingMenuOptionsCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
        [cell.textLabel setFont:[UIFont systemFontOfSize:16]];
        [cell.textLabel setTextColor:[UIColor blackColor]];
    }

    // Configure the cell...
    cell.textLabel.text = [self.menuOptions objectAtIndex:indexPath.row];

    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0) {
        [self.delegate selectLoopingOption:indexPath.row];
    }
}

@end
