//
//  VideoPreference.h
//  VideoLoopingDemo
//
//  Created by Jeremy Black on 5/1/14.
//  Copyright (c) 2014 Jeremy Black. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface VideoPreference : NSManagedObject

@property (nonatomic, retain) NSNumber * loopEndTime;
@property (nonatomic, retain) NSNumber * loopStartTime;
@property (nonatomic, retain) NSString * videoPath;

@end
