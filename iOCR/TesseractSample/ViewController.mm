//
//  ViewController.m
//  TesseractSample
//
//  Created by Ângelo Suzuki on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "MBProgressHUD.h"

#include "baseapi.h"

#include "environ.h"
#import "pix.h"

@implementation ViewController

@synthesize progressHud,imgView,txtView;
//@synthesize choosePictureViewController;

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Set up the tessdata path. This is included in the application bundle
        // but is copied to the Documents directory on the first run.
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
        
        dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // If the expected store doesn't exist, copy the default store.
        if (![fileManager fileExistsAtPath:dataPath]) {
            // get the path to the app bundle (with the tessdata dir)
            NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
            NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
            if (tessdataPath) {
                [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
            }
        }
        
        setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);
        
        // init the tesseract engine.
        tesseract = new tesseract::TessBaseAPI();
        //tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng");
    }
    return self;
}

- (void)dealloc
{
    delete tesseract;
    tesseract = nil;
}

#pragma -
#pragma Image Picker Delegate

-(void)imagePickerController:
(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Code here to work with media
    [self dismissModalViewControllerAnimated:YES];
    UIImage *imagee = [info objectForKey:UIImagePickerControllerOriginalImage];
    imgView.image = [self resizeImage:imagee];
    
    self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
    self.progressHud.labelText = @"Processing OCR";
    
    [self.view addSubview:self.progressHud];
    [self.progressHud showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:imagee animated:YES];
}

-(void)imagePickerControllerDidCancel:
(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark IBAction
- (IBAction) takePhoto:(id) sender
{
    //[_ocrTextView resignFirstResponder];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType =  UIImagePickerControllerSourceTypeCamera;
        [imagePickerController setAllowsEditing:YES];
        
        [self presentModalViewController:imagePickerController animated:YES];
        
        //[imagePickerController release];
    }
}
- (IBAction) findPhoto:(id) sender
{
    //[_ocrTextView resignFirstResponder];
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    [imagePickerController setAllowsEditing:YES];
	
	[self presentModalViewController:imagePickerController animated:YES];
    
    //[imagePickerController release];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    /*
     UIImage *imagee = [UIImage imageNamed:@"english_alphabet.gif"];
     imgView.image = imagee;
     self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
     self.progressHud.labelText = @"Processing OCR";
     [self.view addSubview:self.progressHud];
     [self.progressHud showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:imagee animated:YES];
     */
    /*
     popupQuery = [[UIActionSheet alloc] initWithTitle:@"Select Language to Convert" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"English" otherButtonTitles:@"French", nil];
     popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
     [popupQuery showInView:self.view];
     */
    
    tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng");
    self.txtView.text=@"";
    self.txtView.textAlignment=UITextAlignmentCenter;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    if (![self.progressHud isHidden])
        [self.progressHud hide:NO];
    self.progressHud = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)processOcrAt:(UIImage *)image
{
    [self setTesseractImage:image];
    
    tesseract->Recognize(NULL);
    char* utf8Text = tesseract->GetUTF8Text();
    
    [self performSelectorOnMainThread:@selector(ocrProcessingFinished:)
                           withObject:[NSString stringWithUTF8String:utf8Text]
                        waitUntilDone:NO];
}


- (void)ocrProcessingFinished:(NSString *)result
{
    /*[[[UIAlertView alloc] initWithTitle:@"Tesseract Sample"
     message:[NSString stringWithFormat:@"Recognized:\n%@", result]
     delegate:nil
     cancelButtonTitle:nil
     otherButtonTitles:@"OK", nil] show];*/
    self.txtView.textAlignment=UITextAlignmentLeft;
    self.txtView.text=[NSString stringWithFormat:@"Recognized:\n%@", result];
}

- (void)setTesseractImage:(UIImage *)image
{
    free(pixels);
    
    CGSize size = [image size];
    int width = size.width;
    int height = size.height;
	
	if (width <= 0 || height <= 0)
		return;
	
    // the pixels will be painted to this array
    pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// we're done with the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
}

#pragma - Image Manupaltion

-(UIImage *)resizeImage:(UIImage *)image {
	
	CGImageRef imageRef = [image CGImage];
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
	CGColorSpaceRef colorSpaceInfo = CGColorSpaceCreateDeviceRGB();
	
	if (alphaInfo == kCGImageAlphaNone)
		alphaInfo = kCGImageAlphaNoneSkipLast;
	
	int width, height;
	
	width = 308;//[image size].width;
	height = 210;//[image size].height;
	
	CGContextRef bitmap;
	
	if (image.imageOrientation == UIImageOrientationUp | image.imageOrientation == UIImageOrientationDown)
	{
		bitmap = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
		
	} else {
		bitmap = CGBitmapContextCreate(NULL, height, width, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
		
	}
	
	if (image.imageOrientation == UIImageOrientationLeft) {
		NSLog(@"image orientation left");
		CGContextRotateCTM (bitmap, radians(90));
		CGContextTranslateCTM (bitmap, 0, -height);
		
	} else if (image.imageOrientation == UIImageOrientationRight) {
		NSLog(@"image orientation right");
		CGContextRotateCTM (bitmap, radians(-90));
		CGContextTranslateCTM (bitmap, -width, 0);
		
	} else if (image.imageOrientation == UIImageOrientationUp) {
		NSLog(@"image orientation up");
		
	} else if (image.imageOrientation == UIImageOrientationDown) {
		NSLog(@"image orientation down");
		CGContextTranslateCTM (bitmap, width,height);
		CGContextRotateCTM (bitmap, radians(-180.));
		
	}
	
	CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage *result = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);
	CGImageRelease(ref);
	
	return result;
}

#pragma -
#pragma Unused Methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0)
    {
		tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng");
        self.txtView.text=@"English Language is Selected";
        self.txtView.textAlignment=UITextAlignmentCenter;
	}
    else if (buttonIndex == 1)
    {
		tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "fra");
        self.txtView.text=@"French Language is Selected";
        self.txtView.textAlignment=UITextAlignmentCenter;
	}
    else if (buttonIndex == 2) {
	}
    else if (buttonIndex == 3) {
	}
}

@end
