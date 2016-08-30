//
//  GCPINViewController.m
//  PINCode
//
//  Created by Caleb Davenport on 8/28/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//
//  __________________________________________________________________________________________________________________________
//
//  Modificaiton Log:
//
//  Number:  Date:       Programmer:		Description:
//  =======  ==========  =================  ==================================================================================
//  PV01     06/11/2012  Barton Tsikrikas	Adding in a user ID field to allow for verification of the PIN against the user's
//											ID.
//
//  PV02     07/11/2012  Barton Tsikrikas	Fixed behaviour of theme code, needed additional calls.
//
//  PV03     07/11/2012  Barton Tsikrikas	In order to allow for the use of multiple of text fields the value of |_dismiss|
//											has been changed so it is always TRUE. This way when a textfield requests to
//											resign its first responder status it will be permitted.
//
//  PV04     07/11/2012  Barton Tsikrikas	Created new delegate method PINViewDidDismiss: that way the delegate can perform
//											any specific actions after the view has been dismissed.
//
//  PV05     07/11/2012  Barton Tsikrikas	Improved the update calls that way the labels always match the text of their
//											UITextFields.
//
//  PV06     07/11/2012  Barton Tsikrikas	Added the ability to capture an image of an individual who has entered the
//											PIN number wrong for a set number of times, NUMBERTIES.
//
//  PV07     07/11/2102  Barton Tsikrikas	Now just use standard text fields. Left all of the original code so it can
//											be easily reverted if desired.
//
//	PV08	 22/09/2014	 Barton Tsikrikas	Added new method double-tapped and delegate method PINViewCancelledByUser: to
//											notify the parent view controller when a PINView has been dismissed by the user.
//											Updated nibs for iOS 8.
//  __________________________________________________________________________________________________________________________


#import "GCPINViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#define kGCPINViewControllerDelay 0.3

static int const PVFieldLength = 4; // PV01
static int const PVNumberOfTries = 4; // PV06
static int const PVPinFontSize = 20; // PV07

@interface GCPINViewController ()

// array of passcode entry labels
@property (copy, nonatomic) NSArray *labels;
@property (copy, nonatomic) NSArray *IDLabels; // PV01

// readwrite override for mode
@property (nonatomic, readwrite, assign) GCPINViewControllerMode mode;

// extra storage used when creating a passcode
@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSString *IDText; // PV01

// make the passcode entry labels match the input text
- (void)updatePasscodeDisplay;

// reset user input after a set delay
- (void)resetInput;

// signal that the passcode is incorrect
- (void)wrong;

// dismiss the view after a set delay
- (void)dismiss;

@property (readonly, assign) NSInteger numberWrongInputs; // PV06

@end

@implementation GCPINViewController

@synthesize tapMessage;
@synthesize fieldIDLabelOne; // PV01
@synthesize fieldIDLabelTwo; // PV01
@synthesize fieldIDLabelThree; // PV01
@synthesize fieldIDLabelFour; // PV01
@synthesize fieldOneLabel = __fieldOneLabel;
@synthesize fieldTwoLabel = __fieldTwoLabel;
@synthesize fieldThreeLabel = __fieldThreeLabel;
@synthesize fieldFourLabel = __fieldFourLabel;
@synthesize IDLabel;    // PV01    
@synthesize messageLabel = __messageLabel;
@synthesize errorLabel = __errorLabel;
@synthesize inputField = __inputField;
@synthesize IDField;    // PV01
@synthesize IDView; // PV01
@synthesize PINView;// PV01
@synthesize messageText = __messageText;
@synthesize errorText = __errorText;
@synthesize labels = __labels;
@synthesize IDLabels; // PV01
@synthesize mode = __mode;
@synthesize text = __text;
@synthesize IDText; // PV01

@synthesize tap;
@synthesize selectIDTap;  // PV01
@synthesize selectPINTap; // PV01
@synthesize delegate;
@synthesize backgroundColour;
@synthesize barColour;
@synthesize fontColour;
@synthesize fillColour;
@synthesize numberWrongInputs; // PV06
@synthesize session;           // PV06
@synthesize stillImageOutput;  // PV06

// PV07 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV07 //
@synthesize fieldImageOne;
@synthesize fieldImageTwo;
@synthesize fieldImageThree;
@synthesize fieldImageFour;

