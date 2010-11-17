/*
 *
 * ServiceMonitorAppDelegate.m
 *  
 * Copyright (c) 2010, Martin Jonsson
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * * Neither the name of the <organization> nor the
 * names of its contributors may be used to endorse or promote products
 * derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ServiceMonitorAppDelegate.h"
#import "JAProcessInfo.h"
#import "CommandRunner.h"
#import "PFMoveApplication.h"

@interface ServiceMonitorAppDelegate (Private)
- (void)loadDefaults;
- (void)buildServiceMenu;
@end

@implementation ServiceMonitorAppDelegate

@synthesize window, statusMenu, itemMap;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	PFMoveToApplicationsFolderIfNecessary();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self loadDefaults];
	
	menuDelegate = [[ServiceMonitorMenuDelegate alloc] init];
	[statusMenu setDelegate:menuDelegate];
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain]; 
	[statusItem setMenu:statusMenu];
	[statusItem setImage:[NSImage imageNamed:@"menu-icon.png"]];
	[statusItem setHighlightMode:YES];	

	[self buildServiceMenu];
	[statusMenu addItem:[NSMenuItem separatorItem]];
	[statusMenu addItemWithTitle:@"Quit Service Monitor" action:@selector(terminate:) keyEquivalent:@""];

}

#pragma mark UserDefaults
- (void)loadDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//This doesn't overide any user settings only loading the default values
	NSString *path = [[NSBundle mainBundle] pathForResource:@"ServiceDefaults" ofType:@"plist"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];		
	[defaults registerDefaults:dict];		
	
	//Store defaults for user so they can change it.
	if (![defaults boolForKey:@"defaultsStored"]) {
		[defaults setBool:YES forKey:@"defaultsStored"];
		[defaults setObject:[defaults objectForKey:@"Services"] forKey:@"Services"];
		[defaults synchronize];
	}
}

- (NSMenu *)createSubMenu:(NSArray *)items {
	NSMenu *menu = [[NSMenu alloc] init];
	
	for (NSDictionary *item in items) {
		NSMenuItem *menuItem = [menu addItemWithTitle:[item objectForKey:@"Title"] action:@selector(executeServiceCommand:) keyEquivalent:@""];		
		[menuItem setTag:tagSequencer];		
		[self.itemMap setObject:item forKey:[NSNumber numberWithInt:tagSequencer]];
		tagSequencer++;
	}	

	return [menu autorelease];
}

- (void)buildServiceMenu {
	self.itemMap = [NSMutableDictionary dictionary];
	tagSequencer = 10;
	
	NSDictionary *services = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"Services"];
	NSMutableDictionary *processItems = [NSMutableDictionary dictionary];
	
	for (NSDictionary *service in services) { 
		NSMenu *serviceMenu = [[self createSubMenu:[service objectForKey:@"Items"]] retain];		
		
		NSMenuItem *serviceItem = [statusMenu addItemWithTitle:[service objectForKey:@"Name"] action:NULL keyEquivalent:@""];
		[serviceItem setTag:tagSequencer];
		[processItems setObject:[service objectForKey:@"ProcessName"] forKey:[NSNumber numberWithInt:tagSequencer]];
		tagSequencer++;
		
		[statusMenu setSubmenu:serviceMenu forItem:serviceItem];

		[serviceMenu release];		
	}	
	
	menuDelegate.items = processItems;			
}

- (void)executeServiceCommand:(id)sender {
	NSDictionary *item = [self.itemMap objectForKey:[NSNumber numberWithInt:[sender tag]]];
	NSArray *commands = [item objectForKey:@"Commands"];
	BOOL superUser = [[item objectForKey:@"SuperUser"] isEqualToNumber:[NSNumber numberWithInt:1]];

	CommandRunner *runner = [[CommandRunner alloc] initWithCommands:commands authenticate:superUser];
	[runner performSelectorInBackground:@selector(runCommands) withObject:nil];
	[runner release];

	if (![NSApp isActive]) {
		[NSApp activateIgnoringOtherApps:YES];
	}
}

- (void)dealloc {
	[menuDelegate release];
	[statusItem release];
	[itemMap release];
	[super dealloc];
}

@end
