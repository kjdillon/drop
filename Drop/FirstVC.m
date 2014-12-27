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

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
