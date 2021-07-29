//
//  GTVPixelBufferRefDisplayView.m
//  MiguC
// 
//  Copyright © 2019年 咪咕动漫. All rights reserved.
//

#import "SKPixelBufferRefDisplayView.h"
#import <CoreVideo/CoreVideo.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define STRINGIZE(x)    #x
#define STRINGIZE2(x)    STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString *const SKGTVFUYUVToRGBAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1.0);
 }
 );

NSString *const SKGTVFURGBAFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying highp vec2 textureCoordinate;
 
 void main()
{
    gl_FragColor = vec4(texture2D(inputImageTexture, textureCoordinate).rgb,1.0);
}
 );

NSString *const SKGTVFUVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const SKGTVFUPointsFrgShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec4 fragmentColor;
 
 void main()
{
    gl_FragColor = fragmentColor;
}
 
 );

NSString *const SKGTVFUPointsVtxShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 attribute float point_size;
 
 attribute vec4 inputColor;
 
 varying vec4 fragmentColor;
 
 void main()
{
    gl_Position = position;
    
    gl_PointSize = point_size;
    
    fragmentColor = inputColor;
}
 );

enum
{
    furgbaPositionAttribute,
    furgbaTextureCoordinateAttribute,
    fuPointSize,
    fuPointColor,
};

enum
{
    fuyuvConversionPositionAttribute,
    fuyuvConversionTextureCoordinateAttribute
};

@interface SKPixelBufferRefDisplayView()

@property (nonatomic, strong) EAGLContext *glContext;

@property(nonatomic) dispatch_queue_t contextQueue;

@end

@implementation SKPixelBufferRefDisplayView {
    GLuint rgbaProgram;
    GLuint rgbaToYuvProgram;
    GLuint pointProgram;
    
    CVOpenGLESTextureCacheRef videoTextureCache;
    
    GLuint frameBufferHandle;
    GLuint renderBufferHandle;
    
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLint yuvConversionMatrixUniform;
    GLint displayInputTextureUniform;
    
    GLfloat vertices[8];
    
    int frameWidth;
    int frameHeight;
    int backingWidth;
    int backingHeight;
    
    CGSize boundsSizeAtFrameBufferEpoch;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame] ) {
        
        self.contextQueue = dispatch_queue_create("com.faceunity.contextQueue", DISPATCH_QUEUE_SERIAL);
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking :[NSNumber numberWithBool:NO],
                                          kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
        
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!self.glContext) {
            NSLog(@"failed to create context");
            return nil;
        }
        
        if (!videoTextureCache) {
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &videoTextureCache);
            if (err != noErr) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            }
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // The frame buffer needs to be trashed and re-created when the view size changes.
    if (!CGSizeEqualToSize(self.bounds.size, boundsSizeAtFrameBufferEpoch) &&
        !CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        
        boundsSizeAtFrameBufferEpoch = self.bounds.size;
        dispatch_sync(self.contextQueue, ^{
            [self destroyDisplayFramebuffer];
            [self createDisplayFramebuffer];
            [self updateVertices];
        });
    }
}

- (void)dealloc {
    dispatch_sync(self.contextQueue, ^{
        [self destroyDisplayFramebuffer];
        [self destoryProgram];
        
        if(self->videoTextureCache) {
            CFRelease(self->videoTextureCache);
            self->videoTextureCache = NULL;
        }
    });
}

- (void)createDisplayFramebuffer {
    [EAGLContext setCurrentContext:self.glContext];
    
    glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    glGenRenderbuffers(1, &renderBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBufferHandle);
    CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if ((backingWidth == 0) || (backingHeight == 0)) {
        [self destroyDisplayFramebuffer];
        return;
    }
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBufferHandle);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)destroyDisplayFramebuffer {
    [EAGLContext setCurrentContext:self.glContext];
    
    if (frameBufferHandle)
    {
        glDeleteFramebuffers(1, &frameBufferHandle);
        frameBufferHandle = 0;
    }
    
    if (renderBufferHandle)
    {
        glDeleteRenderbuffers(1, &renderBufferHandle);
        renderBufferHandle = 0;
    }
}

