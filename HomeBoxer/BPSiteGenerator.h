//
//  BPSiteGenerator.h
//  HomeBoxer
//
//  Created by Bruno Philipe on 9/19/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GHMarkdownParser.h"

@interface BPSiteGenerator : NSObject

+ (void)generateSiteAtURL:(NSURL *)url withMetadata:(NSDictionary *)meta pages:(NSArray *)pages andResources:(NSArray *)resources;

@end
