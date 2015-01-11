//
//  ViewController.h
//  Drop
//
//  Created by Kyle Dillon on 12/12/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <Firebase/Firebase.h>


@interface ViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;
- (IBAction)switchCameras:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *cameraOverlayView;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@end

