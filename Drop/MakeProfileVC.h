//
//  MakeProfileVC.h
//  Drop
//
//  Created by Kyle Dillon on 12/17/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>

@interface MakeProfileVC : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
- (IBAction)cameraPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
- (IBAction)finishPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property NSString *email;
@property NSString *password;

@end
