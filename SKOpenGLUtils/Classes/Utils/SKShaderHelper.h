//
//  SKShaderHelper.h
//  SK
//
//  Created by SK Li on 2019/4/18.
//  Copyright © 2019年 SK All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKShaderHelper : NSObject

/**
 将一个顶点着色器和一个片段着色器挂载到一个着色器程序上，并返回程序的 id
 
 @param shaderName 着色器名称，顶点着色器应该命名为 shaderName.vsh ，片段着色器应该命名为 shaderName.fsh
 @return 着色器程序的 ID
 */
+ (GLuint)programWithShaderName:(NSString *)shaderName
                 resourceBundle:(NSBundle *)bundle;

// 通过一张图片来创建纹理
+ (GLuint)createTextureWithImage:(UIImage *)image;

/// 编译shader
/// @param name 着色器名称
/// @param shaderType 类型 GL_VERTEX_SHADER   GL_FRAGMENT_SHADER
/// @param bundle 资源Bundle
+ (GLuint)compileShaderWithName:(NSString *)name
                           type:(GLenum)shaderType
                 resourceBundle:(NSBundle *)bundle;

@end
