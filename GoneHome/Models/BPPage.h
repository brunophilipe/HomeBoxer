//
//  BPPage.h
//  DoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	BP_PAGE_MODE_HTML,
	BP_PAGE_MODE_MARKDOWN,
	BP_PAGE_MODE_PLAINTEXT
} BP_PAGE_MODE;

@interface BPPage : NSObject <NSCoding>

@property (strong, nonatomic) NSString *page_title;
@property (strong, nonatomic) NSString *page_slug;
@property (strong, nonatomic) NSString *page_contents;

@property BOOL deletable;

@property NSUInteger page_id;
@property BP_PAGE_MODE page_mode;

@end
