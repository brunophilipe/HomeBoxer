//
//  BPPage.m
//  HomeBoxer
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPPage.h"

@implementation BPPage

- (id)init
{
	self = [super init];

	if (self) {
		self.title = [NSString string];
		self.slug = [NSString string];
		self.contents = [NSString string];
		self.mode = BP_PAGE_MODE_MARKDOWN;
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];

	if (self) {
		self.title = [aDecoder decodeObjectForKey:@"BPPAGE_TITLE"];
		self.slug = [aDecoder decodeObjectForKey:@"BPPAGE_SLUG"];
		self.contents = [aDecoder decodeObjectForKey:@"BPPAGE_CONTENTS"];
		self.page_id = [(NSNumber *)[aDecoder decodeObjectForKey:@"BPPAGE_ID"] unsignedIntegerValue];
		self.mode = [aDecoder decodeIntegerForKey:@"BPPAGE_MODE"];
		self.home = [aDecoder decodeBoolForKey:@"BP_ISHOME"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.title forKey:@"BPPAGE_TITLE"];
	[aCoder encodeObject:self.slug forKey:@"BPPAGE_SLUG"];
	[aCoder encodeObject:self.contents forKey:@"BPPAGE_CONTENTS"];
	[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.page_id] forKey:@"BPPAGE_ID"];
	[aCoder encodeInteger:self.mode forKey:@"BPPAGE_MODE"];
	[aCoder encodeBool:self.isHome forKey:@"BP_ISHOME"];
}

@end
