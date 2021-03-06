//
//
// Copyright 2013 Kii Corporation
// http://kii.com
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//

#import "FeedViewController.h"

#import <KiiSDK/Kii.h>
#import <KiiSDK/KiiServerCodeExecResult.h>

#import "AppDelegate.h"
#import "KiiToolkit.h"

#define PADDING     20

@interface FeedViewController()

- (void) drawPost:(NSString*)uuid
     withUsername:(NSString*)username
          andTime:(NSString*)created
       andMessage:(NSString*)message
         andImage:(UIImage*)img;

@end

@implementation FeedViewController

- (IBAction) takePhoto:(id)sender
{
    if([KiiUser loggedIn]) {
        
        BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
        
        int cancelIndex = hasCamera ? 2 : 1;
        
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        sheet.title = @"Choose Source";
        sheet.delegate = self;
        sheet.cancelButtonIndex = cancelIndex;
        
        if(hasCamera) {
            [sheet addButtonWithTitle:@"Camera"];
        }
        
        [sheet addButtonWithTitle:@"Gallery"];
        [sheet addButtonWithTitle:@"Cancel"];
        
        [sheet showFromTabBar:self.tabBarController.tabBar];
    } else {
        [KTAlert showAlert:KTAlertTypeToast
               withMessage:@"Log in to post pictures!"
               andDuration:KTAlertDurationLong];
    }
}

- (void) cancelMessage:(id)sender
{
    // change the buttons
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                           target:self
                                                                           action:@selector(composeMessage:)];

    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                          target:self
                                                                          action:@selector(takePhoto:)];
    [_navItem setRightBarButtonItem:right];
    [_navItem setLeftBarButtonItem:left];

    _navItem.title = @"Live Feed";
    _composeView.text = @"";
    _composeView.hidden = TRUE;
    
    [_composeView resignFirstResponder];
}

- (void) postMessage:(id)sender
{
    [KTLoader showLoader:@"Posting..."];
    
    KiiUser *user = [KiiUser userWithUsername:@"demo" andPassword:@"password"];
    [user performRegistrationWithBlock:^(KiiUser *user, NSError *error) {
        if(error) {
            
        }
    }];
    
    KiiObject *obj = [[Kii bucketWithName:BUCKET_FEED] createObject];
    [obj setObject:[KiiUser currentUser].username forKey:@"username"];
    [obj setObject:_composeView.text forKey:@"message"];
    [obj setObject:@"text" forKey:@"message_type"];
    [obj saveWithBlock:^(KiiObject *object, NSError *error) {
        if(error == nil) {
            [KTLoader showLoader:@"Posted!"
                        animated:TRUE
                   withIndicator:KTLoaderIndicatorSuccess
                 andHideInterval:KTLoaderDurationAuto];
            
            // and show it in the UI
            [self drawPost:object.uuid
              withUsername:[KiiUser currentUser].username
                   andTime:@"Just Now"
                andMessage:[object getObjectForKey:@"message"]
                  andImage:nil];
            
        } else {
            [KTLoader showLoader:@"Error!"
                        animated:TRUE
                   withIndicator:KTLoaderIndicatorError
                 andHideInterval:KTLoaderDurationAuto];
        }
    }];
    
    [self cancelMessage:sender];
}

- (IBAction) composeMessage:(id)sender
{
    if([KiiUser loggedIn]) {
        
        // show the compose view
        _composeView.hidden = FALSE;
        [_composeView becomeFirstResponder];
        
        // change the buttons
        UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(postMessage:)];
        
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(cancelMessage:)];
        
        [_navItem setRightBarButtonItem:right];
        [_navItem setLeftBarButtonItem:left];
        
        [_navItem setTitle:@"Create a Post"];

    } else {        
        [KTAlert showAlert:KTAlertTypeToast
               withMessage:@"Log in to start posting!"
               andDuration:KTAlertDurationLong];
    }

}

