//
//  LoginVC.h
//  Drop
//
//  Created by Kyle Dillon on 12/17/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>

@interface LoginVC : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
- (IBAction)loginButton:(id)sender;
- (IBAction)notRegisteredPressed:(id)sender;

- (IBAction)backPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end
