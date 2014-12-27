//
//  SignUpVC.m
//  Drop
//
//  Created by Kyle Dillon on 12/17/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "SignUpVC.h"
#import "MakeProfileVC.h"

@interface SignUpVC ()

@end

@implementation SignUpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    self.spinner.hidden = YES;
    [self.spinner stopAnimating];
    
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width/2;
    self.signUpButton.layer.cornerRadius = 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.usernameTextField becomeFirstResponder];
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

- (IBAction)cameraPressed:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    if(chosenImage != nil) {
        self.imageView.image = chosenImage;
        self.cameraButton.layer.opacity = 0.0;
    }
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


- (IBAction)signUpPressed:(id)sender {
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com"];
    [ref createUser:self.emailTextField.text password:self.passwordTextField.text withCompletionBlock:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"Could not create user."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
        } else {
            [self startSignUp];
        }
    }];
}

-(void)startSignUp{
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com"];
    [ref authUser:self.emailTextField.text password:self.passwordTextField.text withCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"Could not authenticate user."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
        } else {
            // Save Users unique identifier
            [[NSUserDefaults standardUserDefaults] setObject:authData.uid forKey:@"UID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self uploadUserProfilePhoto];
        }
    }];
}

-(void)uploadUserProfilePhoto {
    if([self.usernameTextField.text isEqual: @""] || [self.numberTextField.text isEqual: @""] || self.imageView.image == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                        message:@"Data entered is not valid."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        self.spinner.hidden = YES;
        [self.spinner stopAnimating];
    }
    
    // Upload the profile image
    NSData *imageData = UIImagePNGRepresentation(self.imageView.image);
    NSString *encodedString = [imageData base64Encoding];
    Firebase *photoTreeRef = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com/photos"];
    Firebase *photoRef = [photoTreeRef childByAutoId];
    [photoRef setValue: encodedString withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"Photo could not be uploaded."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
        } else {
            // Upload remaining data
            [self uploadUserData:photoRef.key];
        }
    }];
}

-(void)uploadUserData:(NSString*)profilePhotoKey {
    NSDictionary *userData = @{
                               @"username" : self.usernameTextField.text,
                               @"number": self.numberTextField.text,
                               @"photo_key": profilePhotoKey
                               };
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://dropdatabase.firebaseio.com/users"];
    NSString *UID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UID"];
    Firebase *usersRef = [ref childByAppendingPath: UID];
    [usersRef setValue:userData withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong :/"
                                                            message:@"User data could not be uploaded."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
        } else {
            self.spinner.hidden = YES;
            [self.spinner stopAnimating];
            
            [self performSegueWithIdentifier:@"fromSignUp" sender:self];
        }
    }];
}


- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