- (void) drawPost:(NSString*)uri
     withUsername:(NSString*)username
          andTime:(NSString*)created
       andMessage:(NSString*)message
         andImage:(UIImage*)img
{

    CGFloat totalHeight = 0;
    __block UIImageView *imageView = nil;
    UILabel *messageLabel = nil;
    
    // build this view
    UILabel *usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, 320-2*PADDING, 18)];
    usernameLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    usernameLabel.backgroundColor = [UIColor clearColor];
    usernameLabel.text = username;
    
    totalHeight += usernameLabel.frame.size.height;
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, usernameLabel.frame.origin.y + usernameLabel.frame.size.height, 320-2*PADDING, 14)];
    timeLabel.font = [UIFont systemFontOfSize:12.0f];
    timeLabel.textColor = [UIColor grayColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.text = created;
    
    totalHeight += timeLabel.frame.size.height;
    
    // if it's text
    if(message != nil) {
        
        messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, timeLabel.frame.origin.y + timeLabel.frame.size.height + 4, 320-2*PADDING, 14)];
        messageLabel.font = [UIFont systemFontOfSize:14.0f];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.text = message;
        messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        messageLabel.numberOfLines = 100;
        
        //Calculate the expected size based on the font and linebreak mode of your label
        CGSize maximumLabelSize = CGSizeMake(messageLabel.frame.size.width, FLT_MAX);
        CGSize expectedLabelSize = [messageLabel.text sizeWithFont:messageLabel.font constrainedToSize:maximumLabelSize lineBreakMode:messageLabel.lineBreakMode];
        
        //adjust the label the the new height.
        CGRect newFrame = messageLabel.frame;
        newFrame.size.height = expectedLabelSize.height;
        messageLabel.frame = newFrame;
        
        totalHeight += messageLabel.frame.size.height;
    }
    
    // otherwise it's an image
    else {
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(PADDING, timeLabel.frame.origin.y + timeLabel.frame.size.height + 4, 320-2*PADDING, 320-2*PADDING)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.backgroundColor = [UIColor lightGrayColor];
        imageView.clipsToBounds = TRUE;
        
        if(img != nil) {
            imageView.image = img;
        } else if(uri != nil) {
            
            KiiObject *object = [KiiObject objectWithURI:uri];
            
            // Create a KiiDownloader.
            __block NSString *downloadFilePath = [[AppDelegate applicationDocumentsDirectory] stringByAppendingPathComponent:object.uuid];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:downloadFilePath]) {
                UIImage *img = [UIImage imageWithContentsOfFile:downloadFilePath];
                imageView.image = img; //[UIImage imageWithContentsOfFile:downloadFilePath];
            }
            
            // otherwise, download
            else {

                __block UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                av.center = CGPointMake(imageView.frame.size.width/2, imageView.frame.size.height/2);
                [imageView addSubview:av];
                [av startAnimating];

                KiiDownloader *downloader = [object downloader:downloadFilePath];
                
                // Start downloading.
                [downloader transferWithProgressBlock:nil
                                   andCompletionBlock:^(id<KiiRTransfer> transferObject, NSError *error) {
                                       
                                       [av removeFromSuperview];
                                       
                                       if(error == nil) {
                                           UIImage *img = [UIImage imageWithContentsOfFile:downloadFilePath];
                                           imageView.image = img;
                                       } else {
                                           NSLog(@"Error downloading: %@", error);
                                           
                                           UILabel *errorLabel = [[UILabel alloc] initWithFrame:imageView.bounds];
                                           errorLabel.textColor = [UIColor grayColor];
                                           errorLabel.backgroundColor = [UIColor clearColor];
                                           errorLabel.textAlignment = NSTextAlignmentCenter;
                                           errorLabel.font = [UIFont boldSystemFontOfSize:16];
                                           errorLabel.text = @"Error loading image!";
                                           [imageView addSubview:errorLabel];
                                       }
                                       
                                   }];

            }

        }
        
        totalHeight += imageView.frame.size.height;
    }
    
    // move all the other views down beyond size + padding
    for(UIView *v in _contentView.subviews) {
        CGRect f = v.frame;
        f.origin.y += totalHeight + PADDING;
        v.frame = f;
    }
    
    // put this one at the top
    [_contentView addSubview:usernameLabel];
    [_contentView addSubview:timeLabel];
    
    if(messageLabel != nil) {
        [_contentView addSubview:messageLabel];
    } else if(imageView != nil) {
        [_contentView addSubview:imageView];
    }
    
    // resize the content view
    CGFloat maxY = 0;
    for(UIView *v in _contentView.subviews) {
        
        // so we don't check scroll indicators
        if(v.alpha > 0) {
            CGFloat y = v.frame.origin.y + v.frame.size.height;
            if (y > maxY) {
                maxY = y;
            }
        }

    }
    
    _contentView.contentSize = CGSizeMake(320, maxY+PADDING);
}

