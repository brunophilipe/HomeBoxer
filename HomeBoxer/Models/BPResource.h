//
//  BPResource.h
//  HomeBoxer
//
//  Created by Bruno Philipe on 10/11/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPResource : NSObject <NSCoding>

@property (strong) NSData *data;
@property (strong) NSString *filename;

@property NSUInteger uid;

+ (instancetype)resourceWithFilename:(NSString *)file uid:(NSUInteger)uid andData:(NSData *)data;

@end
