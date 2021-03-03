//
//  SKMicrophoneSource.m
//  SKOpenGLUtilsLib
//
//  Created by Sunflower on 2021/3/2.
//  Copyright © 2021 Sunflower. All rights reserved.
//

#import "SKMicrophoneSource.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#define kInputBus   1//输入道
#define KOutputBus  0//输出道

@interface SKMicrophoneSource ()

@property (nonatomic, assign) AudioComponentInstance componentInstance;
@property (nonatomic, assign) AudioComponent component;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) AudioStreamBasicDescription asbd;

@property (nonatomic, assign) BOOL isInInterruption;
@property (nonatomic, assign) int channelCount;
@property (nonatomic, assign) double sampleRate;
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) BOOL allowAudioMixWithOthers;

@end

@implementation SKMicrophoneSource

- (instancetype)init {
    if(self = [super init]) {
        NSLog(@"SKMicrophoneSource init: %p", self);
        self.taskQueue = dispatch_queue_create("com.audiocapture", NULL);
        self.channelCount = 2;
        self.sampleRate = 44100;
        self.allowAudioMixWithOthers = NO;
        self.muted = NO;
    }
    return self;
}

- (void)setSampleRate:(double)sampleRate {
    _sampleRate = sampleRate;
}

- (void)setChannelCount:(int)channelCount {
    _channelCount = channelCount;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
}

- (void)setAllowAudioMixWithOthers:(BOOL)allowAudioMixWithOthers {
    _allowAudioMixWithOthers = allowAudioMixWithOthers;
}

- (void)prepareToMicrophone {
    if (self.componentInstance || self.componentInstance) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        AudioOutputUnitStop(self.componentInstance);
        AudioComponentInstanceDispose(self.componentInstance);
        self.componentInstance = nil;
        self.component = nil;
    }
    self.isRunning = NO;
    [self setupASBD];
    [self setupAudioComponent];
    [self setupAudioSession];
    [self addObservers];
}

- (void)setupASBD {
    _asbd.mSampleRate = self.sampleRate;
    _asbd.mFormatID = kAudioFormatLinearPCM;
    _asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    _asbd.mChannelsPerFrame = self.channelCount;
    _asbd.mFramesPerPacket = 1;
    _asbd.mBitsPerChannel = 16;
    _asbd.mBytesPerFrame = _asbd.mBitsPerChannel / 8 * _asbd.mChannelsPerFrame;
    _asbd.mBytesPerPacket = _asbd.mBytesPerFrame * _asbd.mFramesPerPacket;
}

- (void)setupAudioComponent {
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;

    self.component = AudioComponentFindNext(NULL, &acd);
    OSStatus status = AudioComponentInstanceNew(self.component, &_componentInstance);
    if (noErr != status) {
        NSLog(@"AudioComponentInstanceNew error, status: %d", status);
        return;
    }

    UInt32 flagOne = 1;
    // Enable IO for recording
    AudioUnitSetProperty(self.componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flagOne, sizeof(flagOne));

    // 应用录制音频流描述
    AudioUnitSetProperty(self.componentInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &_asbd, sizeof(_asbd));
    
    // Set input callback
    AURenderCallbackStruct callback;
    callback.inputProcRefCon = (__bridge void *)(self);
    callback.inputProc = handleInputBuffer;
    AudioUnitSetProperty(self.componentInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputBus, &callback, sizeof(callback));
    
    
    // Enable IO for playback
    AudioUnitSetProperty(self.componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, KOutputBus, &flagOne, sizeof(flagOne));
    
    // 音频流描述
    AudioUnitSetProperty(self.componentInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, KOutputBus, &_asbd, sizeof(_asbd));
    
    // Set output callback
    callback.inputProc = playbackCallback;
    callback.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(self.componentInstance, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, KOutputBus, &callback, sizeof(callback));

    status = AudioUnitInitialize(self.componentInstance);
    if (noErr != status) {
        NSLog(@"AudioUnitInitialize error, status: %d", status);
        return;
    }
}