- (void)setDisplayFramebuffer {
    if (!frameBufferHandle)
    {
        [self createDisplayFramebuffer];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    glViewport(0, 0, (GLint)backingWidth, (GLint)backingHeight);
}

- (void)destoryProgram{
    if (rgbaProgram) {
        glDeleteProgram(rgbaProgram);
        rgbaProgram = 0;
    }
    
    if (rgbaToYuvProgram) {
        glDeleteProgram(rgbaToYuvProgram);
        rgbaToYuvProgram = 0;
    }
    
    if (pointProgram) {
        glDeleteProgram(pointProgram);
        pointProgram = 0;
    }
}

- (void)presentFramebuffer {
    glBindRenderbuffer(GL_RENDERBUFFER, renderBufferHandle);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (pixelBuffer == NULL) return;
    
    CVPixelBufferRetain(pixelBuffer);
    dispatch_sync(self.contextQueue, ^{
        
        self->frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        self->frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        if ([EAGLContext currentContext] != self.glContext) {
            if (![EAGLContext setCurrentContext:self.glContext]) {
                NSLog(@"fail to setCurrentContext");
            }
        }
        
        [self setDisplayFramebuffer];
        
        OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
        if (type == kCVPixelFormatType_32BGRA)
        {
            [self prepareToDrawBGRAPixelBuffer:pixelBuffer];
            
        }else{
            [self prepareToDrawYUVPixelBuffer:pixelBuffer];
        }
        
        CVPixelBufferRelease(pixelBuffer);
        [self presentFramebuffer];
    });
}

- (void)prepareToDrawBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!rgbaProgram) {
        [self loadShadersRGBA];
    }
    
    CVOpenGLESTextureRef rgbaTexture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, frameWidth, frameHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &rgbaTexture);
    
    if (!rgbaTexture || err) {
        
        NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
        return;
    }
    
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(rgbaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glUseProgram(rgbaProgram);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(rgbaTexture));
    glUniform1i(displayInputTextureUniform, 4);
    
    [self updateVertices];
    
    // 更新顶点数据
    glVertexAttribPointer(furgbaPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(furgbaPositionAttribute);
    
    GLfloat quadTextureData[] =  {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    glVertexAttribPointer(furgbaTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
    glEnableVertexAttribArray(furgbaTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if (rgbaTexture) {
        CFRelease(rgbaTexture);
        rgbaTexture = NULL;
    }
}

- (void)prepareToDrawYUVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!rgbaToYuvProgram) {
        [self loadShadersYUV];
    }
    
    CVReturn err;
    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;
    
    /*
     CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture optimally from CVPixelBufferRef.
     */
    
    /*
     Create Y and UV textures from the pixel buffer. These textures will be drawn on the frame buffer Y-plane.
     */
    glActiveTexture(GL_TEXTURE0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       frameWidth,
                                                       frameHeight,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &luminanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(luminanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       frameWidth / 2,
                                                       frameHeight / 2,
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &chrominanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(chrominanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glClearColor(0.1f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Use shader program.
    glUseProgram(rgbaToYuvProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(luminanceTextureRef));
    glUniform1i(yuvConversionLuminanceTextureUniform, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(chrominanceTextureRef));
    glUniform1i(yuvConversionChrominanceTextureUniform, 1);
    
    GLfloat kColorConversion601FullRange[] = {
        1.0,    1.0,    1.0,
        0.0,    -0.343, 1.765,
        1.4,    -0.711, 0.0,
    };
    
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, kColorConversion601FullRange);
    
    // 更新顶点数据
    [self updateVertices];
    
    glVertexAttribPointer(fuyuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(fuyuvConversionPositionAttribute);
    
    GLfloat quadTextureData[] =  {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    glVertexAttribPointer(fuyuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
    glEnableVertexAttribArray(fuyuvConversionTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if (luminanceTextureRef) {
        CFRelease(luminanceTextureRef);
        luminanceTextureRef = NULL;
    }
    
    if (chrominanceTextureRef) {
        CFRelease(chrominanceTextureRef);
        chrominanceTextureRef = NULL;
    }
}

- (void)updateVertices {
    const float width   = frameWidth;
    const float height  = frameHeight;
    const float dH      = (float)backingHeight / height;
    const float dW      = (float)backingWidth      / width;
    const float dd      = MAX(dH, dW);
    const float h       = (height * dd / (float)backingHeight);
    const float w       = (width  * dd / (float)backingWidth );
    
    vertices[0] = - w;
    vertices[1] = - h;
    vertices[2] =   w;
    vertices[3] = - h;
    vertices[4] = - w;
    vertices[5] =   h;
    vertices[6] =   w;
    vertices[7] =   h;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShadersRGBA{
    GLuint vertShader, fragShader;
    
    if (!rgbaProgram) {
        rgbaProgram = glCreateProgram();
    }
    
    // Create and compile the vertex shader.
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER string:SKGTVFUVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER string:SKGTVFURGBAFragmentShaderString]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(rgbaProgram, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(rgbaProgram, fragShader);
    
    // Bind attribute locations. This needs to be done prior to linking.
    glBindAttribLocation(rgbaProgram, furgbaPositionAttribute, "position");
    glBindAttribLocation(rgbaProgram, furgbaTextureCoordinateAttribute, "inputTextureCoordinate");
    
    // Link the program.
    if (![self linkProgram:rgbaProgram]) {
        NSLog(@"Failed to link program: %d", rgbaProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (rgbaProgram) {
            glDeleteProgram(rgbaProgram);
            rgbaProgram = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    displayInputTextureUniform = glGetUniformLocation(rgbaProgram, "inputImageTexture");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(rgbaProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(rgbaProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)loadShadersYUV {
    GLuint vertShader, fragShader;
    
    if (!rgbaToYuvProgram) {
        rgbaToYuvProgram = glCreateProgram();
    }
    
    // Create and compile the vertex shader.
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER string:SKGTVFUVertexShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER string:SKGTVFUYUVToRGBAFragmentShaderString]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to rgbaToYuvProgram.
    glAttachShader(rgbaToYuvProgram, vertShader);
    
    // Attach fragment shader to rgbaToYuvProgram.
    glAttachShader(rgbaToYuvProgram, fragShader);
    
    // Bind attribute locations. This needs to be done prior to linking.
    glBindAttribLocation(rgbaToYuvProgram, fuyuvConversionPositionAttribute, "position");
    glBindAttribLocation(rgbaToYuvProgram, fuyuvConversionTextureCoordinateAttribute, "inputTextureCoordinate");
    
    // Link the rgbaToYuvProgram.
    if (![self linkProgram:rgbaToYuvProgram]) {
        NSLog(@"Failed to link program: %d", rgbaToYuvProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (rgbaToYuvProgram) {
            glDeleteProgram(rgbaToYuvProgram);
            rgbaToYuvProgram = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    yuvConversionLuminanceTextureUniform = glGetUniformLocation(rgbaToYuvProgram, "luminanceTexture");
    yuvConversionChrominanceTextureUniform = glGetUniformLocation(rgbaToYuvProgram, "chrominanceTexture");
    yuvConversionMatrixUniform = glGetUniformLocation(rgbaToYuvProgram, "colorConversionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(rgbaToYuvProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(rgbaToYuvProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    glUseProgram(rgbaToYuvProgram);
    
    return YES;
}

- (BOOL)loadPointsShaders {
    GLuint vertShader, fragShader;
    
    pointProgram = glCreateProgram();
    
    // Create and compile the vertex shader.
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER string:SKGTVFUPointsVtxShaderString]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER string:SKGTVFUPointsFrgShaderString]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(pointProgram, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(pointProgram, fragShader);
    
    // Bind attribute locations. This needs to be done prior to linking.
    glBindAttribLocation(pointProgram, fuPointSize, "point_size");
    glBindAttribLocation(pointProgram, fuPointColor, "inputColor");
    
    // Link the program.
    if (![self linkProgram:pointProgram]) {
        NSLog(@"Failed to link program: %d", pointProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (pointProgram) {
            glDeleteProgram(pointProgram);
            pointProgram = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(pointProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(pointProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString {
    GLint status;
    const GLchar *source;
    source = (GLchar *)[shaderString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog {
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    return YES;
}

@end
