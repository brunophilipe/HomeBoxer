//
//  BPPage.h
//  HomeBoxer
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	BP_PAGE_MODE_MARKDOWN,
	BP_PAGE_MODE_HTML,
	BP_PAGE_MODE_PLAINTEXT
} BP_PAGE_MODE;

@interface BPPage : NSObject <NSCoding>

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *slug;
@property (strong, nonatomic) NSString *contents;

@property (getter = isHome) BOOL home;

@property NSUInteger page_id;
@property BP_PAGE_MODE mode;

@end