- (void)setupAudioSession {
    NSError *sessionError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];

    if (![self resetAudioSessionCategorySettings]) {
        return;
    }

    [session setMode:AVAudioSessionModeVideoChat error:&sessionError];
    if (sessionError) {
        NSLog(@"error:%ld, set session mode error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }

    [session setActive:YES error:&sessionError];
    if (sessionError) {
        NSLog(@"error:%ld, set session active error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }

    [session setPreferredSampleRate:self.sampleRate error:&sessionError];
    if (sessionError) {
        NSLog(@"error:%ld, setPreferredSampleRate error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }

    [session setPreferredIOBufferDuration:1024.0 / self.sampleRate error:&sessionError];
    if (sessionError) {
        NSLog(@"error:%ld, setPreferredIOBufferDuration error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }

    // use bottom microphone for capture by default
    if (AVAudioSessionOrientationBottom != [session inputDataSource].orientation) {
        for (AVAudioSessionDataSourceDescription *dataSource in [session inputDataSources]) {
            if (AVAudioSessionOrientationBottom == dataSource.orientation) {
                [session setInputDataSource:dataSource error:&sessionError];
                if (sessionError) {
                    NSLog(@"error:%ld, set input data source error : %@", sessionError.code, sessionError.localizedDescription);
                }
            }
        }
    }

    return;
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (BOOL)resetAudioSessionCategorySettings {
    NSError *sessionError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];

    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth;

    if (self.allowAudioMixWithOthers) {
        options = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth;
    }

    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:&sessionError];
    if (sessionError) {
        NSLog(@"error:%ld, set session category error : %@", sessionError.code, sessionError.localizedDescription);
        return NO;
    }

    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    AudioOutputUnitStop(self.componentInstance);
    AudioComponentInstanceDispose(self.componentInstance);
    self.componentInstance = nil;
    self.component = nil;
    NSLog(@"SKMicrophoneSource dealloc: %p", self);
}

- (void)startRunning {
    NSLog(@"startRunning");

    dispatch_async(self.taskQueue, ^{
        if (self.isRunning) {
            return;
        }

        if ([self resetAudioSession]) {
            OSStatus result = AudioOutputUnitStart(self.componentInstance);
            NSLog(@"AudioOutputUnitStart result: %ld", (long)result);
            self.isRunning = YES;
        }
    });
}

- (void)stopRunning {
    NSLog(@"stopRunning");

    dispatch_async(self.taskQueue, ^{
        if (!self.isRunning) {
            return;
        }

        OSStatus result = AudioOutputUnitStop(self.componentInstance);
        NSLog(@"AudioOutputUnitStop result: %ld", (long)result);
        self.isRunning = NO;
    });
}

#pragma mark - NSNotification
- (void)handleRouteChange:(NSNotification *)notification {
    NSString* seccReason = @"";
    NSInteger  reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            [self resetAudioSession];
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            [self resetAudioSession];
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            [self resetAudioSession];
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            [self resetAudioSession];
            seccReason = @"The previous audio output path is no longer available.";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            [self resetAudioSession];
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }

    NSLog(@"handleRouteChange: %@ reason %@",[notification name], seccReason);
}

- (BOOL)resetAudioSession {
    NSError *sessionError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];

    [session setActive:YES error:&sessionError];
    if (sessionError) {
        NSLog(@"error:%ld, set session active error : %@", sessionError.code, sessionError.localizedDescription);
        return NO;
    }

    // use bottom microphone for capture by default
    if (AVAudioSessionOrientationBottom != [session inputDataSource].orientation) {
        for (AVAudioSessionDataSourceDescription *dataSource in [session inputDataSources]) {
            if (AVAudioSessionOrientationBottom == dataSource.orientation) {
                [session setInputDataSource:dataSource error:&sessionError];
                if (sessionError) {
                    NSLog(@"error:%ld, set input data source error : %@", sessionError.code, sessionError.localizedDescription);
                }
            }
        }
    }

    return YES;
}

- (void)handleInterruption:(NSNotification *)notification {
    NSLog(@"handleInterruption: %@" ,notification);
    if (![notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        return;
    }

    NSInteger interruptionType = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        dispatch_sync(self.taskQueue, ^{
            if (self.isRunning) {
                OSStatus result = AudioOutputUnitStop(self.componentInstance);
                NSLog(@"AVAudioSessionInterruptionTypeBegan, AudioOutputUnitStop, result: %d", result);
                self.isInInterruption = YES;
            }
        });
    }
    else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        dispatch_async(self.taskQueue, ^{
            if (self.isRunning) {
                OSStatus result = AudioOutputUnitStart(self.componentInstance);
                NSLog(@"AVAudioSessionInterruptionTypeEnded, AudioOutputUnitStart, result: %d", result);
                self.isInInterruption = NO;
            }
        });
    }
}

- (void)handleApplicationActive:(NSNotification *)notification {
    dispatch_async(self.taskQueue, ^{
        if (self.isInInterruption && self.isRunning) {
            OSStatus result = AudioOutputUnitStart(self.componentInstance);
            NSLog(@"applicationActive, AudioOutputUnitStart, result: %d", result);
            self.isInInterruption = NO;
        }
    });
}

#pragma mark - CallBack

static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        SKMicrophoneSource *source = (__bridge SKMicrophoneSource *)inRefCon;
        if (!source) {
            return -1;
        }

        AudioBuffer buffer;
        buffer.mDataByteSize = inNumberFrames * 20;
        buffer.mData = malloc(buffer.mDataByteSize);
        buffer.mNumberChannels = source.channelCount;

        AudioBufferList bufferList;
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0] = buffer;

        OSStatus status = AudioUnitRender(source.componentInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &bufferList);

        if (status || buffer.mDataByteSize <= 0) {
            NSLog(@"AudioUnitRender error, status: %d", status);
            free(buffer.mData);
            return status;
        }

        if (source.muted) {
            memset(buffer.mData, 0, buffer.mDataByteSize);
        }

        if (source.delegate && [source.delegate respondsToSelector:@selector(microphoneSource:didGetAudioBuffer:)]) {
            [source.delegate microphoneSource:source didGetAudioBuffer:bufferList];
        }

        free(buffer.mData);
        return status;
    }
}


