//
//  BPPageWizard.h
//  DoneHome
//
//  Created by Bruno Philipe on 9/17/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BPPage.h"

@class BPPage;

@interface BPPageWizard : NSWindow

@property (weak, nonatomic) BPPage *page;

@property (strong) IBOutlet NSTextField *label_pageTitle;
@property (strong) IBOutlet NSTextField *label_pageSlug;
@property (strong) IBOutlet NSPopUpButton *picker_pageMode;
@property (strong) IBOutlet NSTextField *text_pageContent;

@property BOOL isNewPage;

- (IBAction)action_cancel:(id)sender;
- (IBAction)action_save:(id)sender;

@end
