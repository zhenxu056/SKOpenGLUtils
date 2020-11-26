//
//  UIImage+SKImageHelper.h
//  SKOpenGLUtils
//
//  Created by Sunflower on 2020/11/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (SKImageHelper)

/// 获取RGBA数据
- (unsigned char *)getRGBAWithImage;

/// RGBA数据转图片
/// @param buffer RGBA数据
/// @param width 宽度
/// @param height 高度
- (UIImage *)convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                               withWidth:(int)width
                              withHeight:(int)height;

/// 屏幕截图
+ (UIImage *)fullScreenshots;

/// 获取CGContextRef
- (CGContextRef)createARGBBitmapContextFromImage;

@end

NS_ASSUME_NONNULL_END
