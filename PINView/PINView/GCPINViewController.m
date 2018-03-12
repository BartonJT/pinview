//
//  GCPINViewController.m
//  PINCode
//
//  Created by Caleb Davenport on 8/28/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//


#import "GCPINViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#define kGCPINViewControllerDelay 0.3

static int const PVFieldLength = 4;
static int const PVNumberOfTries = 4;
static int const PVPinFontSize = 20;

@interface GCPINViewController ()

// array of passcode entry labels
@property (copy, nonatomic) NSArray *labels;
@property (copy, nonatomic) NSArray *IDLabels;

// readwrite override for mode
@property (nonatomic, readwrite, assign) GCPINViewControllerMode mode;

// extra storage used when creating a passcode
@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSString *IDText;

// make the passcode entry labels match the input text
- (void)updatePasscodeDisplay;

// reset user input after a set delay
- (void)resetInput;

// signal that the passcode is incorrect
- (void)wrong;

// dismiss the view after a set delay
- (void)dismiss;

@property (readonly, assign) NSInteger numberWrongInputs;

@end

@implementation GCPINViewController

@synthesize tapMessage;
@synthesize fieldIDLabelOne;
@synthesize fieldIDLabelTwo;
@synthesize fieldIDLabelThree;
@synthesize fieldIDLabelFour;
@synthesize fieldOneLabel = __fieldOneLabel;
@synthesize fieldTwoLabel = __fieldTwoLabel;
@synthesize fieldThreeLabel = __fieldThreeLabel;
@synthesize fieldFourLabel = __fieldFourLabel;
@synthesize IDLabel;
@synthesize messageLabel = __messageLabel;
@synthesize errorLabel = __errorLabel;
@synthesize inputField = __inputField;
@synthesize IDField;
@synthesize IDView;
@synthesize PINView;
@synthesize messageText = __messageText;
@synthesize errorText = __errorText;
@synthesize labels = __labels;
@synthesize IDLabels;
@synthesize mode = __mode;
@synthesize text = __text;
@synthesize IDText;

@synthesize tap;
@synthesize selectIDTap;
@synthesize selectPINTap;
@synthesize delegate;
@synthesize backgroundColour = _backgroundColour;
@synthesize barColour = _barColour;
@synthesize fontColour = _fontColour;
@synthesize fillColour = _fillColour;
@synthesize numberWrongInputs;
@synthesize session;
@synthesize stillImageOutput;

@synthesize fieldImageOne;
@synthesize fieldImageTwo;
@synthesize fieldImageThree;
@synthesize fieldImageFour;

@synthesize IDFieldImageOne;
@synthesize IDFieldImageTwo;
@synthesize IDFieldImageThree;
@synthesize IDFieldImageFour;

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
        __dismiss = TRUE;
        
        self.tap = nil;
        self.selectIDTap = nil;
        self.selectPINTap = nil;
        self.delegate = nil;
        
        _backgroundColour = [[UIColor alloc] initWithRed:0.0
                                                   green:0.0
                                                    blue:0.0
                                                   alpha:0.8];
        
        _barColour = [[UIColor alloc] initWithRed:0.0
                                            green:0.0
                                             blue:0.0
                                            alpha:0.8];
        
        _fontColour = [[UIColor alloc] initWithRed:1.0
                                             green:1.0
                                              blue:1.0
                                             alpha:1.0];
        
        _fillColour = [[UIColor alloc] initWithRed:0.0
                                             green:0.0
                                              blue:0.0
                                             alpha:0.8];
        
        numberWrongInputs = 0;
        
        session = nil;
        stillImageOutput = nil;
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

    if (session.running)
    {
        [session stopRunning];
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


- (void)resetInput
{
    /*
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kGCPINViewControllerDelay * NSEC_PER_SEC);
    
    dispatch_after(time, dispatch_get_main_queue(), ^(void)
    {
     */
        [IDField setText:@""];
        self.inputField.text = @"";
//        [self updateIDDisplay];
//        [self updatePasscodeDisplay];
//        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
//    });
}

- (void)wrong
{
    if (numberWrongInputs < PVNumberOfTries)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        self.errorLabel.hidden = NO;
        self.text = nil;
        [self resetInput];
        
        [IDField becomeFirstResponder];
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Access Denied"
                                                                       message:@"You have entered an incorrect PIN five times."
                                                                                "Your image has been captured for identification."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {}];
        
        [alert addAction:alertAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)doubleTapped
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(PINViewCancelledByUser:)])
    {
        [self.delegate PINViewCancelledByUser:self];
    }
    
    [self dismiss];
}

