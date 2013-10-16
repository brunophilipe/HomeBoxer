//
//  BPAdvancedSettings.h
//  HomeBoxer
//
//  Created by Bruno Philipe on 10/14/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BPAdvancedSettings : NSWindow

@property (weak) NSMutableDictionary *project_meta;
@property (weak) NSMutableArray *project_resources;

@property (strong) IBOutlet NSPopUpButton *picker_titleMode;
@property (strong) IBOutlet NSTextField *label_iconFilename;
@property (strong) IBOutlet NSTextField *label_gaCode;

- (IBAction)action_controlChanged:(id)sender;

- (IBAction)action_pickIcon:(id)sender;
- (IBAction)action_cancel:(id)sender;
- (IBAction)action_save:(id)sender;

@end
