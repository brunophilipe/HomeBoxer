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

		[(NSMutableDictionary *)self.project_metadata setObject:@"" forKey:kBP_METADATA_PAGE_TITLE];
		[(NSMutableDictionary *)self.project_metadata setObject:@"" forKey:kBP_METADATA_AUTHOR_NAME];
		[(NSMutableDictionary *)self.project_metadata setObject:@"" forKey:kBP_METADATA_AUTHOR_EMAIL];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCreatedPage) name:kBP_ADD_CREATED_PAGE object:nil];

		BPPage *homePage = [[BPPage alloc] init];
		[homePage setTitle:@"Home Page"];
		[homePage setSlug:@"home"];
		[homePage setMode:BP_PAGE_MODE_MARKDOWN];
		[homePage setContents:@"Home Page\n=========\n\nThis is your homepage. Fill it with content!"];
		[homePage setHome:YES];
		[self.project_pages performSelector:@selector(addObject:) withObject:homePage];
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

	NSArray *items = @[
					   [DMTabBarItem tabBarItemWithIcon:[NSImage imageNamed:@"box_icon"] tag:0],
					   [DMTabBarItem tabBarItemWithIcon:[NSImage imageNamed:@"pages"] tag:1],
					   [DMTabBarItem tabBarItemWithIcon:[NSImage imageNamed:@"files"] tag:2]];
	
	[self.tabBar setTabBarItems:items];
	[self.tabBar handleTabBarItemSelection:^(DMTabBarItemSelectionType selectionType, DMTabBarItem *targetTabBarItem, NSUInteger targetTabBarItemIndex) {
		if (selectionType == DMTabBarItemSelectionType_WillSelect) {
			[self.tabView selectTabViewItemAtIndex:targetTabBarItemIndex];

			switch (targetTabBarItemIndex) {
				case 0:
					[self.liveEditorContainer setHidden:YES];
					[self.livePreview setHidden:YES];
					break;

				case 1:
					[self.liveEditorContainer setHidden:NO];
					[self.livePreview setHidden:YES];
					break;

				case 2:
					[self.liveEditorContainer setHidden:YES];
					[self.livePreview setHidden:NO];
					break;
			}
		}
	}];

	MarkerLineNumberView *lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:self.liveEditorContainer];

	[self.liveEditorContainer setVerticalRulerView:lineNumberView];
	[self.liveEditorContainer setHasHorizontalRuler:NO];
	[self.liveEditorContainer setHasVerticalRuler:YES];
	[self.liveEditorContainer setRulersVisible:YES];

	[self.liveEditor setFont:[NSFont userFixedPitchFontOfSize:11]];

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
	NSBlockOperation *opr = [NSBlockOperation blockOperationWithBlock:^{
		[self.tableView_pages beginUpdates];
		[self.tableView_pages insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.project_pages.count] withAnimation:NSTableViewAnimationSlideRight];
		[self.project_pages performSelector:@selector(addObject:) withObject:createdPage];
		createdPage = nil;
		[self.tableView_pages endUpdates];
	}];
	[opr performSelector:@selector(start) withObject:nil afterDelay:0.3];
}

- (BPPageWizard *)loadPageWizard
{
	NSArray		*topLevelObjects;
	BPPageWizard	*sheet;

	[[NSBundle mainBundle] loadNibNamed:@"PageWizard" owner:nil topLevelObjects:&topLevelObjects];

	for (NSObject *obj in topLevelObjects) {
		if (obj.class == [BPPageWizard class]) {
			sheet = (BPPageWizard *)obj;
			break;
		}
	}

	return sheet;
}

- (NSString *)metadataValueOrDefaultForKey:(NSString *)key
{
	NSString *value = [self.project_metadata objectForKey:key];

	if (!value || ([value isEqualToString:@""])) {
		if ([key isEqualToString:kBP_METADATA_PAGE_TITLE]) {
			return @"John's Website";
		} else if ([key isEqualToString:kBP_METADATA_AUTHOR_NAME]) {
			return @"John Appleseed";
		} else if ([key isEqualToString:kBP_METADATA_AUTHOR_EMAIL]) {
			return @"john.apple@example.com";
		}
	}

	return value;
}

#pragma mark - IBActions

- (IBAction)updatedMetadata:(id)sender {
	[(NSMutableDictionary *)self.project_metadata setObject:self.info_title.stringValue forKey:kBP_METADATA_PAGE_TITLE];
	[(NSMutableDictionary *)self.project_metadata setObject:self.info_author.stringValue forKey:kBP_METADATA_AUTHOR_NAME];
	[(NSMutableDictionary *)self.project_metadata setObject:self.info_authorEmail.stringValue forKey:kBP_METADATA_AUTHOR_EMAIL];
}

