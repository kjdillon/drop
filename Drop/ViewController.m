//
//  ViewController.m
//  Drop
//
//  Created by Kyle Dillon on 12/12/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "ViewController.h"
#import "Drop.h"
#include <MobileCoreServices/MobileCoreServices.h>
#include <CoreVideo/CoreVideo.h>
#include <CoreMedia/CoreMedia.h>
#include <AVFoundation/AVFoundation.h>
#include <ImageIO/ImageIO.h>

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@interface ViewController ()

@end

@implementation ViewController

AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
AVCaptureStillImageOutput *stillImageOutput;

UITapGestureRecognizer *takePhotoTap;
UISwipeGestureRecognizer *swipeDeleteLeft;
UISwipeGestureRecognizer *swipeDeleteRight;
UISwipeGestureRecognizer *swipeDropDown;

CLLocationManager *locationManager;
CLLocation *currentLocation;

NSMutableArray *collectedDropKeys;
NSMutableArray *dropsOnMap;

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDatabase];
    [self setupGestures];
    [self setupMapAndLocation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupCameraView];
}

#pragma mark Database

-(void) setupDatabase {
    // First download collected Drops
    collectedDropKeys = [[NSMutableArray alloc] init];
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com/users"];
    NSString *UID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UID"];
    ref = [ref childByAppendingPath: UID];
    ref = [ref childByAppendingPath: @"dropsCollected"];
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *collectedDropsDict = (NSDictionary*) snapshot.value;
        if(![collectedDropsDict isKindOfClass:[NSNull class]]) { // Only if they have actually collected drops
            [collectedDropKeys addObjectsFromArray: [collectedDropsDict allValues]];
        }
        
        // After collectedDrops have been downloaded, then download and filter the nearby drops
        [self downloadAndListenForDrops];
    }];
}

-(void) downloadAndListenForDrops {
    // Download and filter out drops to put on the map
    dropsOnMap = [[NSMutableArray alloc] init];
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com/drops"];
    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *dropDict = (NSDictionary*) snapshot.value;
        Drop *drop = [[Drop alloc] init];
        drop.dropperKey = dropDict[@"dropperUID"];
        NSNumber *epochTime = dropDict[@"epoch"];
        double epochTimeDouble = [epochTime doubleValue];
        drop.dropDate = [NSDate dateWithTimeIntervalSince1970:epochTimeDouble];
        drop.imageKey = dropDict[@"imageKey"];
        double lat = [(NSNumber*)dropDict[@"lat"] doubleValue];
        double lon = [(NSNumber*)dropDict[@"lon"] doubleValue];
        drop.location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        bool public = [(NSNumber*)dropDict[@"public"] boolValue];
        drop.publicDrop = public;
        drop.dropKey = snapshot.key;
        
        // Add the drop to the map drops only if it has not yet been collected.
        if(![collectedDropKeys containsObject:drop.dropKey]) {
            [dropsOnMap addObject:drop];
            [self refreshMapMarkers];
            [self zoomToCurrentLocation];
        }
    }];
}

-(void) uploadDropWithImage:(UIImage*) image {
    // Upload everything in parallel, but get keys in order: photo, metadata, userDrops
    
    // Photo upload
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com/photos"];
    ref = [ref childByAutoId];
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *encodedString = [imageData base64Encoding];
    [ref setValue:encodedString withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"Photo could not be uploaded."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    // Drop data upload
    NSDictionary *drop = @{
                           @"dropperUID" : [[NSUserDefaults standardUserDefaults] stringForKey:@"UID"],
                           @"epoch": [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
                           @"imageKey": ref.key,
                           @"lat": [NSNumber numberWithDouble: currentLocation.coordinate.latitude],
                           @"lon": [NSNumber numberWithDouble: currentLocation.coordinate.longitude],
                           @"public": [NSNumber numberWithBool:NO]
                           };
    Firebase *ref2 = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com/drops"];
    ref2 = [ref2 childByAutoId];
    [ref2 setValue:drop withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"Drop data could not be uploaded."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    // User drops key upload
    Firebase *ref3 = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com/users"];
    NSString *UID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UID"];
    ref3 = [ref3 childByAppendingPath: UID];
    ref3 = [ref3 childByAppendingPath: @"drops"];
    ref3 = [ref3 childByAutoId];
    [ref3 setValue:ref2.key withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"Drop user key could not be uploaded."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

#pragma mark Map and Location

-(void) refreshMapMarkers {
    NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy];
    [annotationsToRemove removeObject:self.mapView.userLocation];
    [self.mapView removeAnnotations:annotationsToRemove];
    for(Drop *drop in dropsOnMap) {
        MKPointAnnotation *dropPoint = [[MKPointAnnotation alloc] init];
        dropPoint.coordinate = drop.location.coordinate;
        [self.mapView addAnnotation:dropPoint];
    }
}

- (void) mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views
{
    for (MKAnnotationView *view in views)
    {
        if ([[view annotation] isKindOfClass:[MKUserLocation class]]) {
            view.layer.zPosition = 2;
        }
        else {
            view.layer.zPosition = 1;
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        // Try to dequeue an existing pin view first.
        MKAnnotationView *pinView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"DropAnnotationView"];
        if (!pinView){
            pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"DropAnnotationView"];
            pinView.canShowCallout = NO;
            UIImage *image = [UIImage imageNamed:@"friend_drop_message"];
            pinView.image = image;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    currentLocation = [locations objectAtIndex:0];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if(status == kCLAuthorizationStatusAuthorized) {
        [self zoomToCurrentLocation];
    }
}

-(void) zoomToCurrentLocation {
    MKCoordinateSpan span;
    span.latitudeDelta=0.005;
    span.longitudeDelta=0.005;
    MKCoordinateRegion cordinateRegion;
    cordinateRegion.center = currentLocation.coordinate;
    cordinateRegion.span=span;
    [self.mapView setRegion:cordinateRegion animated:YES];
}

-(void) setupMapAndLocation {
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
}

#pragma mark Gestures

-(void) setupGestures {
    takePhotoTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureNow)];
    [self.cameraOverlayView addGestureRecognizer:takePhotoTap];
    
    swipeDeleteLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDeleteLeft)];
    swipeDeleteLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.cameraOverlayView addGestureRecognizer:swipeDeleteLeft];
    
    swipeDeleteRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDeleteRight)];
    swipeDeleteRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.cameraOverlayView addGestureRecognizer:swipeDeleteRight];
    
    swipeDropDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDropDown)];
    swipeDropDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.cameraOverlayView addGestureRecognizer:swipeDropDown];

}

