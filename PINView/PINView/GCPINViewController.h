//
//  GCPINViewController.h
//  PINCode
//
//  Created by Caleb Davenport on 8/28/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>

#import <riOSUI/ThemeProtocol.h>
#import <riOSUI/UIView+ImprovedUI.h>
#import <riOSUI/UINavigationController+KeyboardDismiss.h>


typedef NS_ENUM(unsigned int, GCPINViewControllerMode)
{
    /*
     
     Create a new passcode. This allows the user to enter a new passcode then
     imediately verify it.
     
     */
    GCPINViewControllerModeCreate = 0,
    
    /*
     
     Verify a passcode. This allows the user to input a passcode then have it
     checked by the caller.
     
     */
    GCPINViewControllerModeVerify
    
};

/*
 
 This class defines a common passcode control that can be dropped into an app.
 It behaves exactly like the passcode screens that can be seen by going to
 Settings > General > Passcode Lock.
 
 */
@interface GCPINViewController : UIViewController <UITextFieldDelegate, ThemeProtocol>
{
    @private
        BOOL __dismiss;
}

/*
 
 Set the text to display text above the input area.
 
 */
@property (nonatomic, copy) NSString *messageText;

/*
 
 Set the text to display below the input area when the passcode fails
 verification.
 
 */
@property (nonatomic, copy) NSString *errorText;


/*
 
 Refer to `GCPINViewControllerMode`. This can only be set through the
 designated initializer.
 
 */
@property (nonatomic, readonly, assign) GCPINViewControllerMode mode;


/*
 
 Used to detect a tap in order to dismiss the view.
 
 */
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@property (nonatomic, strong) UITapGestureRecognizer *selectIDTap;
@property (nonatomic, strong) UITapGestureRecognizer *selectPINTap;

/*
 
 The delegate of GCPINViewController. This is easier than using the original
 block method.
 
 */
@property (nonatomic, weak) id delegate;

@property (nonatomic, copy) UIColor *backgroundColour;
@property (nonatomic, copy) UIColor *barColour;
@property (nonatomic, copy) UIColor *fontColour;
@property (nonatomic, copy) UIColor *fillColour;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;


/*
 
 Create a new passcode view controller providing the nib name, bundle, and
 desired mode. This is the designated initializer.
 
 */
- (instancetype)initWithNibName:(NSString *)nib bundle:(NSBundle *)bundle mode:(GCPINViewControllerMode)mode;

/*
 
 Present the receiver from the given view controller. This is a convenience
 method and wraps the receiver in a navigation controller before showing
 modally.
 
 */
- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated;

- (void) updateIDDisplay;

/*
 
 External declaration for internal method.
 
 */
- (void)resetInput;

// nib properties
@property (nonatomic, strong) IBOutlet UILabel *tapMessage;
@property (nonatomic, strong) IBOutlet UILabel *fieldIDLabelOne;
@property (nonatomic, strong) IBOutlet UILabel *fieldIDLabelTwo;
@property (nonatomic, strong) IBOutlet UILabel *fieldIDLabelThree;
@property (nonatomic, strong) IBOutlet UILabel *fieldIDLabelFour;
@property (nonatomic, strong) IBOutlet UILabel *fieldOneLabel;
@property (nonatomic, strong) IBOutlet UILabel *fieldTwoLabel;
@property (nonatomic, strong) IBOutlet UILabel *fieldThreeLabel;
@property (nonatomic, strong) IBOutlet UILabel *fieldFourLabel;
@property (nonatomic, strong) IBOutlet UILabel *IDLabel;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UILabel *errorLabel;
@property (nonatomic, strong) IBOutlet UITextField *inputField;
@property (nonatomic, strong) IBOutlet UITextField *IDField;
@property (nonatomic, strong) IBOutlet UIView *IDView;
@property (nonatomic, strong) IBOutlet UIView *PINView;
@property (nonatomic, strong) IBOutlet UIImageView *fieldImageOne;
@property (nonatomic, strong) IBOutlet UIImageView *fieldImageTwo;
@property (nonatomic, strong) IBOutlet UIImageView *fieldImageThree;
@property (nonatomic, strong) IBOutlet UIImageView *fieldImageFour;
@property (nonatomic, strong) IBOutlet UIImageView *IDFieldImageOne;
@property (nonatomic, strong) IBOutlet UIImageView *IDFieldImageTwo;
@property (nonatomic, strong) IBOutlet UIImageView *IDFieldImageThree;
@property (nonatomic, strong) IBOutlet UIImageView *IDFieldImageFour;

@end

@protocol GCPINViewDelegate <NSObject>

@optional
- (Boolean) PINView:(GCPINViewController *)aPINView verifyPIN:(NSString *)aPIN;
- (Boolean) PINView:(GCPINViewController *)aPINView verifyPIN:(NSString *)aPIN forUser:(NSString *)anUser;
- (void) PINViewCancelledByUser:(GCPINViewController *)aPINView;
- (void) PINViewDidDismiss:(GCPINViewController *)aPINView; // PV04

@end
