/*
 *
 * JAProcessInfo.h
 * 
 * Author: http://jongampark.wordpress.com/2008/01/26/a-simple-objectie-c-class-for-checking-if-a-specific-process-is-running/
 * 
 */
#import <Cocoa/Cocoa.h> 

@interface JAProcessInfo : NSObject {
	
@private
    int numberOfProcesses;
    NSMutableArray *processList;
}
- (id) init;
- (int)numberOfProcesses;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;
@end