-(void) swipeDeleteLeft {
    if(self.photoView.image == nil) return; // If the image does not exist then dont animate it.
    
    CGAffineTransform originalTransform = self.photoView.transform;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(self.photoView.frame.origin.x - (self.photoView.frame.size.width * 0.75), self.photoView.frame.origin.y);
    CGAffineTransform scale = CGAffineTransformMakeScale(0.9, 0.9);
    CGAffineTransform transform =  CGAffineTransformConcat(translate, scale);
    transform = CGAffineTransformRotate(transform, DEGREES_TO_RADIANS(-11.25));
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.photoView.layer.opacity = 0.25;
                         self.photoView.transform = transform;
                     }completion:^(BOOL finished){
                         self.photoView.image = nil;
                         self.photoView.layer.opacity = 1.0;
                         self.photoView.transform = originalTransform;
                     }];
}

-(void) swipeDeleteRight {
    if(self.photoView.image == nil) return; // If the image does not exist then dont animate it.
    
    CGAffineTransform originalTransform = self.photoView.transform;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(self.photoView.frame.origin.x + (self.photoView.frame.size.width * 0.75), self.photoView.frame.origin.y);
    CGAffineTransform scale = CGAffineTransformMakeScale(0.9, 0.9);
    CGAffineTransform transform =  CGAffineTransformConcat(translate, scale);
    transform = CGAffineTransformRotate(transform, DEGREES_TO_RADIANS(11.25));
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.photoView.layer.opacity = 0.25;
                         self.photoView.transform = transform;
                     }completion:^(BOOL finished){
                         self.photoView.image = nil;
                         self.photoView.layer.opacity = 1.0;
                         self.photoView.transform = originalTransform;
                     }];
}

-(void) swipeDropDown {
    if(self.photoView.image == nil) return; // If the image does not exist then dont animate it.
    
    [self uploadDropWithImage:self.photoView.image];
    
    [self zoomToCurrentLocation];
    
    CGAffineTransform originalTransform = self.photoView.transform;
    int distanceFromPhotoToMap = self.mapView.center.y - self.photoView.center.y;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(self.photoView.frame.origin.x, self.photoView.frame.origin.y + distanceFromPhotoToMap*40.0); // 40 to counter-act the scaling
    CGAffineTransform scale = CGAffineTransformMakeScale(0.025, 0.025);
    CGAffineTransform transform =  CGAffineTransformConcat(translate, scale);
    transform = CGAffineTransformRotate(transform, DEGREES_TO_RADIANS(0));
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.photoView.transform = transform;
                     }completion:^(BOOL finished){
                         self.photoView.image = nil;
                         self.photoView.transform = originalTransform;
                     }];
}

#pragma mark Camera

-(void) setupCameraView {
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    CALayer *viewLayer = self.cameraView.layer;
    NSLog(@"viewLayer = %@", viewLayer);
    
    captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    
    captureVideoPreviewLayer.frame = self.cameraView.bounds;
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.cameraView.layer addSublayer:captureVideoPreviewLayer];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    [session addInput:input];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:stillImageOutput];
    
    [session startRunning];
}

-(void)captureNow
{
    if(self.photoView.image != nil) return; // Image is being previewed, do not take another one.
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    NSLog(@"about to request a capture from: %@", stillImageOutput);
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments)
         {
             // Do something with the attachments.
             NSLog(@"attachements: %@", exifAttachments);
         }
         else
             NSLog(@"no attachments");
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         if(isUsingFrontFacingCamera) {
             image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
         }
         self.photoView.image = image;
     }];
}

bool isUsingFrontFacingCamera = NO;
- (IBAction)switchCameras:(id)sender {
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera)
        desiredPosition = AVCaptureDevicePositionBack;
    else
        desiredPosition = AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [[captureVideoPreviewLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[captureVideoPreviewLayer session] inputs]) {
                [[captureVideoPreviewLayer session] removeInput:oldInput];
            }
            [[captureVideoPreviewLayer session] addInput:input];
            [[captureVideoPreviewLayer session] commitConfiguration];
            break;
        }
    }
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}
@end
