//
//  Drop.h
//  Drop
//
//  Created by Kyle Dillon on 1/10/15.
//  Copyright (c) 2015 KJDev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Drop : NSObject

@property NSString *dropKey;
@property NSString *dropperKey;
@property NSString *dropperUsername;
@property NSDate *dropDate;
@property NSString *imageKey;
@property CLLocation *location;
@property BOOL publicDrop;
@property UIImage *image;

@end
