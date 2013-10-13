//
//  BPSiteGenerator.m
//  HomeBoxer
//
//  Created by Bruno Philipe on 9/19/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPSiteGenerator.h"
#import "BPDocument.h"

@implementation BPSiteGenerator

+ (void)generateSiteAtURL:(NSURL *)url withMetadata:(NSDictionary *)meta pages:(NSArray *)pages andResources:(NSArray *)resources
{
	NSString *auxPath;
	NSError *error = nil;
	NSMutableString *tempContents;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

	[formatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm '– GMT'ZZZ"];

	//Build menu to be used on all pages

	NSString *menu = [BPSiteGenerator buildMenu:pages];

	//Create necessary directories

	[BPSiteGenerator emptyDirectoryAtPath:url.relativePath];

	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir, exists = [fm fileExistsAtPath:url.relativePath isDirectory:&isDir];
	if (!exists || isDir) {
		if (isDir) {
			[fm removeItemAtPath:url.relativePath error:&error];

			if (error) {
				NSAlert *alert = [NSAlert alertWithError:error];
				[alert runModal];
			}
		}
		[fm createDirectoryAtURL:url withIntermediateDirectories:NO attributes:NO error:&error];

		if (error) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
		}
	}

	[fm createDirectoryAtURL:[url URLByAppendingPathComponent:@"css"] withIntermediateDirectories:NO attributes:NO error:&error];
	[fm createDirectoryAtURL:[url URLByAppendingPathComponent:@"js"] withIntermediateDirectories:NO attributes:NO error:&error];
	[fm createDirectoryAtURL:[url URLByAppendingPathComponent:@"fonts"] withIntermediateDirectories:NO attributes:NO error:&error];
	[fm createDirectoryAtURL:[url URLByAppendingPathComponent:@"files"] withIntermediateDirectories:NO attributes:NO error:&error];

	//Generate pages

	for (NSUInteger i=0; i<pages.count; i++) {
		BPPage		*page = [pages objectAtIndex:i];
		NSString	*content;
		NSString	*path;
		NSString	*tag;

		auxPath = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.html",(!page.isHome ? page.slug : @"index")]].relativePath;
		tempContents = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error] mutableCopy];

		if (error) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
		}

		switch (page.mode) {
			case BP_PAGE_MODE_HTML:
			case BP_PAGE_MODE_PLAINTEXT:
				content = page.contents;
				break;

			case BP_PAGE_MODE_MARKDOWN:
				content = [GHMarkdownParser flavoredHTMLStringFromMarkdownString:page.contents];
				break;
		}

		[tempContents replaceOccurrencesOfString:@"{render.contents}" withString:content options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];

		for (BPPage *page in pages) {
			path = [NSString stringWithFormat:@"%@.html",(!page.isHome ? page.slug : @"index")];
			tag = [NSString stringWithFormat:@"{pages.%@}",page.slug];

			[tempContents replaceOccurrencesOfString:tag withString:path options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		}

		for (BPResource *resource in resources) {
			path = [NSString stringWithFormat:@"files/%@",resource.filename];
			tag = [NSString stringWithFormat:@"{resource.%ld}",(unsigned long)resource.uid];

			[tempContents replaceOccurrencesOfString:tag withString:path options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		}

		[tempContents replaceOccurrencesOfString:@"{project.title}" withString:[BPSiteGenerator fieldInputOrDefaultForKey:kBP_METADATA_PAGE_TITLE onDictionary:meta] options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		[tempContents replaceOccurrencesOfString:@"{project.email}" withString:[BPSiteGenerator fieldInputOrDefaultForKey:kBP_METADATA_AUTHOR_EMAIL onDictionary:meta] options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		[tempContents replaceOccurrencesOfString:@"{project.author}" withString:[BPSiteGenerator fieldInputOrDefaultForKey:kBP_METADATA_AUTHOR_NAME onDictionary:meta] options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];

		[tempContents replaceOccurrencesOfString:@"{page.title}" withString:page.title options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		[tempContents replaceOccurrencesOfString:@"{page.slug}" withString:page.slug options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		[tempContents replaceOccurrencesOfString:@"{render.menu}" withString:menu options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		[tempContents replaceOccurrencesOfString:@"{render.builddate}" withString:[formatter stringFromDate:[NSDate date]] options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];

		[BPSiteGenerator writeData:[tempContents dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
	}

	//Copy files

	for (BPResource *resource in resources) {
		auxPath = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"/files/%@",resource.filename]].relativePath;
		[BPSiteGenerator writeData:resource.data toPath:auxPath];
	}

	auxPath = [url URLByAppendingPathComponent:@"css/bootstrap.min.css"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bootstrap" ofType:@"min.css"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
	auxPath = [url URLByAppendingPathComponent:@"css/homeboxer.css"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"homeboxer" ofType:@"css"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
	auxPath = [url URLByAppendingPathComponent:@"js/bootstrap.min.js"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bootstrap" ofType:@"min.js"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
	auxPath = [url URLByAppendingPathComponent:@"js/jquery.min.js"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"jquery" ofType:@"min.js"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];

	auxPath = [url URLByAppendingPathComponent:@"fonts/glyphicons-halflings-regular.eot"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glyphicons-halflings-regular-eot" ofType:@"data"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
	auxPath = [url URLByAppendingPathComponent:@"fonts/glyphicons-halflings-regular.svg"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glyphicons-halflings-regular-svg" ofType:@"data"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
	auxPath = [url URLByAppendingPathComponent:@"fonts/glyphicons-halflings-regular.ttf"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glyphicons-halflings-regular-ttf" ofType:@"data"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
	auxPath = [url URLByAppendingPathComponent:@"fonts/glyphicons-halflings-regular.woff"].relativePath;
	[BPSiteGenerator writeData:[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glyphicons-halflings-regular-woff" ofType:@"data"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
}

+ (BOOL)writeData:(NSData *)data toPath:(NSString *)path
{
	NSFileManager *manager = [NSFileManager defaultManager];
	@try {
		if (![manager fileExistsAtPath:path isDirectory:NO]) {
			[manager createFileAtPath:path contents:data attributes:nil];
		} else {
			[data writeToFile:path atomically:NO];
		}
	}
	@catch (NSException *exception) {
		return NO;
	}
	return YES;
}

+ (NSString *)fieldInputOrDefaultForKey:(NSString *)key onDictionary:(NSDictionary *)meta
{
	NSString *value = [meta objectForKey:key];
	if (value && ![value isEqualToString:@""]) {
		return value;
	}

	if ([key isEqualToString:kBP_METADATA_PAGE_TITLE]) {
		return @"John's Homepage";
	} else if ([key isEqualToString:kBP_METADATA_AUTHOR_NAME]) {
		return @"John Appleseed";
	} else if ([key isEqualToString:kBP_METADATA_AUTHOR_EMAIL]) {
		return @"john.apple@example.com";
	} else {
		return @"UNDEFINED";
	}
}

+ (NSString *)buildMenu:(NSArray *)pages
{
	NSMutableString *str = [[NSMutableString alloc] init];

	for (BPPage *page in pages) {
		[str appendFormat:@"<li><a href=\"%@.html\">%@</a></li>\n",(!page.isHome ? page.slug : @"index"),page.title];
	}

	return [str copy];
}

+ (void)emptyDirectoryAtPath:(NSString *)path
{
	NSFileManager* fm = [[NSFileManager alloc] init];
	NSDirectoryEnumerator* en = [fm enumeratorAtPath:path];
	NSError* err = nil;
	BOOL res;

	NSString* file;
	while (file = [en nextObject]) {
		res = [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
		if (!res && err) {
			NSLog(@"oops: %@", err);
		}
	}
}

@end