@synthesize IDFieldImageOne;
@synthesize IDFieldImageTwo;
@synthesize IDFieldImageThree;
@synthesize IDFieldImageFour;
// PV07 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV07 //

#pragma mark - object methods -

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [self initWithNibName:nibNameOrNil
						  bundle:nibBundleOrNil
							mode:GCPINViewControllerModeVerify];
	
	return self;
}

- (instancetype)initWithNibName:(NSString *)nib bundle:(NSBundle *)bundle mode:(GCPINViewControllerMode)mode
{
    NSAssert(mode == GCPINViewControllerModeCreate ||
             mode == GCPINViewControllerModeVerify,
             @"Invalid passcode mode");
    
	if (self = [super initWithNibName:nib bundle:bundle])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChange:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:nil];
        
        self.mode = mode;
        __dismiss = TRUE; // PV03
        
        self.tap = nil;
        self.selectIDTap = nil; // PV01
        self.selectPINTap = nil; // PV01
        self.delegate = nil;
        
        backgroundColour = [[UIColor alloc] initWithRed:0.0
                                                  green:0.0
                                                   blue:0.0
                                                  alpha:0.8];
        
        barColour = [[UIColor alloc] initWithRed:0.0
                                           green:0.0
                                            blue:0.0
                                           alpha:0.8];
        
        fontColour = [[UIColor alloc] initWithRed:1.0
                                            green:1.0
                                             blue:1.0
                                            alpha:1.0];
        
        fillColour = [[UIColor alloc] initWithRed:0.0
                                            green:0.0
                                             blue:0.0
                                            alpha:0.8];
        
        numberWrongInputs = 0;  // PV06
        
        session = nil;          // PV06
        stillImageOutput = nil; // PV06
	}
    
	return self;
}

- (void)dealloc
{
    delegate = nil;
    
    // clear notifs
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:nil];
    
    // clear properties
    self.messageText = nil;
    self.errorText = nil;

	if (session.running) // PV06
    {
        [session stopRunning]; // PV06
    }
}

- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
	[controller presentViewController:navController animated:animated completion:^(void){}];
}

- (BOOL) disablesAutomaticKeyboardDismissal
{
    return NO;
}

- (void)updatePasscodeDisplay
{
    NSUInteger length = [self.inputField.text length];
    
    for (NSUInteger i = 0; i < PVFieldLength; i++)
    {
        UILabel *label = self.labels[i];
        
        if (i < length)
        {
            [label setText:@"●"];
        }
        else
        {
            [label setText:@""];
        }
    }
}

// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //
- (void) updateIDDisplay
{
    NSUInteger length = [IDField.text length];
    
    for (int i = 0; i < PVFieldLength; i++)
    {
        UILabel *label = IDLabels[i];
        
        if (i < length)
        {
            NSRange range = {i, 1};
            NSString *labelText = [IDField.text substringWithRange:range];
            [label setText:labelText];
        }
        else
        {
            [label setText:@""];
        }
    }
}
// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //

- (void)resetInput
{
    /*
     // PV07
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kGCPINViewControllerDelay * NSEC_PER_SEC);
    
    dispatch_after(time, dispatch_get_main_queue(), ^(void)
    {
     */
        [IDField setText:@""]; // PV01
        self.inputField.text = @"";
//        [self updateIDDisplay]; // PV05 // PV07
//        [self updatePasscodeDisplay]; // PV05 // PV07
//        [[UIApplication sharedApplication] endIgnoringInteractionEvents]; // PV07
//    }); // PV07
}

