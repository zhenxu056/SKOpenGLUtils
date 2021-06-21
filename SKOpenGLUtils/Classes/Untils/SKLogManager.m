//
//  SKLogManager.m
//
//
//  Created by Sunflower on 2019/11/27.
//

#import "SKLogManager.h"

static BOOL SKLogEnable = YES;

void SKVideoCheckStatus(OSStatus status, NSString *message) {
    if (status == noErr) {
        return;
    }
    
    char fourCC[16];
    *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
    fourCC[4] = '\0';
    if (isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3])) {
        SKLog(@"ERROR: %@ -> %s", message, fourCC);
    } else {
        SKLog(@"ERROR: %@ -> %d", message, (int)status);
    }
}


@implementation SKLogManager

+ (void)setLogEnable:(BOOL)enable {
    SKLogEnable = enable;
}

+ (BOOL)getLogEnable {
    return SKLogEnable;
}

+ (NSString *)version {
    return @"1.0.0";
}

+ (void)logWithFunction:(const char *)function lineNumber:(int)lineNumber formatString:(NSString *)formatString {
    if ([self getLogEnable]) {
        NSLog(@"%s [%d] %@", function, lineNumber, formatString);
    }
}

@end
