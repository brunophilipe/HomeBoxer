//
//  BPPage.m
//  DoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPPage.h"

@implementation BPPage

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];

	if (self) {
		self.page_title = [aDecoder decodeObjectForKey:@"BPPAGE_TITLE"];
		self.page_slug = [aDecoder decodeObjectForKey:@"BPPAGE_SLUG"];
		self.page_contents = [aDecoder decodeObjectForKey:@"BPPAGE_CONTENTS"];
		self.page_id = [(NSNumber *)[aDecoder decodeObjectForKey:@"BPPAGE_ID"] unsignedIntegerValue];
		self.page_mode = [aDecoder decodeIntegerForKey:@"BPPAGE_MODE"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.page_title forKey:@"BPPAGE_TITLE"];
	[aCoder encodeObject:self.page_slug forKey:@"BPPAGE_SLUG"];
	[aCoder encodeObject:self.page_contents forKey:@"BPPAGE_CONTENTS"];
	[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.page_id] forKey:@"BPPAGE_ID"];
	[aCoder encodeInteger:self.page_mode forKey:@"BPPAGE_MODE"];
}

@end
