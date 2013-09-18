//
//  BPDocument.m
//  GoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPDocument.h"

@implementation BPDocument
{
	BPPage *createdPage;
}

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

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCreatedPage) name:kBP_ADD_CREATED_PAGE object:nil];
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

- (void)dismissModal
{
	[NSApp stopModal];
}

- (void)addCreatedPage
{
	[self.project_pages performSelector:@selector(addObject:) withObject:createdPage];
	createdPage = nil;

	[self.tableView_pages reloadData];
}

#pragma mark - IBActions

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

- (IBAction)action_addPage:(id)sender {
	NSArray			*topLevelObjects;
	BPPageWizard	*sheet;

	[[NSBundle mainBundle] loadNibNamed:@"PageWizard" owner:nil topLevelObjects:&topLevelObjects];

	for (NSObject *obj in topLevelObjects) {
		if (obj.class == [BPPageWizard class]) {
			sheet = (BPPageWizard *)obj;
			break;
		}
	}

	createdPage = [[BPPage alloc] init];

	[sheet setPage:createdPage];
	[sheet setIsNewPage:YES];
	[sheet makeKeyWindow];

	[NSApp beginSheet:sheet modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:sheet];

    [NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (IBAction)action_removePage:(id)sender {
}

- (IBAction)action_editPage:(id)sender {
}

- (IBAction)action_addResource:(id)sender {
}

- (IBAction)action_deleteResource:(id)sender {
}

- (IBAction)action_copyTemplate:(id)sender {
}



#pragma mark - Table view data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	switch (aTableView.tag) {
		case 1: return self.project_pages.count;
		case 2: return self.project_resources.count;

		default: return 0;
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	switch (aTableView.tag) {
		case 1:
		{
			if ([aTableColumn.identifier isEqualToString:@"title"]) {
				return [(BPPage *)[self.project_pages objectAtIndex:rowIndex] page_title];
			} else if ([aTableColumn.identifier isEqualToString:@"slug"]) {
				return [(BPPage *)[self.project_pages objectAtIndex:rowIndex] page_slug];
			}
		}

		case 2:
		{
			return @"resource";
		}

		default: return nil;
	}
}

#pragma mark - Table view delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView *table = notification.object;
	if (table.selectedRow >= 0) {
		switch (table.tag) {
			case 1:
			{
				[self.button_removePage setEnabled:YES];
				[self.button_editPage setEnabled:YES];
			}
			case 2:
			{
				[self.button_removePage setEnabled:YES];
				[self.button_editPage setEnabled:YES];
			}
		}
	} else {
		[self.button_removePage setEnabled:NO];
		[self.button_editPage setEnabled:NO];
	}
}

@end
