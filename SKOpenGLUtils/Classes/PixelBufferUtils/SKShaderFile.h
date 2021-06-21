//
//  SKShaderFile.h
//  Pods
//
//  Created by Sunflower on 2021/5/28.
//

#ifndef SKShaderFile_h
#define SKShaderFile_h

#define SKSTRINGIZE(x) #x
#define SKSTRINGIZE2(x) SKSTRINGIZE(x)
#define SK_SHADER_STRING(text) @ SKSTRINGIZE2(text)

NSString *const kSKNormalVertexShaderString = SK_SHADER_STRING
(
 attribute vec3 position;
 attribute vec2 inputTextureCoordinate;
 varying vec2 textureCoordinate;

 void main (void) {
     gl_Position = vec4(position, 1.0);
     textureCoordinate = inputTextureCoordinate;
 }
 );

NSString *const kSKNormalFragmentShaderString =  SK_SHADER_STRING
(
 precision highp float;

 uniform sampler2D renderTexture;
 varying vec2 textureCoordinate;

 void main (void) {
     vec4 mask = texture2D(renderTexture, textureCoordinate);
     gl_FragColor = vec4(mask.rgb, 1.0);
 }
 );


//----------------

NSString *const kSKYUVConversionVertexShaderString = SK_SHADER_STRING
(
 attribute vec3 position;
 attribute vec2 inputTextureCoordinate;
 varying vec2 textureCoordinate;

 void main (void) {
     textureCoordinate = inputTextureCoordinate;
     gl_Position = vec4(position.x, position.y, position.z, 1.0);
 }
 );

NSString *const kSKYUVConversionFragmentShaderString =  SK_SHADER_STRING
(
 precision highp float;

 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mat3 colorConversionMatrix;

 varying vec2 textureCoordinate;

 void main (void) {
     vec3 yuv = vec3(0.0, 0.0, 0.0);
     vec3 rgb = vec3(0.0, 0.0, 0.0);
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1.0);
 }

 );


#endif /* SKShaderFile_h */
