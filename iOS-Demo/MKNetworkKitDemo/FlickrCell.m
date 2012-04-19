//
//  FlickrCell.m
//  MKNetworkKit-iOS-Demo
//
//  Created by Mugunth Kumar on 22/1/12.
//  Copyright (c) 2012 Steinlogic. All rights reserved.
//

#import "FlickrCell.h"

@implementation FlickrCell
@synthesize titleLabel = titleLabel_;
@synthesize authorNameLabel = authorNameLabel_;
@synthesize thumbnailImage = thumbnailImage_;
@synthesize loadingImageURLString = loadingImageURLString_;

//=========================================================== 
// + (BOOL)automaticallyNotifiesObserversForKey:
//
//=========================================================== 
+ (BOOL)automaticallyNotifiesObserversForKey: (NSString *)theKey 
{
    BOOL automatic;
    
    if ([theKey isEqualToString:@"thumbnailImage"]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    
    return automatic;
}

-(void) prepareForReuse {
    
    self.thumbnailImage.image = nil;
    [self.thumbnailImage cancelImageDownload];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) setFlickrData:(NSDictionary*) thisFlickrImage {
    
    self.titleLabel.text = [thisFlickrImage objectForKey:@"title"];
	self.authorNameLabel.text = [thisFlickrImage objectForKey:@"owner"];
    self.loadingImageURLString =
    [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/%@_%@_s.jpg", 
     [thisFlickrImage objectForKey:@"farm"], [thisFlickrImage objectForKey:@"server"], 
     [thisFlickrImage objectForKey:@"id"], [thisFlickrImage objectForKey:@"secret"]];
    
    [self.thumbnailImage setImageAtURL:[NSURL URLWithString:self.loadingImageURLString]];
}

@end
