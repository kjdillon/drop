//
//  SignUpVC.h
//  Drop
//
//  Created by Kyle Dillon on 12/17/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>

@interface SignUpVC : UIViewController  <UITextFieldDelegate>

- (IBAction)backPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
- (IBAction)cameraPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

- (IBAction)signUpPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end
