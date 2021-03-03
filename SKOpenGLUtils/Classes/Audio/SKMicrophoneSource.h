//
//  SKMicrophoneSource.h
//  SKOpenGLUtilsLib
//
//  Created by Sunflower on 2021/3/2.
//  Copyright © 2021 Sunflower. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
 
@class SKMicrophoneSource;

@protocol SKMicrophoneSourceDelegate <NSObject>

/// 声音数据采集
/// @param source 对象
/// @param bufList 音频buffer
- (void)microphoneSource:(SKMicrophoneSource *)source didGetAudioBuffer:(AudioBufferList)bufList;

/// 声音播放
/// @param source 对象
/// @param buffer 填充音频buffer
/// @param lenth 音频长度
- (void)queryAudioDataSource:(SKMicrophoneSource *)source audioBuffer:(uint8_t*)buffer audioSize:(int)lenth;

@end

@interface SKMicrophoneSource : NSObject
/// 声音格式
@property (nonatomic, assign, readonly) AudioStreamBasicDescription asbd;

/// 通道数
@property (nonatomic, assign, readonly) int channelCount;

/// 采样率
@property (nonatomic, assign, readonly) double sampleRate;

/// 是否在运行
@property (nonatomic, assign, readonly) BOOL isRunning;

/// 使用静音
@property (nonatomic, assign, readonly) BOOL muted;

/// APP声音和外界声音开启
@property (nonatomic, assign, readonly) BOOL allowAudioMixWithOthers;

/// 代理回调
@property (nonatomic, weak) id<SKMicrophoneSourceDelegate> delegate;

/// 设置通道数(默认 2 )
/// @param channelCount 通道数
- (void)setChannelCount:(int)channelCount;

/// 设置采样率(默认 44100)
/// @param sampleRate 采样率
- (void)setSampleRate:(double)sampleRate;

/// 麦克风准备
- (void)prepareToMicrophone;

/// 开始采集
- (void)startRunning;

/// 停止采集
- (void)stopRunning;

@end

NS_ASSUME_NONNULL_END
