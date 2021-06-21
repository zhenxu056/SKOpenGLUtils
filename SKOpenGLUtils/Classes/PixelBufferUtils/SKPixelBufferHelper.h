//
//  SKPixelBufferHelper.h
//
//
//  Created by Sunflower
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 视频帧buffer
@interface SKPixelBufferHelper : NSObject

/// 初始化
/// @param context 上下文
- (instancetype)initWithContext:(EAGLContext *)context;

/// YUV 格式的 PixelBuffer 转化为纹理
/// @param pixelBuffer YUV Buffer
- (GLuint)convertYUVPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer;

/// RBG 格式的 PixelBuffer 转化为纹理
/// @param pixelBuffer RGBA Buffer
- (GLuint)convertRGBPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer;

/// 纹理转化为 RGB 格式的 pixelBuffer
/// @param texture RGBA纹理ID
/// @param textureSize 纹理大小
- (CVPixelBufferRef)convertTextureToPixelBuffer:(GLuint)texture
                                    textureSize:(CGSize)textureSize;

/// 纹理转化为 RGB 格式的 pixelBuffer
/// @param texture 纹理
/// @param textureSize  纹理大小
/// @param pixelBuffer 渲染的buffer
- (CVPixelBufferRef)convertTextureToPixelBuffer:(GLuint)texture
                                    textureSize:(CGSize)textureSize
                                    pixelBuffer:(CVPixelBufferRef)pixelBuffer;

#pragma mark - Unit

/// Copy一份 Buffer
/// @param videoPixelBuffer RGB Buffer
+ (CVPixelBufferRef)copyPixelBufferWithBuffer:(CVPixelBufferRef)videoPixelBuffer;

/// 创建 RGB 格式的 pixelBuffer
/// @param size 帧大小
+ (CVPixelBufferRef)createPixelBufferWithSize:(CGSize)size;

/// RGBA Buffer 生成 图片
/// @param pixelBufferRef RGBA Buffer
+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef;

/// 图片生成 RGBA Buffer
/// @param image 图片
+ (CVPixelBufferRef)pixelBufferFromImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
