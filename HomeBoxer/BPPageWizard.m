//
//  BPPageWizard.m
//  HomeBoxer
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPPageWizard.h"
#import "BPDocument.h"

@implementation BPPageWizard
{
	BPPage *_page;
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (IBAction)action_cancel:(id)sender {
	[NSApp stopModal];
}

- (IBAction)action_save:(id)sender {
	[self.page setSlug:self.label_pageSlug.stringValue];
	[self.page setTitle:self.label_pageTitle.stringValue];

	BP_PAGE_MODE mode = BP_PAGE_MODE_MARKDOWN;

	if ([self.picker_pageMode.selectedItem.title isEqualToString:@"HTML"]) {
		mode = BP_PAGE_MODE_HTML;
	} else if ([self.picker_pageMode.selectedItem.title isEqualToString:@"Markdown"]) {
		mode = BP_PAGE_MODE_MARKDOWN;
	} else if ([self.picker_pageMode.selectedItem.title isEqualToString:@"Plain Text"]) {
		mode = BP_PAGE_MODE_PLAINTEXT;
	}

	[self.page setMode:mode];

	if (self.isNewPage) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kBP_ADD_CREATED_PAGE object:self];
	}

	[NSApp stopModal];
}

#pragma mark - Custom Getters and Setters

- (BPPage *)page
{
	return _page;
}

- (void)setPage:(BPPage *)page
{
	_page = page;

	[self.label_pageTitle setStringValue:self.page.title];
	[self.label_pageSlug setStringValue:self.page.slug];
	[self.picker_pageMode selectItemAtIndex:self.page.mode];
}
@end
