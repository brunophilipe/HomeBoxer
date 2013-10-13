//
//  BPResource.m
//  HomeBoxer
//
//  Created by Bruno Philipe on 10/11/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPResource.h"

@implementation BPResource

+ (instancetype)resourceWithFilename:(NSString *)file uid:(NSUInteger)uid andData:(NSData *)data
{
	BPResource *resource = [[BPResource alloc] init];
	[resource setFilename:file];
	[resource setUid:uid];
	[resource setData:data];
	return resource;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self) {
		self.data = [aDecoder decodeObjectForKey:@"BP_RES_DATA"];
		self.filename = [aDecoder decodeObjectForKey:@"BP_RES_FILENAME"];
		self.uid = [(NSNumber *)[aDecoder decodeObjectForKey:@"BP_RES_UID"] unsignedIntegerValue];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.data forKey:@"BP_RES_DATA"];
	[aCoder encodeObject:self.filename forKey:@"BP_RES_FILENAME"];
	[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.uid] forKey:@"BP_RES_UID"];
}

@end