- (void) viewDidAppear:(BOOL)animated
{
    [KiiAnalytics trackEvent:@"page_view" withExtras:@{@"page": @"feed", @"logged_in": [NSNumber numberWithBool:[KiiUser loggedIn]]}];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!animated) {
        
        for(UIView *v in _contentView.subviews) {
            // so we don't remove scroll indicators
            if(v.alpha > 0) {
                [v removeFromSuperview];
            }
        }
        
        [KTLoader showLoader:@"Loading Feed..."];
        
        // Instantiate with the endpoint.
        KiiServerCodeEntry* entry = [Kii serverCodeEntry:@"feed"];
        
        // Execute the Server Code.
        [entry execute:nil
             withBlock:^(KiiServerCodeEntry *entry, KiiServerCodeEntryArgument *argument, KiiServerCodeExecResult *result, NSError *error) {
                 
                 if(error == nil) {
                     
                     NSDictionary *response = [result returnedValue];
                     NSArray *results = [response objectForKey:@"returnedValue"];
                     
                     results = [results reversedArray];
                     
                     for(NSDictionary *o in results) {
                         
                         double created = [[o objectForKey:@"created"] doubleValue];
                         NSDate *date = [NSDate dateWithTimeIntervalSince1970:created/1000];
                         NSString *timestamp = [date timeAgo:FALSE];
                         
                         [self drawPost:[o objectForKey:@"uri"]
                           withUsername:[o objectForKey:@"username"]
                                andTime:timestamp
                             andMessage:[o objectForKey:@"message"]
                               andImage:nil];
                     }
                     
                     [KTLoader hideLoader];
                     
                 } else {
                     
                     NSLog(@"Error: %@", error);
                     
                     [KTLoader showLoader:@"Error Loading Feed"
                                 animated:TRUE
                            withIndicator:KTLoaderIndicatorError
                          andHideInterval:KTLoaderDurationAuto];
                 }
             }];

    }

}

#pragma mark - UIActionSheetDelegate
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if(buttonIndex != actionSheet.cancelButtonIndex) {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = TRUE;
        
        if(hasCamera && buttonIndex == 0) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        
        [self presentViewController:picker animated:TRUE completion:nil];
    }

}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // get the image
//    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    // shrink it down to be quicker to load..
    // we don't need them big for this use case anyway
    __block UIImage *newImage = [UIImage imageWithImage:image scaledToSize:CGSizeMake(280, 280)];
    
    // save it to file
    __block NSString *path = [[AppDelegate applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString randomString:16]];
    [UIImageJPEGRepresentation(newImage, 1.0f) writeToFile:path atomically:TRUE];
    
    // show the progress indicator
    [KTLoader showLoader:@"Uploading Image..."
                animated:TRUE
           withIndicator:KTLoaderIndicatorProgress];
    
    // start the upload
    KiiBucket *bucket = [Kii bucketWithName:BUCKET_FEED];
    KiiObject *object = [bucket createObject];
    [object setObject:@"image" forKey:@"message_type"];
    [object setObject:[KiiUser currentUser].username forKey:@"username"];
    
    [object saveWithBlock:^(KiiObject *object, NSError *error) {
        if(error == nil) {
            
            KiiUploader *uploader = [object uploader:path];
            
            KiiRTransferBlock progress = ^(id <KiiRTransfer> transferObject, NSError *retError) {
                KiiRTransferInfo *info = [transferObject info];
                float progressFloat = (float) [info completedSizeInBytes] / [info totalSizeInBytes];
                [KTLoader setProgress:progressFloat];
                
                NSLog(@"Progress: %g", progressFloat);
            };
            
            [uploader transferWithProgressBlock:progress
                             andCompletionBlock:^(id<KiiRTransfer> transferObject, NSError *error) {
                                 
                                 if(error == nil) {
                                     [KTLoader showLoader:@"Posted!"
                                                 animated:TRUE
                                            withIndicator:KTLoaderIndicatorSuccess
                                          andHideInterval:KTLoaderDurationAuto];
                                     
                                     [self drawPost:object.uuid
                                       withUsername:[KiiUser currentUser].username
                                            andTime:@"Just Now"
                                         andMessage:nil
                                           andImage:newImage];
                                     
                                 } else {
                                     NSLog(@"Error: %@", error);
                                     [KTLoader showLoader:@"Error!"
                                                 animated:TRUE
                                            withIndicator:KTLoaderIndicatorError
                                          andHideInterval:KTLoaderDurationAuto];
                                 }
                                 
                                 // remove the file
                                 NSError *fileErr;
                                 [[NSFileManager defaultManager] removeItemAtPath:path error:&fileErr];

                             }];
            
        } else {
            NSLog(@"Error: %@", error);
            [KTLoader showLoader:@"Error!"
                        animated:TRUE
                   withIndicator:KTLoaderIndicatorError
                 andHideInterval:KTLoaderDurationAuto];

            // remove the file
            NSError *fileErr;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&fileErr];
        }
    }];

    
    
    // dismiss the view
    [picker dismissViewControllerAnimated:TRUE completion:nil];
}

@end
