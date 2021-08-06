//
//  NSBundle+SKResource.m
//  Pods-SKOpenGLUtilsLib
//
//  Created by Sunflower on 2020/4/28.
//

#import "NSBundle+SKResource.h"

@implementation NSBundle (SKResource)

+ (NSBundle *)SKBundle {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SKResource" ofType:@"bundle"];
//    NSString *path = [[[NSBundle bundleForClass: [self class]] resourcePath] stringByAppendingPathComponent:@"SKOpenGLUtils.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    return bundle;
}

@end
