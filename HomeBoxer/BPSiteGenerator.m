//
//  BPSiteGenerator.m
//  HomeBoxer
//
//  Created by Bruno Philipe on 9/19/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <stdio.h>
#import <errno.h>

#import "BPSiteGenerator.h"
#import "BPHomeBoxerProject.h"
#import "BPPage.h"
#import "BPResource.h"
#import "GHMarkdownParser.h"
#import "tidy.h"
#import "buffio.h"

@implementation BPSiteGenerator

+ (void)generateSiteAtURL:(NSURL *)url withMetadata:(NSDictionary *)meta pages:(NSArray *)pages andResources:(NSArray *)resources
{
	NSString		*auxPath, *content, *path, *tag;
	NSError			*error = nil;
	NSMutableString *tempContents;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	BPPage			*page;
	NSString		*extension = (![[meta objectForKey:kBP_METADATA_FAKEPHP] boolValue] ? @"html" : @"php");

	[formatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm '- GMT'ZZZ"];

	//Build menu to be used on all pages

	NSString *menu = [BPSiteGenerator buildMenu:pages filesExtension:extension];

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
		page = [pages objectAtIndex:i];

		auxPath = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",(!page.isHome ? page.slug : @"index"),extension]].relativePath;
		tempContents = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error] mutableCopy];

		if (error) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
		}

		[tempContents replaceOccurrencesOfString:@"{project.metadesc}" withString:[BPSiteGenerator fieldInputOrDefaultForKey:kBP_METADATA_METADESC onDictionary:meta] options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];
		[tempContents replaceOccurrencesOfString:@"{project.metakeys}" withString:[BPSiteGenerator fieldInputOrDefaultForKey:kBP_METADATA_METAKEYS onDictionary:meta] options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];

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

		[tempContents replaceOccurrencesOfString:@"{project.footer}" withString:[BPSiteGenerator fieldInputOrDefaultForKey:kBP_METADATA_FOOTERMSG onDictionary:meta] options:NSCaseInsensitiveSearch range:NSMakeRange(0, tempContents.length)];

		for (BPPage *page in pages) {
			path = [NSString stringWithFormat:@"%@.%@",(!page.isHome ? page.slug : @"index"),extension];
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

		// TidyHTML

		[BPSiteGenerator writeData:[[BPSiteGenerator executeTidyHTMLOnString:tempContents] dataUsingEncoding:NSUTF8StringEncoding] toPath:auxPath];
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

+ (NSString *)executeTidyHTMLOnString:(NSString *)inputStr
{
	NSString *outputStr = nil;
	const char* input = [inputStr UTF8String];
	TidyBuffer output = {0};
	TidyBuffer errbuf = {0};
	int rc = -1;
	Bool ok;

	TidyDoc tdoc = tidyCreate();                     // Initialize "document"
//	printf( "Tidying:\t%s\n", input);

	ok = tidyOptSetBool(tdoc, TidyXhtmlOut, no);  // Convert to XHTML TidyHideEndTags
	if (ok) ok = tidyOptSetInt(tdoc, TidyIndentContent, TidyAutoState);
	if (ok) ok = tidyOptSetInt(tdoc, TidyWrapLen, 0);
	if (ok)	ok = tidyOptSetInt(tdoc, TidyIndentSpaces, 4);
	if (ok) ok = tidyOptSetValue(tdoc, TidyCharEncoding, "utf8");
//	if (ok) ok = tidyOptSetValue(tdoc, TidyInCharEncoding, "uft8");
//	if (ok) ok = tidyOptSetValue(tdoc, TidyOutCharEncoding, "uft8");
	if (ok) rc = tidySetErrorBuffer(tdoc, &errbuf);      // Capture diagnostics
	if (rc >= 0) rc = tidyParseString(tdoc, input);           // Parse the input
	if (rc >= 0) rc = tidyCleanAndRepair(tdoc);               // Tidy it up!
	if (rc >= 0) rc = tidyRunDiagnostics(tdoc);               // Kvetch
	if (rc > 1) rc =(tidyOptSetBool(tdoc, TidyForceOutput, yes) ? rc : -1); // If error, force output.
	if (rc >= 0) rc = tidySaveBuffer(tdoc, &output);          // Pretty Print

	if(rc >= 0)
	{
		if(rc > 0)
//			printf( "\nDiagnostics:\n\n%s", errbuf.bp);
//		printf( "\nAnd here is the result:\n\n%s", output.bp);
		outputStr = [NSString stringWithUTF8String:(const char *)output.bp];
	}
	else
		printf( "A severe error (%d) occurred.\n", rc);

	tidyBufFree(&output);
	tidyBufFree(&errbuf);
	tidyRelease(tdoc);

	return outputStr;
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
	} else if ([key isEqualToString:kBP_METADATA_FOOTERMSG]) {
		return @"Copyright © 2013 - {project.author}";
	} else {
		return @"UNDEFINED";
	}
}

+ (NSString *)buildMenu:(NSArray *)pages filesExtension:(NSString *)extension
{
	NSMutableString *str = [[NSMutableString alloc] init];

	for (BPPage *page in pages) {
		if ([page hideFromMenu]) continue;
		[str appendFormat:@"<li><a href=\"%@.%@\">%@</a></li>\n",(!page.isHome ? page.slug : @"index"),extension,page.title];
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