- (void)dismiss
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    __dismiss = YES;
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kGCPINViewControllerDelay * NSEC_PER_SEC);
    
    dispatch_after(time, dispatch_get_main_queue(), ^(void)
    {
        [self dismissViewControllerAnimated:YES completion:^(void){}];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        numberWrongInputs = 0;
        
        // Tell the delegate that PINView has dismissed itself.
        if (delegate &&
            [delegate respondsToSelector:@selector(PINViewDidDismiss:)])
        {
            [delegate PINViewDidDismiss:self];
        }
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
                     fieldIDLabelFour];
    
    // setup labels
    self.messageLabel.text = self.messageText;
    self.errorLabel.text = self.errorText;
    self.errorLabel.hidden = YES;
    [self updatePasscodeDisplay];
    [self updateIDDisplay];
    
    // setup input field
//    self.inputField.hidden = YES;
    self.inputField.hidden = NO;
    self.inputField.font = [UIFont boldSystemFontOfSize:PVPinFontSize];
    self.inputField.textAlignment = NSTextAlignmentCenter;
    self.inputField.keyboardType = UIKeyboardTypeNumberPad;
    self.inputField.delegate = self;
    self.inputField.secureTextEntry = YES;
    self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    // Setup ID field.
//    [IDField setHidden:TRUE];
    [IDField setHidden:FALSE];
    [IDField setFont:[UIFont boldSystemFontOfSize:PVPinFontSize]];
    [IDField setTextAlignment:NSTextAlignmentCenter];
    [IDField setDelegate:self];
    [IDField setSecureTextEntry:FALSE];
    [IDField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [IDField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    
    // Setup Gesture Recognisers.
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped)];
    [tap setNumberOfTapsRequired:2];
    [tap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:tap];
    
    if (![tap respondsToSelector:@selector(locationInView:)])
    {
        [self setTap:nil];
    }
    
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
    
    [self setTheme];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tapMessage = nil;
    self.fieldOneLabel = nil;
    self.fieldTwoLabel = nil;
    self.fieldThreeLabel = nil;
    self.fieldFourLabel = nil;
    self.IDLabel = nil;
    self.messageLabel = nil;
    self.errorLabel = nil;
    self.inputField = nil;
    self.IDField = nil;
    [self setIDView:nil];
    [self setPINView:nil];
    self.labels = nil;
    [self setIDLabels:nil];
    
    self.text = nil;
    
    [self setTap:nil];
    [self setSelectIDTap:nil];
    [self setSelectPINTap:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [IDField setText:@""];
    [self.inputField setText:@""];
    
    [self updateIDDisplay];
    [self updatePasscodeDisplay];
    
    [IDField becomeFirstResponder];
    
    [self setTheme];
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
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.inputField ||
        textField == IDField)
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
    
    return TRUE;
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (textField == IDField)
    {
        [self.inputField becomeFirstResponder];
    }
    
    return TRUE;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return __dismiss;
}

#pragma mark - Theme Protocol -
- (void) setTheme
{
    [self updateBackground];
    [self updateFonts];
}

- (void) updateBackground
{
    [self.navigationController.navigationBar setTintColor:nil];
    [self.navigationController.navigationBar setTintColor:self.barColour];
    
    [self.view setBackgroundColor:self.backgroundColour];
}

- (void) updateFonts
{
    [tapMessage setTextColor:self.fontColour];
    [__messageLabel setTextColor:self.fontColour];
    [IDLabel setTextColor:self.fontColour];
}


@end
