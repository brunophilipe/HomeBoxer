//
//  BPDocument.m
//  GoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPHomeBoxerProject.h"

@implementation BPHomeBoxerProject
{
	BPPage *createdPage;
	time_t lastInteractionTime;
	BOOL didSave;
	MarkerLineNumberView *lineNumberView;
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
		[(NSMutableDictionary *)self.project_metadata setObject:@"" forKey:kBP_METADATA_METADESC];
		[(NSMutableDictionary *)self.project_metadata setObject:@"" forKey:kBP_METADATA_METAKEYS];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCreatedPage) name:kBP_ADD_CREATED_PAGE object:nil];

		BPPage *homePage = [[BPPage alloc] init];
		[homePage setTitle:@"Home Page"];
		[homePage setSlug:@"home"];
		[homePage setMode:BP_PAGE_MODE_MARKDOWN];
		[homePage setContents:[NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HomeDefault" withExtension:@"md"] encoding:NSUTF8StringEncoding error:nil]];
		[homePage setHome:YES];
		[self.project_pages performSelector:@selector(addObject:) withObject:homePage];

		NSURL *aligURL = [[NSBundle mainBundle] URLForResource:@"alligator" withExtension:@"jpg"];
		[self addResourcesForURLs:@[aligURL]];

		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkLastInteractionTimerFired:) userInfo:nil repeats:YES];

		lastInteractionTime = 0;
    }
    return self;
}

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"BPHomeBoxerProject";
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
					[self.livePreview setHidden:YES];
					break;

				case 2:
					[self.livePreview setHidden:NO];
					break;
			}
		}
	}];

	[self updateContentFromMemory];

	[self.liveEditor setFont:[NSFont userFixedPitchFontOfSize:11]];

	lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:self.liveEditorContainer];

//	[lineNumberView ]

	[self.liveEditorContainer setVerticalRulerView:lineNumberView];
	[self.liveEditorContainer setHasHorizontalRuler:NO];
	[self.liveEditorContainer setHasVerticalRuler:YES];
	[self.liveEditorContainer setRulersVisible:YES];

	[self.liveEditorContainer setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liveEditorDidScroll:) name:NSViewBoundsDidChangeNotification object:self.liveEditorContainer.contentView];

	[self.tableView_pages registerForDraggedTypes:@[@"BP_PAGE_TYPE"]];
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
	[self.info_metaDesc setStringValue:[self.project_metadata objectForKey:kBP_METADATA_METADESC]];
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

- (void)addResourcesForURLs:(NSArray *)urls
{
	BPResource *resource;

	NSNumber *lastUID = [self.project_metadata objectForKey:kBP_METADATA_LAST_UID];
	NSUInteger lUID;

	if (!lastUID) {
		lUID = 0;
	} else {
		lUID = [lastUID unsignedIntegerValue];
	}

	for (NSURL *url in urls) {
		resource = [[BPResource alloc] init];
		[resource setData:[NSData dataWithContentsOfURL:url]];
		[resource setFilename:[url lastPathComponent]];
		[resource setUid:++lUID];

		[self.project_resources performSelector:@selector(addObject:) withObject:resource];
	}

	[(NSMutableDictionary *)self.project_metadata setObject:[NSNumber numberWithUnsignedInteger:lUID] forKey:kBP_METADATA_LAST_UID];

	[self.tableView_resources reloadData];
}

- (void)replaceResourceAtIndex:(NSUInteger)index withResourceInURL:(NSURL *)url
{
	BPResource *oldResource = [self.project_resources objectAtIndex:index];
	BPResource *resource;

	resource = [[BPResource alloc] init];
	[resource setData:[NSData dataWithContentsOfURL:url]];
	[resource setFilename:[url lastPathComponent]];
	[resource setUid:oldResource.uid];

	[(NSMutableArray *)self.project_resources replaceObjectAtIndex:index withObject:resource];

	[self.tableView_resources reloadData];
}

- (void)checkLastInteractionTimerFired:(NSTimer *)timer
{
	if (lastInteractionTime == 0) {
		didSave = NO;
		return;
	}

	time_t timeNow;
	time(&timeNow);

//	NSLog(@"Verifying!");

	if (timeNow+3 > lastInteractionTime) {
		//Event threshold reached
		lastInteractionTime = 0;

		[self.liveActivity startAnimation:nil];

		[(BPPage *)[self.project_pages objectAtIndex:[self.tableView_pages selectedRow]] setContents:[self.liveEditor.string copy]];
		didSave = YES;

		[self.liveActivity performSelector:@selector(stopAnimation:) withObject:nil afterDelay:0.5];
	} else {
		didSave = NO;
	}
}

- (NSOpenPanel *)buildImportResourcePanelWithMessage:(NSString *)msg
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];

	[panel setAllowsOtherFileTypes:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:YES];
	[panel setCanSelectHiddenExtension:YES];

	NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 250, 50)];

	[field setStringValue:msg];
	[field setBordered:NO];
	[field setBackgroundColor:[NSColor clearColor]];
	[field setEditable:NO];
	[field setAlignment:NSCenterTextAlignment];
	[field sizeToFit];

	[panel setAccessoryView:field];

	return panel;
}

- (void)liveEditorDidScroll:(NSNotification *)notification
{
	[lineNumberView setNeedsDisplay:YES];
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
	NSOpenPanel *panel = [self buildImportResourcePanelWithMessage:@"Select one or more files to import into your project."];

	[panel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result){
		if (result) {
			[self addResourcesForURLs:[panel URLs]];
		}
	}];
}

