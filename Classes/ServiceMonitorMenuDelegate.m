/*
 *
 * ServiceMonitorMenuDelegate.m
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

#import "ServiceMonitorMenuDelegate.h"
#import "JAProcessInfo.h"

@implementation ServiceMonitorMenuDelegate
@synthesize items;

- (void)menuWillOpen:(NSMenu *)menu {
	JAProcessInfo *procInfo = [[JAProcessInfo alloc] init];
	[procInfo obtainFreshProcessList];

	NSArray *menuItems = [menu itemArray];
	NSImage *imgRunning = [NSImage imageNamed:@"bullet-green.png"];
	NSImage *imgStopped = [NSImage imageNamed:@"bullet-red.png"];
	
	for (NSMenuItem *menuItem in menuItems) {
		NSString *processName = [self.items objectForKey:[NSNumber numberWithInt:[menuItem tag]]];
		
		if (processName == nil) {
			continue;
		}
		
		if ([procInfo findProcessWithName:processName]) {
			[menuItem setImage:imgRunning];
		} else {
			[menuItem setImage:imgStopped];
		}
	}
	
	[procInfo release];
}

- (void)dealloc {
	[items release];
	[super dealloc];
}
@end