static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    @autoreleasepool {
        
        SKMicrophoneSource* source = (__bridge SKMicrophoneSource *) inRefCon;

        if (!source || !source.isRunning) {
            for (UInt32 i = 0; i < ioData->mNumberBuffers; i++) {
                AudioBuffer *ioBuffer = &ioData->mBuffers[i];
                memset(ioBuffer->mData, 0x00, ioBuffer->mDataByteSize);
            }
            return noErr;
        }

        for (int i = 0; i < (int)ioData->mNumberBuffers; i++) {
            AudioBuffer *ioBuffer = &ioData->mBuffers[i];
            memset(ioBuffer->mData, 0x00, ioBuffer->mDataByteSize);
            if (source.delegate && [source.delegate respondsToSelector:@selector(queryAudioDataSource:audioBuffer:audioSize:)]) {
                [source.delegate queryAudioDataSource:source audioBuffer:ioBuffer->mData audioSize:ioBuffer->mDataByteSize];
            }
        }
        
        /*----------------------------------------------------------------------
         |   1.根据buffer.mDataByteSize大小需求，给buffer.mData赋值相应大小的数据内容; |
         |   2.若无数据，则把数据填写为0，默认正在播放无声音频；                         |
         |       UInt16 *frameBuffer = buffer.mData;                            |
         |       for (int j = 0; j < inNumberFrames; j++) {                     |
         |           frameBuffer[j] = 0;                                        |
         |       }                                                              |
         ----------------------------------------------------------------------*/

        return noErr;
    }
    return noErr;
}

@end