- (void)wrong
{
// PV06 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV06 //
    if (numberWrongInputs < PVNumberOfTries)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        self.errorLabel.hidden = NO;
        self.text = nil;
        [self resetInput];
        
        [IDField becomeFirstResponder]; // PV05
        numberWrongInputs++;
    }
    // Take picture of the 'hacker'.
    else
    {
        // Setup capture session.
        if (session)
        {
            [self setSession:nil];
        }
        session = [[AVCaptureSession alloc] init];
        
        // Sort through the devices looking for the front camera.
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        AVCaptureDevice *frontCamera = nil;
        
        for (AVCaptureDevice *aDevice in devices)
        {
            if ([aDevice position] == AVCaptureDevicePositionFront)
            {
                frontCamera = aDevice;
            }
        }
        
        // Check for an input feed from the device.
        NSError *inputError;
        
        AVCaptureDeviceInput *frontCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera
                                                                                       error:&inputError];
        
        if (inputError)
        {
            [self dismiss];
            
            return;
        }
        
        // Add the device and input to the session.
        if ([session canSetSessionPreset:AVCaptureSessionPresetPhoto])
        {
            [session setSessionPreset:AVCaptureSessionPresetPhoto];
        }
        
        if ([session canAddInput:frontCameraInput])
        {
            [session addInput:frontCameraInput];
        }
        
        // Check for an output feed from the device/session.
        if (stillImageOutput)
        {
            [self setStillImageOutput:nil];
        }

        stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = @{ AVVideoCodecJPEG: AVVideoCodecKey};
        [stillImageOutput setOutputSettings:outputSettings];
        
        if ([session canAddOutput:stillImageOutput])
        {
            [session addOutput:stillImageOutput];
        }
        
        [session startRunning];
        
        // Check for a video connection from the device that can be used.
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
            
            if (videoConnection)
            {
                break;
            }
        }
        
        // Perform the capture.
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
         
         ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
        {
            /*
            CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
            if (exifAttachments)
            {
                // Do something with the attachments.
                NSLog(@"attachements: %@", exifAttachments);
            }
            else
            {
                NSLog(@"no attachments");
            }
             */
            
            // Save the captured image.
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            
            if (image)
            {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }
        }];

        
        [self dismiss];
        
        // Warn the user what has happened.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied!"
                                                        message:@"You have entered an incorrect PIN five times."
                                                                 "Your image has been captured for identification."
                                                       delegate:self
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
// PV06 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV06 //
}

// PV08 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV08 //
- (void)doubleTapped
{
	if (self.delegate &&
		[self.delegate respondsToSelector:@selector(PINViewCancelledByUser:)])
	{
		[self.delegate PINViewCancelledByUser:self];
	}
	
	[self dismiss];
}
// PV08 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV08 //

- (void)dismiss
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    __dismiss = YES;
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kGCPINViewControllerDelay * NSEC_PER_SEC);
    
    dispatch_after(time, dispatch_get_main_queue(), ^(void)
    {
		[self dismissViewControllerAnimated:YES completion:^(void){}];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        numberWrongInputs = 0; // PV06
        
// PV04 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV04 //
        // Tell the delegate that PINView has dismissed itself.
        if (delegate &&
            [delegate respondsToSelector:@selector(PINViewDidDismiss:)])
        {
            [delegate PINViewDidDismiss:self];
        }
// PV04 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV04 //
    });
}

#pragma mark - view lifecycle -
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	
	NSString *currentSystemVersion = [[UIDevice currentDevice] systemVersion];
	NSComparisonResult result = [currentSystemVersion compare:@"7.0" options:NSNumericSearch];
	
	if (result == NSOrderedDescending ||
		result == NSOrderedSame)
	{
		[self setEdgesForExtendedLayout:UIRectEdgeNone];
	}
	
	
    // setup labels list
    self.labels = @[self.fieldOneLabel,
                   self.fieldTwoLabel,
                   self.fieldThreeLabel,
                   self.fieldFourLabel];
    
    self.IDLabels = @[fieldIDLabelOne,
                     fieldIDLabelTwo,
                     fieldIDLabelThree,
                     fieldIDLabelFour]; // PV01
    
    // setup labels
    self.messageLabel.text = self.messageText;
    self.errorLabel.text = self.errorText;
    self.errorLabel.hidden = YES;
	[self updatePasscodeDisplay];
    [self updateIDDisplay]; // PV01
    
	// setup input field
//    self.inputField.hidden = YES; // PV07
    self.inputField.hidden = NO; // PV07
    self.inputField.font = [UIFont boldSystemFontOfSize:PVPinFontSize]; // PV07
    self.inputField.textAlignment = NSTextAlignmentCenter; // PV07
    self.inputField.keyboardType = UIKeyboardTypeNumberPad;
    self.inputField.delegate = self;
    self.inputField.secureTextEntry = YES;
    self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    // Setup ID field.
