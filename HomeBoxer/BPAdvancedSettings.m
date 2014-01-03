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

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

#pragma mark - IBActions

- (IBAction)action_controlChanged:(id)sender {
}

- (IBAction)action_pickIcon:(id)sender {
}

- (IBAction)action_cancel:(id)sender {
	[NSApp stopModal];
}

- (IBAction)action_save:(id)sender {

	[NSApp stopModal];
}

#pragma mark - Getters and Setters

- (void)setProject_meta:(NSMutableDictionary *)project_meta
{
	_project_meta = project_meta;

	id aux;

	aux = [project_meta objectForKey:kBP_MD_GACODE];
	if (!aux) aux = @"";
	[self.label_gaCode setStringValue:aux];

	aux = [project_meta objectForKey:kBP_MD_TITLEMODE];
//	if (!aux) aux = [NSNumber numberWithInt:<#(int)#>];

}

- (NSMutableDictionary *)project_meta
{
	return _project_meta;
}

@end
