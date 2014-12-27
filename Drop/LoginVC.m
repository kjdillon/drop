//
//  LoginVC.m
//  Drop
//
//  Created by Kyle Dillon on 12/17/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "LoginVC.h"
#import "SignUpVC.h"

@interface LoginVC ()

@end

@implementation LoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.spinner.hidden = YES;
    [self.spinner stopAnimating];
    
    self.loginButton.layer.cornerRadius = 10;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com"];
    if (ref.authData) {
        // Save Users unique identifier
        [[NSUserDefaults standardUserDefaults] setObject:ref.authData.uid forKey:@"UID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self performSegueWithIdentifier:@"fromSignIn" sender:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.emailTextField becomeFirstResponder];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    NSInteger nextTag = textField.tag + 1;
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

- (IBAction)loginButton:(id)sender {
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com"];
    [ref authUser:self.emailTextField.text password:self.passwordTextField.text withCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"Are you registered?"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            // Save Users unique identifier
            [[NSUserDefaults standardUserDefaults] setObject:ref.authData.uid forKey:@"UID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self performSegueWithIdentifier:@"fromSignIn" sender:self];
        }
        
        self.spinner.hidden = YES;
        [self.spinner stopAnimating];
    }];

}

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
