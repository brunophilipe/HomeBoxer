//
//  BPDocument.h
//  HomeBoxer
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BPPageWizard.h"
#import "BPResource.h"
#import "BPSiteGenerator.h"
#import "DMTabBar.h"
#import "MarkerLineNumberView.h"

@class DMTabBar;

typedef enum
{
	BP_METADATA_PAGE_TITLE = 1,
	BP_METADATA_AUTHOR_NAME,
	BP_METADATA_AUTHOR_EMAIL
} BP_METADATA;

#define kBP_METADATA_PAGE_TITLE		@"BP_METADATA_PAGE_TITLE"
#define kBP_METADATA_AUTHOR_NAME	@"BP_METADATA_AUTHOR_NAME"
#define kBP_METADATA_AUTHOR_EMAIL	@"BP_METADATA_AUTHOR_EMAIL"
#define kBP_METADATA_METAKEYS		@"BP_METADATA_METAKEYS"
#define kBP_METADATA_METADESC		@"BP_METADATA_METADESC"
#define kBP_METADATA_FOOTERMSG		@"BP_METADATA_FOOTERMSG"
#define kBP_METADATA_LAST_UID		@"BP_METADATA_LAST_UID"

#define kBP_METADATA_FAKEPHP		@"BP_METADATA_FAKEPHP"

#define kBP_ADD_CREATED_PAGE		@"BP_ADD_CREATED_PAGE"

@interface BPHomeBoxerProject : NSDocument <NSTableViewDataSource, NSTableViewDelegate, NSOpenSavePanelDelegate, NSSplitViewDelegate, NSTextDelegate>

@property NSDictionary	*project_metadata;
@property NSArray		*project_pages;
@property NSArray		*project_resources;

@property (strong) IBOutlet NSTextField *info_title;
@property (strong) IBOutlet NSTextField *info_author;
@property (strong) IBOutlet NSTextField *info_authorEmail;
@property (strong) IBOutlet NSTokenField *info_metaKeys;
@property (strong) IBOutlet NSTextField *info_metaDesc;
@property (strong) IBOutlet NSTextField *info_footerMessage;

@property (strong) IBOutlet NSButton *button_addPage;
@property (strong) IBOutlet NSButton *button_removePage;
@property (strong) IBOutlet NSButton *button_editPage;
@property (strong) IBOutlet NSButton *button_setHomePage;
@property (strong) IBOutlet NSButton *button_addResource;
@property (strong) IBOutlet NSButton *button_removeResource;
@property (strong) IBOutlet NSButton *button_copyPageTemplate;
@property (strong) IBOutlet NSButton *button_copyResourceTemplate;
@property (strong) IBOutlet NSButton *button_replaceResource;

@property (strong) IBOutlet NSButton *check_fakePHPExtension;

@property (strong) IBOutlet NSTableView *tableView_pages;
@property (strong) IBOutlet NSTableView *tableView_resources;

@property (strong) IBOutlet NSTabView *tabView;
@property (strong) IBOutlet DMTabBar *tabBar;

@property (strong) IBOutlet NSScrollView *liveEditorContainer;
@property (strong) IBOutlet NSTextView *liveEditor;
@property (strong) IBOutlet NSImageView *livePreview;
@property (strong) IBOutlet NSProgressIndicator *liveActivity;

- (IBAction)updatedMetadata:(id)sender;

- (IBAction)action_addPage:(id)sender;
- (IBAction)action_removePage:(id)sender;
- (IBAction)action_editPage:(id)sender;
- (IBAction)action_setHomePage:(id)sender;
- (IBAction)action_addResource:(id)sender;
- (IBAction)action_replaceResource:(id)sender;
- (IBAction)action_deleteResource:(id)sender;
- (IBAction)action_copyTemplate:(id)sender;
- (IBAction)action_generateSite:(id)sender;
- (IBAction)action_insertTag:(id)sender;

- (IBAction)action_optionUpdated:(id)sender;


- (void)dismissModal;

@end
