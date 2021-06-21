//
//  SKVideoConfig.h
//  iOS_Test
//
//  Created by  on 2019/9/27.
//  Copyright © 2019 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - <-------------------- Define -------------------->
typedef NS_ENUM(NSUInteger, SKVideoEncoderType) {
    SKVideoEncoderType_H264_Hardware,
    SKVideoEncoderType_HEVC_Hardware,
    SKVideoEncoderType_H264_Software,
    SKVideoEncoderType_HEVC_Software,
};

typedef NS_ENUM(NSUInteger, SKVideoDecoderType) {
    SKVideoDecoderType_H264_Hardware,
    SKVideoDecoderType_HEVC_Hardware,
    SKVideoDecoderType_H264_Software,
    SKVideoDecoderType_HEVC_Software,
};


#pragma mark - <-------------------- Class -------------------->
@interface SKVideoConfig : NSObject

#pragma mark - <-- Setter && Getter -->
/// 分辨率
@property(nonatomic, copy) AVCaptureSessionPreset sessionPreset;
/// 摄像头前后
@property(nonatomic, assign) AVCaptureDevicePosition position;
/// 显示方向
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
/// 帧率
@property (nonatomic, assign) NSUInteger fps;
/// gop 最大关键帧间隔，默认:fps 的2倍
@property (nonatomic, assign) NSUInteger gop;
/// 码率，单位是 bps
@property (nonatomic, assign) NSUInteger bitRate;
/// 是否有B帧, 默认:否
@property(nonatomic, assign) BOOL isEnableBFrame;


/// 自适应码率开关,配合最小码率和最大码率使用, 默认:否
@property(nonatomic, assign) BOOL adaptiveBitRate;
/// 自适应最小码率，单位是 bps, 默认: bitRate的0.5倍
@property (nonatomic, assign) NSUInteger minBitRate;
/// 自适应最大码率，单位是 bps, 默认: bitRate的1.5倍
@property (nonatomic, assign) NSUInteger maxBitRate;


/// 编码类型, 默认: DVVideoEncoderType_H264_Hardware
@property(nonatomic, assign) SKVideoEncoderType encoderType;
/// 解码类型, 默认: DVVideoDecoderType_H264_Hardware
@property(nonatomic, assign) SKVideoDecoderType decoderType;


#pragma mark - <-- Readonly -->
/// 视频的分辨率，宽高务必设定为 2 的倍数，否则解码播放时可能出现绿边
@property (nonatomic, assign, readonly) CGSize size;
/// 是否是横屏
@property (nonatomic, assign, readonly) BOOL isLandscape;


#pragma mark - <-- Initializer -->
- (instancetype)init;


#pragma mark - <-- PCM Default -->
+ (SKVideoConfig *)kConfig_480P_15fps;
+ (SKVideoConfig *)kConfig_480P_24fps;
+ (SKVideoConfig *)kConfig_480P_30fps;

+ (SKVideoConfig *)kConfig_540P_15fps;
+ (SKVideoConfig *)kConfig_540P_24fps;
+ (SKVideoConfig *)kConfig_540P_30fps;

+ (SKVideoConfig *)kConfig_720P_15fps;
+ (SKVideoConfig *)kConfig_720P_24fps;
+ (SKVideoConfig *)kConfig_720P_30fps;

+ (SKVideoConfig *)kConfig_1080P_15fps;
+ (SKVideoConfig *)kConfig_1080P_24fps;
+ (SKVideoConfig *)kConfig_1080P_30fps_2M;
+ (SKVideoConfig *)kConfig_1080P_30fps_4M;
+ (SKVideoConfig *)kConfig_1080P_60fps_10M;

+ (SKVideoConfig *)kConfig_4K_15fps;
+ (SKVideoConfig *)kConfig_4K_24fps;
+ (SKVideoConfig *)kConfig_4K_30fps;

@end

NS_ASSUME_NONNULL_END
