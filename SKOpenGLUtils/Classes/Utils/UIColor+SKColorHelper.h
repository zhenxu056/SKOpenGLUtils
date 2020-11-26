//
//  UIColor+SKColorHelper.h
//  SKOpenGLUtils
//
//  Created by Sunflower on 2020/11/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (SKColorHelper)

/// 获取屏幕位置颜色
/// @param point 位置
- (UIColor *)getPixelColorScreenWindowAtLocation:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