//    [IDField setHidden:TRUE]; // PV07
    [IDField setHidden:FALSE]; // PV07
    [IDField setFont:[UIFont boldSystemFontOfSize:PVPinFontSize]]; // PV07
    [IDField setTextAlignment:NSTextAlignmentCenter]; // PV07
    [IDField setDelegate:self];
    [IDField setSecureTextEntry:FALSE];
    [IDField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [IDField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    
    // Setup Gesture Recognisers.
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped)];
    [tap setNumberOfTapsRequired:2]; // PV01
    [tap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:tap];
    
    if (![tap respondsToSelector:@selector(locationInView:)])
    {
        [self setTap:nil];
    }
    
// PV07 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV07 //
    // Hide unnecessary views.
    for (UILabel *label in self.labels)
    {
        [label setHidden:TRUE];
    }
    
    for (UILabel *label in IDLabels)
    {
        [label setHidden:TRUE];
    }
    
    [fieldImageOne setHidden:TRUE];
    [fieldImageTwo setHidden:TRUE];
    [fieldImageThree setHidden:TRUE];
    [fieldImageFour setHidden:TRUE];
    
    [IDFieldImageOne setHidden:TRUE];
    [IDFieldImageTwo setHidden:TRUE];
    [IDFieldImageThree setHidden:TRUE];
    [IDFieldImageFour setHidden:TRUE];
// PV07 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV07 //
    
// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //
    selectIDTap = [[UITapGestureRecognizer alloc] initWithTarget:IDField action:@selector(becomeFirstResponder)];
    [selectIDTap setNumberOfTapsRequired:1];
    [selectIDTap setNumberOfTouchesRequired:1];
    [selectIDTap requireGestureRecognizerToFail:tap];
    //[IDView addGestureRecognizer:selectIDTap];
    
    if (![selectIDTap respondsToSelector:@selector(locationInView:)])
    {
        [self setSelectIDTap:nil];
    }
    
    selectPINTap = [[UITapGestureRecognizer alloc] initWithTarget:self.inputField action:@selector(becomeFirstResponder)];
    [selectPINTap setNumberOfTapsRequired:1];
    [selectPINTap setNumberOfTouchesRequired:1];
    [selectPINTap requireGestureRecognizerToFail:tap];
    //[PINView addGestureRecognizer:selectPINTap];
    
    if (![selectPINTap respondsToSelector:@selector(locationInView:)])
    {
        [self setSelectPINTap:nil];
    }
// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //
	
    [self setTheme]; // PV02
}

- (void)viewDidUnload
{
	[super viewDidUnload];
    self.tapMessage = nil;
	self.fieldOneLabel = nil;
    self.fieldTwoLabel = nil;
    self.fieldThreeLabel = nil;
    self.fieldFourLabel = nil;
    self.IDLabel = nil; // PV01
    self.messageLabel = nil;
    self.errorLabel = nil;
    self.inputField = nil;
    self.IDField = nil; // PV01
    [self setIDView:nil]; // PV01
    [self setPINView:nil]; // PV01
    self.labels = nil;
    [self setIDLabels:nil]; // PV01
    
    self.text = nil;
    
    [self setTap:nil]; // PV01
    [self setSelectIDTap:nil]; // PV01
    [self setSelectPINTap:nil]; // PV01
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [IDField setText:@""];
    [self.inputField setText:@""];
    
    [self updateIDDisplay];
    [self updatePasscodeDisplay];
    
    [IDField becomeFirstResponder]; // PV01
    
    [self refreshTheme];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return TRUE;
    }
    else
    {
        return (orientation == UIInterfaceOrientationPortrait);
    }
}

#pragma mark - overridden property accessors -
- (void)setMessageText:(NSString *)text
{
    __messageText = [text copy];
    self.messageLabel.text = __messageText;
}

- (void)setErrorText:(NSString *)text
{
    __errorText = [text copy];
    self.errorLabel.text = __errorText;
}

