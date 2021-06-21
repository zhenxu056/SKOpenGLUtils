//
//  SKLogManager.h
//
//
//  Created by Sunflower on 2019/11/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SKLog(format,...)  [SKLogManager logWithFunction:__FUNCTION__ lineNumber:__LINE__ formatString:[NSString stringWithFormat:format, ##__VA_ARGS__]]

NS_ASSUME_NONNULL_BEGIN

void SKVideoCheckStatus(OSStatus status, NSString *message);

@interface SKLogManager : NSObject

// Set the log output status.
+ (void)setLogEnable:(BOOL)enable;

// Gets the log output status.
+ (BOOL)getLogEnable;

/// Get  version.
+ (NSString *)version;

// Log output method.
+ (void)logWithFunction:(const char *)function lineNumber:(int)lineNumber formatString:(NSString *)formatString;

@end

NS_ASSUME_NONNULL_END
