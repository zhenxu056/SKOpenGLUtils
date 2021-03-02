//
//  MGTEDMovieWrite.h
//  MGMediaPlay
//
//  Created by Sunflower on 2019/12/3.
//

#import <Foundation/Foundation.h>

#import <CoreMedia/CMFormatDescription.h>
#import <CoreMedia/CMSampleBuffer.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif

@class MGTEDMovieWrite;

@protocol MGTEDMovieWriteDelegate <NSObject>

@required

/// 准备编码完成
/// @param recorder 编码对象
- (void)movieRecorderDidFinishPreparing:(MGTEDMovieWrite *)recorder;

/// 编码错误
/// @param recorder 编码对象
/// @param error 错误信息
- (void)movieRecorder:(MGTEDMovieWrite *)recorder didFailWithError:(NSError *)error;

/// 编码完成
/// @param recorder 编码对象
- (void)movieRecorderDidFinishRecording:(MGTEDMovieWrite *)recorder;

@end

@interface MGTEDMovieWrite : NSObject

/// 视频地址
@property (assign, nonatomic, readonly) NSURL *currentURL;
/// 音频时间戳
@property (assign, nonatomic, readonly) NSTimeInterval audioSampleCnt;
/// 视频时间戳
@property (assign, nonatomic, readonly) NSTimeInterval videoTimestamp;

#pragma mark - Init

/// 初始化
/// @param URL 路径URL
/// @param delegate 代理
/// @param queue 代理返回的线程
- (instancetype)initWithURL:(NSURL *)URL delegate:(id<MGTEDMovieWriteDelegate>)delegate callbackQueue:(dispatch_queue_t)queue;

/// 是否写入音频开关(默认打开)
/// @param isOpenAudioWrite 开关设置
- (void)swichOpenAudioWrite:(BOOL)isOpenAudioWrite;

/// 设置写入视频的数据
/// @param videoSize 视频分辨率(默认: 720P )
/// @param sampleRate 音频采样率(默认: 44100 )
/// @param bitrate 比特率(默认: 2000000 )
- (void)addWriteVideoSize:(CGSize)videoSize audioSampleRate:(double)sampleRate videoBitrate:(double)bitrate;

/// 添加视频格式和视频信息 (不添加则为默认)
/// @param transform 旋转角度
/// @param videoSettings 视频信息设置
- (void)addVideoTrackWithtransform:(CGAffineTransform)transform settings:(NSDictionary *)videoSettings;

/// 添加音频格式和音频信息  (不添加则为默认)
/// @param audioSettings 音频信息设置
- (void)addAudioTrackWithSettings:(NSDictionary *)audioSettings;

/// 编码准备
- (void)prepareToRecord;

#pragma mark - Input

/// 输入视频帧
/// @param sampleBuffer 视频帧
- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/// 输入视频帧
/// @param pixelBuffer 视频帧
/// @param presentationTime 视频帧pts
- (void)appendVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime;

/// 输入音频数据
/// @param sampleBuffer 音频数据
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/// 输入音频数据
/// @param audioBufferList 音频数据
/// @param presentationTime 音频pts
- (void)appendAudioBufferList:(AudioBufferList)audioBufferList withPresentationTime:(CMTime)presentationTime;

#pragma mark - finish

/// 结束编码
- (void)finishRecording;

@end

NS_ASSUME_NONNULL_END
