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
#import <objc/runtime.h>

#define kActivityIndicatorTag 18942347
#define kMaskingViewTag 18942348
#define kTemporaryViewTag 18942349

static char kMKNetworkOperationObjectKey;

@interface UIImageView (MKNetworkKitAdditions_Private)

@property (readwrite, nonatomic, retain, getter=mk_imageOperation, setter = mk_setImageOperation:) MKNetworkOperation *mk_imageOperation;

@end

@implementation UIImageView (MKNetworkKitAdditions_Private)

@dynamic mk_imageOperation;

@end

@implementation UIImageView (MKNetworkKitAdditions)

+ (MKNetworkEngine *)mk_sharedImageEngine {
    static MKNetworkEngine *_mk_sharedImageEngine = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _mk_sharedImageEngine = [[MKNetworkEngine alloc] initWithHostName:nil customHeaderFields:nil];
        [_mk_sharedImageEngine useCache];
    });
    
    return _mk_sharedImageEngine;
}

- (MKNetworkOperation *)mk_imageOperation {
    return (MKNetworkOperation *)objc_getAssociatedObject(self, &kMKNetworkOperationObjectKey);
}

- (void)mk_setImageOperation:(MKNetworkOperation *)imageOperation {
    objc_setAssociatedObject(self, &kMKNetworkOperationObjectKey, imageOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)mk_showActivityIndicatorWithStyle:(UIActivityIndicatorViewStyle)indicatorStyle {
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

- (void)mk_cleanup {
    UIView *activityIndicator = [self viewWithTag:kActivityIndicatorTag];
    [activityIndicator removeFromSuperview];
    UIView *maskingImageView = [self viewWithTag:kMaskingViewTag];
    [maskingImageView removeFromSuperview];
    UIView *temporaryImageView = [self viewWithTag:kTemporaryViewTag];
    [temporaryImageView removeFromSuperview];
}

- (void)mk_setImageAtURL:(NSURL *)imageURL {
    [self mk_setImageAtURL:imageURL usingEngine:[UIImageView mk_sharedImageEngine]];
}

- (void)mk_setImageAtURL:(NSURL *)imageURL usingEngine:(MKNetworkEngine *)engine {
    [self mk_setImageAtURL:imageURL usingEngine:engine forceReload:NO showActivityIndicator:YES activityIndicatorStyle:UIActivityIndicatorViewStyleGray loadingImage:nil fadeIn:YES notAvailableImage:nil];
}

- (void)mk_setImageAtURL:(NSURL *)imageURL forceReload:(BOOL)forceReload showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage fadeIn:(BOOL)fadeIn notAvailableImage:(UIImage *)notAvailableImage {
    [self mk_setImageAtURL:imageURL usingEngine:[UIImageView mk_sharedImageEngine] forceReload:forceReload showActivityIndicator:showActivityIndicator activityIndicatorStyle:indicatorStyle loadingImage:loadingImage fadeIn:fadeIn notAvailableImage:notAvailableImage];
}

- (void)mk_setImageAtURL:(NSURL *)imageURL usingEngine:(MKNetworkEngine *)engine forceReload:(BOOL)forceReload showActivityIndicator:(BOOL)showActivityIndicator activityIndicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingImage:(UIImage *)loadingImage fadeIn:(BOOL)fadeIn notAvailableImage:(UIImage *)notAvailableImage {
    NSParameterAssert(engine);
    
    // Don't restart same URL
    BOOL operationAlreadyActive = NO;
    if ([self.mk_imageOperation.url isEqual:imageURL]) {
        operationAlreadyActive = YES;
    }
    
    // In case we are called multiple times, cleanup old stuff first
    if (operationAlreadyActive) {
        [self mk_cleanup];
    } else {
        [self mk_cancelImageDownload];
    }
    
    self.image = loadingImage;
    
    if (!imageURL) {
        self.image = notAvailableImage;
        if (operationAlreadyActive) {
            [self mk_cancelImageDownload];
        }
        return;
    }
    
    // Setup views needed for fade
    UIImageView *temporaryImageView = nil;
    UIImageView *maskingImageView = nil;
    if (fadeIn) {
        temporaryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        temporaryImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        temporaryImageView.contentMode = self.contentMode;
        temporaryImageView.image = self.image;
        temporaryImageView.tag = kTemporaryViewTag;
        [self addSubview:temporaryImageView];
        
        maskingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        maskingImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        maskingImageView.contentMode = self.contentMode;
        maskingImageView.image = self.image;
        maskingImageView.tag = kMaskingViewTag;
        
        if (self.backgroundColor) {
            maskingImageView.backgroundColor = self.backgroundColor;
        } else {
            maskingImageView.backgroundColor = [UIColor clearColor];
        }
        [self addSubview:maskingImageView];
    }
    
    if (showActivityIndicator) {
        if (maskingImageView) {
            [maskingImageView mk_showActivityIndicatorWithStyle:indicatorStyle];
        } else {
            [self mk_showActivityIndicatorWithStyle:indicatorStyle];
        }
    }
    
    void (^completionBlock)(UIImage *fetchedImage, NSURL *URL, BOOL isInCache) = ^(UIImage *fetchedImage, NSURL *URL, BOOL isInCache) {
        if (!fetchedImage) {
            fetchedImage = notAvailableImage;
        }
        
        if (fadeIn && !isInCache) {
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
            [self mk_cleanup];
            [temporaryImageView removeFromSuperview];
            [maskingImageView removeFromSuperview];
        }
    };
    
    if (operationAlreadyActive) {
        [self.mk_imageOperation onCompletion:^(MKNetworkOperation *completedOperation) {
            completionBlock([completedOperation responseImage], imageURL, [completedOperation isCachedResponse]);
        } onError:^(NSError *error) {
            completionBlock(nil, imageURL, NO);
        }];
    } else {
        MKNetworkOperation *imageOperation = [engine operationWithURLString:[imageURL absoluteString]];
        [imageOperation onCompletion:^(MKNetworkOperation *completedOperation) {
            completionBlock([completedOperation responseImage], imageURL, [completedOperation isCachedResponse]);
        } onError:^(NSError *error) {
            completionBlock(nil, imageURL, NO);
        }];
        self.mk_imageOperation = imageOperation;
        [engine enqueueOperation:imageOperation forceReload:forceReload];
    }
}

- (void)mk_cancelImageDownload {
    [self.mk_imageOperation cancel];
    self.mk_imageOperation = nil;
    [self mk_cleanup];
}

@end
#endif
