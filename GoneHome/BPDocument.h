//
//  BPDocument.h
//  GoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	BP_METADATA_PAGE_TITLE = 1,
	BP_METADATA_AUTHOR_NAME,
	BP_METADATA_AUTHOR_EMAIL
} BP_METADATA;

#define kBP_METADATA_PAGE_TITLE @"BP_METADATA_PAGE_TITLE"
#define kBP_METADATA_AUTHOR_NAME @"BP_METADATA_AUTHOR_NAME"
#define kBP_METADATA_AUTHOR_EMAIL @"BP_METADATA_AUTHOR_EMAIL"

@interface BPDocument : NSDocument

@property NSDictionary	*project_metadata;
@property NSArray		*project_pages;
@property NSArray		*project_resources;

@property (strong) IBOutlet NSTextField *info_title;
@property (strong) IBOutlet NSTextField *info_author;
@property (strong) IBOutlet NSTextField *info_authorEmail;

- (IBAction)updatedMetadata:(id)sender;

@end
