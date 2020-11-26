//
//  UIColor+SKColorHelper.m
//  SKOpenGLUtils
//
//  Created by Sunflower on 2020/11/26.
//

#import "UIColor+SKColorHelper.h"

#import "UIImage+SKImageHelper.h"

@implementation UIColor (SKColorHelper)
 
- (UIColor *)getPixelColorScreenWindowAtLocation:(CGPoint)point {
    UIColor* color = nil;
    UIImage *image = [UIImage fullScreenshots];
    CGImageRef inImage = image.CGImage;
    CGContextRef cgctx = [image createARGBBitmapContextFromImage];
    if (cgctx == NULL) { return nil;  }
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    CGRect rect = {{0,0},{w,h}};
    CGContextDrawImage(cgctx, rect, inImage);
    unsigned char* data = CGBitmapContextGetData (cgctx);
    CGFloat scale = [UIScreen mainScreen].scale;
    if (data != NULL) {
        //offset locates the pixel in the data from x,y.
        //4 for 4 bytes of data per pixel, w is width of one row of data.
        @try {
            int offset = 4*((w*round(point.y * scale))+round(point.x * scale));
            int alpha =  (int)data[offset];
            int red = (int)data[offset+1];
            int green = (int)data[offset+2];
            int blue = (int)data[offset+3];
            color = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:(alpha/255.0f)];
            
            free(data);
        }
        @catch (NSException * e) {
            NSLog(@"%@",[e reason]);
        }
        @finally {
        }
    }
    return color;
}
 

@end