- (IBAction)action_addPage:(id)sender {
	BPPageWizard *sheet = [self loadPageWizard];

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
	NSInteger index = [self.tableView_pages selectedRow];
	if (index >= 0) {
		[self.tableView_pages beginUpdates];
		[self.tableView_pages removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideRight];
		[(NSMutableArray *)self.project_pages removeObjectAtIndex:index];
		[self.tableView_pages endUpdates];
	}
}

- (IBAction)action_editPage:(id)sender {
	BPPageWizard *sheet = [self loadPageWizard];

	[sheet setPage:[self.project_pages objectAtIndex:self.tableView_pages.selectedRow]];
	[sheet setIsNewPage:NO];
	[sheet makeKeyWindow];

	[NSApp beginSheet:sheet modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:sheet];

    [NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (IBAction)action_setHomePage:(id)sender {
	if (self.tableView_pages.selectedRow >= 0) {
		for (BPPage *page in self.project_pages) {
			[page setHome:NO];
		}
		[[self.project_pages objectAtIndex:self.tableView_pages.selectedRow] setHome:YES];
	}
	[self.tableView_pages reloadData];
}

- (IBAction)action_addResource:(id)sender {
}

- (IBAction)action_deleteResource:(id)sender {
}

- (IBAction)action_copyTemplate:(id)sender {
}

- (IBAction)action_generateSite:(id)sender {
	[self updatedMetadata:nil];

	NSSavePanel *panel = [NSSavePanel savePanel];
	NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 250, 50)];

	[field setStringValue:@"Select a place to export your website.\nA folder with the name inserted above will be created in this place."];
	[field setBordered:NO];
	[field setBackgroundColor:[NSColor clearColor]];
	[field setEditable:NO];
	[field setAlignment:NSCenterTextAlignment];
	[field sizeToFit];

	[panel setTitle:@"Exporting Website"];
	[panel setAccessoryView:field];
	[panel setNameFieldStringValue:[self metadataValueOrDefaultForKey:kBP_METADATA_PAGE_TITLE]];
	[panel setAllowedFileTypes:@[@"public.folder"]];

	[panel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result){
		if (result) {
			NSURL *url = [[panel directoryURL] URLByAppendingPathComponent:panel.nameFieldStringValue];

			[BPSiteGenerator generateSiteAtURL:url withMetadata:self.project_metadata pages:self.project_pages andResources:self.project_resources];
		}
	}];
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
			BPPage *page = [self.project_pages objectAtIndex:rowIndex];
			if ([aTableColumn.identifier isEqualToString:@"icon"]) {
				if (page.isHome) return [NSImage imageNamed:NSImageNameHomeTemplate];
				else return [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
			} else if ([aTableColumn.identifier isEqualToString:@"title"]) {
				NSString *type;
				switch (page.mode) {
					case BP_PAGE_MODE_HTML:
						type = @"HTML";
						break;

					case BP_PAGE_MODE_MARKDOWN:
						type = @"Markdown";
						break;

					case BP_PAGE_MODE_PLAINTEXT:
						type = @"plain text";
						break;
				}
				return [NSString stringWithFormat:@"%@ – %@",page.title,type];
			} else if ([aTableColumn.identifier isEqualToString:@"slug"]) {
				return page.slug;
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
				[self.button_removePage setEnabled:![[self.project_pages objectAtIndex:table.selectedRow] isHome]];
				[self.button_setHomePage setEnabled:![[self.project_pages objectAtIndex:table.selectedRow] isHome]];
				[self.button_editPage setEnabled:YES];

				[self.liveEditor setString:[(BPPage *)[self.project_pages objectAtIndex:table.selectedRow] contents]];
				break;
			}
			case 2:
			{
				[self.button_removeResource setEnabled:YES];
				[self.button_copyTemplate setEnabled:YES];
				break;
			}
		}
	} else {
		[self.button_removePage setEnabled:NO];
		[self.button_editPage setEnabled:NO];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex
{
	return columnIndex != 0 && newColumnIndex != 0;
}

#pragma mark - Split View Delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	return splitView.frame.size.width - 250;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return 250;
}

#pragma mark - Text Delegate

- (void)textDidChange:(NSNotification *)aNotification
{
	[(BPPage *)[self.project_pages objectAtIndex:[self.tableView_pages selectedRow]] setContents:[self.liveEditor.string copy]];
}

@end
