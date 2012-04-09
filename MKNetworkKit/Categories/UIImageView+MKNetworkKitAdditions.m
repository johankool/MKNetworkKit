//
//  UIImageView+MKNetworkKitAdditions.m
//  MKNetworkKit
//
//  Created by Johan Kool on 2/4/2012.
//  Copyright (c) 2012 Johan Kool. All rights reserved.
//

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#if TARGET_OS_IPHONE
#import "MKNetworkKit.h"

#define kActivityIndicatorTag 18942347
#define kMaskingViewTag 18942348
#define kTemporaryViewTag 18942349

@implementation UIImageView (MKNetworkKitAdditions)

- (void)showActivityIndicatorWithStyle:(UIActivityIndicatorViewStyle)indicatorStyle {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    CGRect currentFrame = activityIndicator.frame;
    CGRect newFrame = CGRectMake(CGRectGetMidX(self.bounds) - 0.5f * currentFrame.size.width,
                                 CGRectGetMidY(self.bounds) - 0.5f * currentFrame.size.height,
                                 currentFrame.size.width,
                                 currentFrame.size.height);
    activityIndicator.frame = newFrame;
    activityIndicator.tag = kActivityIndicatorTag;
    [activityIndicator startAnimating];
    [self addSubview:activityIndicator];
}

- (void)hideActivityIndicator {
    UIView *activityIndicator = [self viewWithTag:kActivityIndicatorTag];
    [activityIndicator removeFromSuperview];
    UIView *maskingImageView = [self viewWithTag:kMaskingViewTag];
    [maskingImageView removeFromSuperview];
    UIView *temporaryImageView = [self viewWithTag:kTemporaryViewTag];
    [temporaryImageView removeFromSuperview];
}

- (MKNetworkOperation *)setImageAtURL:(NSURL *)imageURL usingEngine:(MKNetworkEngine *)networkEngine {
    return [self setImageAtURL:imageURL usingEngine:networkEngine showActivityIndicator:YES activityIndicatorStyle:UIActivityIndicatorViewStyleGray loadingImage:nil fadeIn:YES notAvailableImage:nil];
}

- (MKNetworkOperation *)setImageAtURL:(NSURL *)imageURL usingEngine:(MKNetworkEngine *)networkEngine showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage fadeIn:(BOOL)fadeIn notAvailableImage:(UIImage *)notAvailableImage; {
    self.image = loadingImage;
    
    if (!imageURL) {
        self.image = notAvailableImage;
        return nil;
    }
    
    // Setup views needed for fade
    UIImageView *temporaryImageView = nil;
    UIImageView *maskingImageView = nil;
    if (fadeIn) {
        temporaryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        temporaryImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        temporaryImageView.image = self.image;
        temporaryImageView.tag = kTemporaryViewTag;
        [self addSubview:temporaryImageView];
        
        maskingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        maskingImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        maskingImageView.image = self.image;
        maskingImageView.tag = kMaskingViewTag;
        
        if (self.backgroundColor) {
            maskingImageView.backgroundColor = [self.backgroundColor colorWithAlphaComponent:1.0];
        } else {
            maskingImageView.backgroundColor = [UIColor whiteColor];
        }
        [self addSubview:maskingImageView];
    }
    
    if (showActivityIndicator) {
        if (maskingImageView) {
            [maskingImageView showActivityIndicatorWithStyle:indicatorStyle];
        } else {
            [self showActivityIndicatorWithStyle:indicatorStyle];
        }
    }
    
    MKNetworkOperation *imageOperation = [networkEngine imageAtURL:imageURL onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
        if (!fetchedImage) {
           fetchedImage = notAvailableImage;
        }
        
        if (!isInCache && fadeIn) {
            // Perform fade
            temporaryImageView.image = fetchedImage;
            temporaryImageView.alpha = 0;
            maskingImageView.alpha = 1;
            [UIView animateWithDuration:0.4 
                             animations:^{ 
                                 temporaryImageView.alpha = 1;
                                 maskingImageView.alpha = 0;
                             } 
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     // Set image and cleanup
                                     self.image = fetchedImage;
                                     [temporaryImageView removeFromSuperview];
                                     [maskingImageView removeFromSuperview];
                                 }
                             }];
        } else {
            // Set image and cleanup
            self.image = fetchedImage;
            [self hideActivityIndicator];
            [temporaryImageView removeFromSuperview];
            [maskingImageView removeFromSuperview];
        }
    }];
    
    return imageOperation;
}


@end
#endif