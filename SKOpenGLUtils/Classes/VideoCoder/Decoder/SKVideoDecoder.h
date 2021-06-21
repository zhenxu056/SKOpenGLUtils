//
//  DVVideoDecoder.h
//  iOS_Test
//
//  Created by DV on 2019/10/9.
//  Copyright © 2019 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "SKVideoConfig.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - <-------------------- SKVideoEncoderDelegate -------------------->
@protocol SKVideoDecoder;
@protocol SKVideoDecoderDelegate <NSObject>

- (void)DVVideoDecoder:(id<SKVideoDecoder>)decoder
         decodecBuffer:(nullable CMSampleBufferRef)buffer
          isFirstFrame:(BOOL)isFirstFrame
              userInfo:(nullable void *)userInfo;

@end


#pragma mark - <-------------------- SKVideoEncoder -------------------->
@protocol SKVideoDecoder <NSObject>
@optional

@property(nonatomic, weak) id<SKVideoDecoderDelegate> delegate;

- (void)decodeVideoData:(NSData *)data
                    pts:(int64_t)pts
                    dts:(int64_t)dts
                    fps:(int)fps
               userInfo:(nullable void *)userInfo;

- (void)closeDecoder;

@end

NS_ASSUME_NONNULL_END
