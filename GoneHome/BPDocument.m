//
//  BPDocument.m
//  GoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPDocument.h"

@implementation BPDocument

- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		[self setProject_metadata:[NSMutableDictionary dictionary]];
		[self setProject_pages:[NSMutableArray array]];
		[self setProject_resources:[NSMutableArray array]];

		[(NSMutableDictionary *)self.project_metadata setObject:@"John's Homepage" forKey:kBP_METADATA_PAGE_TITLE];
		[(NSMutableDictionary *)self.project_metadata setObject:@"John Appleseed" forKey:kBP_METADATA_AUTHOR_NAME];
		[(NSMutableDictionary *)self.project_metadata setObject:@"john.apple@example.com" forKey:kBP_METADATA_AUTHOR_EMAIL];
    }
    return self;
}

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"BPDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has loaded the document's window.

	[self updateContentFromMemory];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	NSMutableDictionary *files = [NSMutableDictionary dictionary];
	NSFileWrapper	*wrapper;
	NSData			*auxData;

	@try {
		auxData = [NSKeyedArchiver archivedDataWithRootObject:self.project_metadata];
		wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:auxData];
		[files setObject:wrapper forKey:@"metadata.bin"];

		auxData = [NSKeyedArchiver archivedDataWithRootObject:self.project_pages];
		wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:auxData];
		[files setObject:wrapper forKey:@"pages.bin"];

		auxData = [NSKeyedArchiver archivedDataWithRootObject:self.project_resources];
		wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:auxData];
		[files setObject:wrapper forKey:@"resources.bin"];

		wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:files];

		return wrapper;
	}
	@catch (NSException *exception) {
		*outError = [NSError errorWithDomain:@"BP_READ_WRITE" code:2 userInfo:exception.userInfo];
		return nil;
	}
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	NSDictionary	*files;
	NSFileWrapper	*wrapper;

	@try {
		files = [fileWrapper fileWrappers];

		wrapper = [files objectForKey:@"metadata.bin"];
		self.project_metadata = [NSKeyedUnarchiver unarchiveObjectWithData:wrapper.regularFileContents];

		wrapper = [files objectForKey:@"pages.bin"];
		self.project_pages = [NSKeyedUnarchiver unarchiveObjectWithData:wrapper.regularFileContents];

		wrapper = [files objectForKey:@"resources.bin"];
		self.project_resources = [NSKeyedUnarchiver unarchiveObjectWithData:wrapper.regularFileContents];

		return YES;
	}
	@catch (NSException *exception) {
		*outError = [NSError errorWithDomain:@"BP_READ_WRITE" code:1 userInfo:exception.userInfo];
		return NO;
	}
}

- (void)updateContentFromMemory
{
	[self.info_title setStringValue:[self.project_metadata objectForKey:kBP_METADATA_PAGE_TITLE]];
	[self.info_author setStringValue:[self.project_metadata objectForKey:kBP_METADATA_AUTHOR_NAME]];
	[self.info_authorEmail setStringValue:[self.project_metadata objectForKey:kBP_METADATA_AUTHOR_EMAIL]];
}

- (IBAction)updatedMetadata:(id)sender {
	NSControl *control = sender;
	switch (control.tag) {
		case BP_METADATA_PAGE_TITLE:
			[(NSMutableDictionary *)self.project_metadata setObject:control.stringValue forKey:kBP_METADATA_PAGE_TITLE];
			break;

		case BP_METADATA_AUTHOR_NAME:
			[(NSMutableDictionary *)self.project_metadata setObject:control.stringValue forKey:kBP_METADATA_AUTHOR_NAME];
			break;

		case BP_METADATA_AUTHOR_EMAIL:
			[(NSMutableDictionary *)self.project_metadata setObject:control.stringValue forKey:kBP_METADATA_AUTHOR_EMAIL];
			break;

		default:
			break;
	}
}
@end
