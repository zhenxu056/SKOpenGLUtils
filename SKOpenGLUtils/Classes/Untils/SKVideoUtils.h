//
//  SKVideoUtils.h
//
//
//  Created by  on 2019/4/1.
//  Copyright © 2019 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKVideoUtils : NSObject

+ (UIImage *)convertToImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

+ (void)saveVideoToPhotoAlbum:(NSString *)filePath completion:(void(^)(BOOL finished))completion;

+ (void)saveImageToPhotoAlbum:(UIImage *)image completion:(void (^)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
