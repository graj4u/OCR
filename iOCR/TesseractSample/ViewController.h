//
//  ViewController.h
//  TesseractSample
//
//  Created by Ângelo Suzuki on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
//#import "JSON.h"
#include <math.h>

static inline double radians (double degrees) {return degrees * M_PI/180;}


@class MBProgressHUD;

namespace tesseract {
    class TessBaseAPI;
};

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIActionSheetDelegate>
{
    MBProgressHUD *progressHud;
    UIImagePickerController *imagePickerController;
    tesseract::TessBaseAPI *tesseract;
    uint32_t *pixels;
    UIActionSheet *popupQuery;
    NSString *dataPath ;
}

@property (nonatomic, strong) MBProgressHUD *progressHud;
@property (nonatomic, strong) IBOutlet UIImageView *imgView;
@property (nonatomic, strong) IBOutlet UITextView *txtView;

- (void)setTesseractImage:(UIImage *)image;
-(UIImage *)resizeImage:(UIImage *)image;

- (IBAction) findPhoto:(id) sender;
- (IBAction) takePhoto:(id) sender;

@end
