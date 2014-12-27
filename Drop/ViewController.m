//
//  ViewController.m
//  Drop
//
//  Created by Kyle Dillon on 12/12/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "ViewController.h"
#include <MobileCoreServices/MobileCoreServices.h>
#include <CoreVideo/CoreVideo.h>
#include <CoreMedia/CoreMedia.h>
#include <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupGestures];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupCameraView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