- (IBAction)action_replaceResource:(id)sender {
	NSOpenPanel *panel = [self buildImportResourcePanelWithMessage:@"Select one file to replace the currently selected resource file in your project."];

	[panel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result){
		if (result) {
			[self replaceResourceAtIndex:self.tableView_resources.selectedRow withResourceInURL:[panel URL]];
		}
	}];
}

- (IBAction)action_deleteResource:(id)sender {
	NSAlert *alert = [NSAlert alertWithMessageText:nil defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"Are you sure you want to delete the selected resource files? This operation can not be undone!"];
	if ([alert runModal]) {
		[self.project_resources performSelector:@selector(removeObjectsAtIndexes:) withObject:[self.tableView_resources selectedRowIndexes]];
		[self.tableView_resources reloadData];
	}
}

- (IBAction)action_copyTemplate:(id)sender {
	NSButton *bt = sender;
	switch (bt.tag) {
		case 1:
		{
			NSUInteger row = [self.tableView_pages selectedRow];
			BPPage *page = [self.project_pages objectAtIndex:row];

			[[NSPasteboard generalPasteboard] clearContents];
			[[NSPasteboard generalPasteboard] writeObjects:@[[NSString stringWithFormat:@"{pages.%@}",page.slug]]];
		}
			break;

		case 2:
		{
			NSUInteger row = [self.tableView_resources selectedRow];
			BPResource *res = [self.project_resources objectAtIndex:row];

			[[NSPasteboard generalPasteboard] clearContents];
			[[NSPasteboard generalPasteboard] writeObjects:@[[NSString stringWithFormat:@"{resource.%lu}",(unsigned long)res.uid]]];
		}
			break;

		default:
			break;
	}
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

- (IBAction)action_insertTag:(id)sender
{
	NSMenuItem *item = sender;
	switch (item.tag) {
		case 1:
			[self.liveEditor insertText:@"{project.title}"];
			break;

		case 2:
			[self.liveEditor insertText:@"{project.author}"];
			break;

		case 3:
			[self.liveEditor insertText:@"{project.email}"];
			break;

		case 4:
			[self.liveEditor insertText:@"{page.title}"];
			break;

		case 5:
			[self.liveEditor insertText:@"{page.slug}"];
			break;

		default:
			break;
	}
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
			BPResource *res = [self.project_resources objectAtIndex:rowIndex];
			if ([aTableColumn.identifier isEqualToString:@"id"]) {
				return [NSNumber numberWithUnsignedInteger:res.uid];
			} else if ([aTableColumn.identifier isEqualToString:@"filename"]) {
				return res.filename;
			}
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
				[self.button_copyPageTemplate setEnabled:YES];
				[self.liveEditorContainer setHidden:NO];

				[self.liveEditor setString:[(BPPage *)[self.project_pages objectAtIndex:table.selectedRow] contents]];
				break;
			}
			case 2:
			{
				[self.button_removeResource setEnabled:YES];
				[self.button_copyResourceTemplate setEnabled:YES];
				[self.button_replaceResource setEnabled:YES];

//				[self.livePreview setImage:<#(NSImage *)#>]
				break;
			}
		}
	} else {
		switch (table.tag) {
			case 1:
			{
				[self.button_removePage setEnabled:NO];
				[self.button_editPage setEnabled:NO];
				[self.button_replaceResource setEnabled:NO];
				[self.button_copyPageTemplate setEnabled:NO];
				[self.liveEditorContainer setHidden:YES];
				break;
			}

			case 2:
			{
				[self.button_removeResource setEnabled:NO];
				[self.button_copyResourceTemplate setEnabled:NO];
				break;
			}

			default:
				break;
		}
	}
}


- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)to dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *rowData = [pboard dataForType:@"BP_PAGE_TYPE"];
	NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	NSUInteger from = [rowIndexes firstIndex];

	if (from == to) {
		return NO;
	}

//	[(NSMutableArray *)self.project_pages exchangeObjectAtIndex:from withObjectAtIndex:MIN(to,self.project_pages.count-1)];
	[self.tableView_pages beginUpdates];
	id source = [(NSMutableArray *)self.project_pages objectAtIndex:from];
	[(NSMutableArray *)self.project_pages insertObject:source atIndex:to];
	[(NSMutableArray *)self.project_pages removeObjectAtIndex:(from > to ? from+1 : from)];
	[self.tableView_pages endUpdates];

//	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:target] byExtendingSelection:NO];

	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([info draggingSource] == self.tableView_pages) {
        if (operation == NSTableViewDropOn){
            [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
        }
        return NSDragOperationMove;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	if (aTableView.tag == 1) {
		NSMutableArray *names = [NSMutableArray array];
		NSUInteger *rows = malloc(sizeof(NSUInteger)*[rowIndexes count]);
		NSUInteger count = [rowIndexes getIndexes:rows maxCount:NSUIntegerMax inIndexRange:nil];
		for (NSUInteger i=0; i<count; i++) {
			[names addObject:[[self.project_pages objectAtIndex:rows[i]] performSelector:@selector(title)]];
		}
		[pboard writeObjects:names];
		[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:@"BP_PAGE_TYPE"];
		return YES;
	} else {
		return NO;
	}
}

#pragma mark - Split View Delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	return splitView.frame.size.width - 490;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return 310;
}

#pragma mark - Text Delegate

- (void)textDidChange:(NSNotification *)aNotification
{
	time(&lastInteractionTime);
}

@end
