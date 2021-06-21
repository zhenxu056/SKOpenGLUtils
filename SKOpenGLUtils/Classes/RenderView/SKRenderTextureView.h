//
//  GTVRenderView.h
//  AFNetworking
//
//  Created by Sunflower on 2019/7/16.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKRenderTextureView : UIView

@property (nonatomic , strong) EAGLContext *glContext;

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context;

- (void)renderTexture:(GLuint)texture;

@end

NS_ASSUME_NONNULL_END
