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
#import "UIImageView+MKNetworkKitAdditions.h"

#define kActivityIndicatorTag 18942347

@implementation UIImageView (MKNetworkKitAdditions)

- (void)showActivityIndicatorWithStyle:(UIActivityIndicatorViewStyle)indicatorStyle {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    activityIndicator.center = self.center;
    activityIndicator.tag = kActivityIndicatorTag;
    [activityIndicator startAnimating];
    [self addSubview:activityIndicator];
}

- (void)hideActivityIndicator {
    UIView *activityIndicator = [self viewWithTag:kActivityIndicatorTag];
    [activityIndicator removeFromSuperview];
}

- (MKNetworkOperation *)setImageAtURL:(NSURL *)imageURL usingEngine:(MKNetworkEngine *)networkEngine {
    return [self setImageAtURL:imageURL usingEngine:networkEngine forceReload:NO showActivityIndicator:YES activityIndicatorStyle:UIActivityIndicatorViewStyleGray loadingImage:nil notAvailableImage:nil];
}

- (MKNetworkOperation *)setImageAtURL:(NSURL *)imageURL usingEngine:(MKNetworkEngine *)networkEngine forceReload:(BOOL)forceReload showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage notAvailableImage:(UIImage *)notAvailableImage; {
    
    self.image = loadingImage;
    
    if (!imageURL) {
        self.image = notAvailableImage;
        return nil;
    }
    
    if (showActivityIndicator) {
        [self showActivityIndicatorWithStyle:indicatorStyle];
    }
    
    MKNetworkOperation *imageOperation = [networkEngine imageAtURL:imageURL onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
        if (!fetchedImage) {
            self.image = notAvailableImage;
        } else {
            self.image = fetchedImage;
        }
        if (showActivityIndicator) {
            [self performSelectorOnMainThread:@selector(hideActivityIndicator) withObject:nil waitUntilDone:NO];
        }
    }];
    [networkEngine enqueueOperation:imageOperation forceReload:forceReload];
    
    return imageOperation;
}

@end
#endif