#pragma mark - text field methods -
- (void)textDidChange:(NSNotification *)notif
{
    if ([notif object] == self.inputField)
    {
        [self updatePasscodeDisplay];
        
        if ([self.inputField.text length] == PVFieldLength)
        {
            if (self.mode == GCPINViewControllerModeCreate)
            {
                if ([self.text isEqualToString:@""])
                {
                    self.text = self.inputField.text;
                    [self resetInput];
                }
                else
                {
                    Boolean authorised = FALSE;
                    
                    if (delegate &&
                        [delegate respondsToSelector:@selector(PINView:verifyPIN:forUser:)])
                    {
                        authorised = [delegate PINView:self
                                             verifyPIN:self.inputField.text
                                               forUser:IDField.text];
                    }
                    
                    if ([self.text isEqualToString:self.inputField.text] &&
                        authorised)
                    {
                        [self dismiss];
                    }
                    else
                    {
                        [self wrong];
                    }
                }
            }
            else if (self.mode == GCPINViewControllerModeVerify)
            {
                Boolean authorised = FALSE;
                
                if (delegate &&
                    [delegate respondsToSelector:@selector(PINView:verifyPIN:forUser:)])
                {
                    authorised = [delegate PINView:self
                                         verifyPIN:self.inputField.text
                                           forUser:IDField.text];
                }
                
                if (authorised)
                {
                    [self dismiss];
                }
                else
                {
                    [self wrong];
                }
            }
        }
    }
// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //
    else if ([notif object] == IDField)
    {
        [self updateIDDisplay];
        
        [self setIDText:IDField.text];
        
        if ([IDField.text length] == PVFieldLength)
        {
            [IDField resignFirstResponder];
            
            [self.inputField becomeFirstResponder];
            
        }
    }
// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.inputField ||
        textField == IDField) // #PV 01
    {
        if ([textField.text length] == PVFieldLength && [string length] > 0)
        {
            return NO;
        }
        else
        {
            self.errorLabel.hidden = YES;
            return YES;
        }
    }
    
    return TRUE; // PV01
}

// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (textField == IDField)
    {
        [self.inputField becomeFirstResponder];
    }
    
    return TRUE;
}
// PV01 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PV01 //

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return __dismiss;
}

#pragma mark - Theme Protocol -
- (void) setTheme
{
    [self.navigationController.navigationBar setTintColor:nil];
    [self.navigationController.navigationBar setTintColor:barColour];

    // Apply Background Colour.
    //[self.view applyShinyBackgroundWithColour:backgroundColour];
    [self.view setBackgroundColor:backgroundColour];
    
    [self updateFonts];
}

- (void) refreshTheme
{
    [self updateBackground];
    [self updateFonts];
}

- (void) updateBackground
{
    [self.navigationController.navigationBar setTintColor:nil];
    [self.navigationController.navigationBar setTintColor:barColour];
    
    //[self.view updateShinyBackgroundWithColour:backgroundColour]; // PV02
    [self.view setBackgroundColor:backgroundColour];
}

- (void) updateFonts
{
    [tapMessage setTextColor:fontColour];
    [__messageLabel setTextColor:fontColour];
    [IDLabel setTextColor:fontColour]; // #PV
    
    /*
    NSDictionary *fontAttributes = [NSDictionary dictionaryWithObject:fontColour
                                                               forKey:UITextAttributeTextColor];
    [self.navigationController.navigationBar setTitleTextAttributes:fontAttributes];
     */
}

- (void) updateThemeColours:(UIColor *)aBackgroundColour fontColour:(UIColor *)aFontColour
{
    [self setBackgroundColour:nil];
    [self setBackgroundColour:aBackgroundColour];
    
    [self setFontColour:nil];
    [self setFontColour:aFontColour];
    
    [self setFillColour:nil];
    [self setFillColour:aBackgroundColour];
    
    [self setBarColour:nil];
    [self setBarColour:aBackgroundColour];
}


- (void) setBackgroundColour:(UIColor *)aBackgroundColour
                  fillColour:(UIColor *)aFillColour
                  fontColour:(UIColor *)aFontColour
                   barColour:(UIColor *)aBarColour
{
    [self setBackgroundColour:nil];
    [self setBackgroundColour:aBackgroundColour];
    
    [self setBarColour:nil];
    [self setBarColour:aBarColour];
    
    [self setFontColour:nil];
    [self setFontColour:aFontColour];
    
    [self setFillColour:nil];
    [self setFillColour:aFillColour];
}


@end
