//
//  FirstVC.m
//  Drop
//
//  Created by Kyle Dillon on 12/18/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "FirstVC.h"

@interface FirstVC ()

@end

@implementation FirstVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.loginButton.layer.cornerRadius = 10;
    self.signupButton.layer.cornerRadius = 10;
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com"];
    if (ref.authData) {
        // Save Users unique identifier
        [[NSUserDefaults standardUserDefaults] setObject:ref.authData.uid forKey:@"UID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self performSegueWithIdentifier:@"fromFirst" sender:self];
    }
    
}

-(void)viewDidAppear:(BOOL)animated {
    [self startDropAnimation];
}

#define O_BOB_HEIGHT 10
-(void)startDropAnimation {
    [self bobLogoUp];
}

-(void)bobLogoUp {
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0, -O_BOB_HEIGHT);
    [UIView animateWithDuration:2.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.OLogoImageView.transform = translate;
                     }completion:^(BOOL finished){
                         [self bobLogoDown];
                     }];
}

-(void)bobLogoDown {
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0, O_BOB_HEIGHT);
    [UIView animateWithDuration:2.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.OLogoImageView.transform = translate;
                     }completion:^(BOOL finished){
                         [self bobLogoUp];
                     }];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
