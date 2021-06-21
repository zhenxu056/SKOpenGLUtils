//
//  GTVPixelBufferRefDisplayView.h
//  MGGTVideoPlayer
//
//  Created by Sunflower on 2019/8/1.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKPixelBufferRefDisplayView : UIView
    
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
