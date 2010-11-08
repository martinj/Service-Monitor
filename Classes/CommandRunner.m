/*
 *
 * CommandRunner.m
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


#import "CommandRunner.h"


@implementation CommandRunner

- (id)initWithCommands:(NSArray *)commands authenticate:(BOOL)authenticate {
	if (self = [super init]) {
		_commands = [commands retain];
		_authenticate = authenticate;
		_authorizationRef == NULL;
		_authCommandPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/AuthenticatedCommand"] copy];
	}
	
	return self;
}

- (AuthorizationRef)createAuthorizationRef {
	OSStatus status;
	AuthorizationFlags flags = kAuthorizationFlagDefaults;
	AuthorizationRef authRef;
	AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authRef);
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authRef);
	
	if (status != errAuthorizationSuccess) {
		AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
		return NULL;
	}
	
	AuthorizationItem authItems = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights authRights = {1, &authItems};
	
	flags = kAuthorizationFlagDefaults |
			kAuthorizationFlagInteractionAllowed |
			kAuthorizationFlagPreAuthorize |
			kAuthorizationFlagExtendRights;
	
	status = AuthorizationCopyRights(authRef, &authRights, NULL, flags, NULL);
	
	if (status != errAuthorizationSuccess) {
		AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);			
		return NULL;
	}
	
	return authRef;
}

- (void)executeAuthenticatedCommand:(NSString *)cmd arguments:(NSArray *)args authorizationRef:(AuthorizationRef)authRef {
	NSMutableArray *cmdArguments = [NSMutableArray arrayWithObjects:cmd, nil];
	[cmdArguments addObjectsFromArray:args];			
	
	int argCount = [cmdArguments count];
	char **arguments = (char **) malloc(sizeof(char *) * (argCount + 1));
	
	for (int i = 0 ; i < argCount ; i++) { 
		const char *cArg = [[cmdArguments objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding];
		int len = strlen(cArg);		
		char *arg = (char *) malloc(sizeof(char) * (len + 1)); //+ 1 for ending '\0'
		strcpy(arg, cArg);
		arguments[i] = arg;
	}
	
	arguments[argCount] = NULL;
	
	FILE *ioPipe = NULL;		
	AuthorizationExecuteWithPrivileges(authRef, [_authCommandPath cStringUsingEncoding:NSUTF8StringEncoding], kAuthorizationFlagDefaults, arguments, &ioPipe);							
	char *tmp; 
	char buff[256];
	
	if (ioPipe) {
		// We use the pipe to signal us when the command has completed
		do {
			tmp = fgets(buff, sizeof(buff), ioPipe);
		} while (tmp);
		
		fclose (ioPipe);
	}
	
	// AuthorizationExecuteWithPrivileges() does a fork() and we want to remove those zombie processes.
	while(waitpid(-1, 0, WNOHANG) > 0);
	
	
	for(int i = 0; i < argCount; i++) {
		free(arguments[i]);
	}
	
	free(arguments);
	
}

- (void)executeCommand:(NSString *)cmd arguments:(NSArray *)args {
	[NSTask launchedTaskWithLaunchPath:cmd arguments:args];
}

- (void)runCommands {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//this method should be threaded.
	[self retain];
	
	if (_authenticate && _authorizationRef == NULL) {
		_authorizationRef = [self createAuthorizationRef];
	}
	
	for (NSDictionary *command in _commands) {
		NSString *cmd = [command objectForKey:@"Command"];
		NSArray *args = [command objectForKey:@"Arguments"];

		if (_authenticate) {
			[self executeAuthenticatedCommand:cmd arguments:args authorizationRef:_authorizationRef];
		} else {
			[self executeCommand:cmd arguments:args];
		}
		
		//ugly fix but sleep is sometimes needed for launchd process if we want to run 2 commands to emulate restart
		//should add this as option in plist
		[NSThread sleepForTimeInterval:2];
	}		

	AuthorizationFree(_authorizationRef, kAuthorizationFlagDestroyRights);
	[self release];
	[pool release];
}

- (void)dealloc {
	[_commands release];
	[_authCommandPath release];
	[super dealloc];
}

@end
