//
//  BPPageWizard.m
//  DoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPPageWizard.h"
#import "BPDocument.h"

@implementation BPPageWizard

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (IBAction)action_cancel:(id)sender {
	[NSApp stopModal];
}

- (IBAction)action_save:(id)sender {
	[self.page setPage_contents:self.text_pageContent.stringValue];
	[self.page setPage_slug:self.label_pageSlug.stringValue];
	[self.page setPage_title:self.label_pageTitle.stringValue];

	BP_PAGE_MODE mode = BP_PAGE_MODE_HTML;

	if ([self.picker_pageMode.selectedItem.title isEqualToString:@"HTML"]) {
		mode = BP_PAGE_MODE_HTML;
	} else if ([self.picker_pageMode.selectedItem.title isEqualToString:@"Markdown"]) {
		mode = BP_PAGE_MODE_MARKDOWN;
	} else if ([self.picker_pageMode.selectedItem.title isEqualToString:@"Plain Text"]) {
		mode = BP_PAGE_MODE_PLAINTEXT;
	}

	[self.page setPage_mode:mode];

	if (self.isNewPage) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kBP_ADD_CREATED_PAGE object:self];
	}

	[NSApp stopModal];
}
@end
