//
//  BPAdvancedSettings.m
//  HomeBoxer
//
//  Created by Bruno Philipe on 10/14/13.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
//

#import "BPAdvancedSettings.h"

@implementation BPAdvancedSettings
{
	NSMutableDictionary *_project_meta;
}

#pragma mark - IBActions

- (IBAction)action_controlChanged:(id)sender {
}

- (IBAction)action_pickIcon:(id)sender {
}

- (IBAction)action_cancel:(id)sender {
}

- (IBAction)action_save:(id)sender {
}

#pragma mark - Getters and Setters

- (void)setProject_meta:(NSMutableDictionary *)project_meta
{
	_project_meta = project_meta;

	[self.label_gaCode setStringValue:[project_meta objectForKey:kBP_METADATA_GACODE]];
}

- (NSMutableDictionary *)project_meta
{
	return _project_meta;
}

@end
