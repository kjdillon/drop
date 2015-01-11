//
//  FirstVC.h
//  Drop
//
//  Created by Kyle Dillon on 12/18/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>

@interface FirstVC : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIImageView *DropLogoImageView;

@property (weak, nonatomic) IBOutlet UIImageView *OLogoImageView;
@end
