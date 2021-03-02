//
//  MGTEDMovieWrite.m
//  MGMediaPlay
//
//  Created by Sunflower on 2019/12/3.
//

#import "MGTEDMovieWrite.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, MGTEDMovieWriteStatus) {
    MGTEDMovieWriteStatusIdle = 0,
    MGTEDMovieWriteStatusPreparingToRecord,
    MGTEDMovieWriteStatusRecording,
    MGTEDMovieWriteStatusFinishingRecordingPart1,
    MGTEDMovieWriteStatusFinishingRecordingPart2,
    MGTEDMovieWriteStatusFinished,
    MGTEDMovieWriteStatusFailed
};


@interface MGTEDMovieWrite ()
{
    AVAssetWriter *_assetWriter;
    MGTEDMovieWriteStatus _status;
    NSURL *_URL;
    
    BOOL _haveStartedSession;
    
    AVAssetWriterInput *_audioInput;
    AVAssetWriterInput *_videoInput;
    AVAssetWriterInputPixelBufferAdaptor *_pixelAdaptor;
    
    NSDictionary *_audioTrackSettings;
    NSDictionary *_videoTrackSettings;
    
    CGAffineTransform _videoTrackTransform;
    
    __weak id<MGTEDMovieWriteDelegate> _delegate;
    
    dispatch_queue_t _writingQueue;
    dispatch_queue_t _delegateCallbackQueue;
}

@property (nonatomic, assign) BOOL allowWriteAudio;

@property (assign, nonatomic, readwrite) NSTimeInterval firstAudioSampleCnt;
@property (assign, nonatomic, readwrite) NSTimeInterval firstViodeTimestamp;
@property (assign, nonatomic, readwrite) NSTimeInterval audioSampleCnt;
@property (assign, nonatomic, readwrite) NSTimeInterval videoTimestamp;

@property (nonatomic, assign) BOOL isOpenAudioWrite;
@property (assign, nonatomic) CGSize videoSize;
@property (assign, nonatomic) NSInteger videoBitrate;
@property (nonatomic, assign) double sampleRate;

@end

@implementation MGTEDMovieWrite

#pragma mark -
#pragma mark API

- (instancetype)initWithURL:(NSURL *)URL delegate:(id<MGTEDMovieWriteDelegate>)delegate callbackQueue:(dispatch_queue_t)queue {
    
    self = [super init];
    if (self) {
        _writingQueue = dispatch_queue_create("com.apple.sample.MGTEDMovie.writing", DISPATCH_QUEUE_SERIAL);
        _videoTrackTransform = CGAffineTransformIdentity;
        _URL = URL;
        _delegate = delegate;
        _delegateCallbackQueue = queue;
        _allowWriteAudio = YES;
        self.isOpenAudioWrite = YES;
        self.videoSize = CGSizeMake(720, 1280);
        self.videoBitrate = 2000000;
        self.sampleRate = 44100;
        self.audioSampleCnt = 0;
        self.videoTimestamp = -1;
        self.firstAudioSampleCnt = -1;
        self.firstViodeTimestamp = -1;
        _videoTrackSettings = [self defaultVideoSetting];
        _audioTrackSettings = [self defaultAudioSetting];
    }
    return self;
}

- (void)swichOpenAudioWrite:(BOOL)isOpenAudioWrite {
    self.isOpenAudioWrite = isOpenAudioWrite;
}

- (void)addWriteVideoSize:(CGSize)videoSize audioSampleRate:(double)sampleRate videoBitrate:(double)bitrate {
    self.videoSize = videoSize;
    self.videoBitrate = bitrate;
    self.sampleRate = sampleRate;
    _videoTrackSettings = [self defaultVideoSetting];
    _audioTrackSettings = [self defaultAudioSetting];
}

- (void)addVideoTrackWithtransform:(CGAffineTransform)transform settings:(NSDictionary *)videoSettings {
    
    @synchronized(self) {
        if (_status != MGTEDMovieWriteStatusIdle) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        _videoTrackTransform = transform;
        _videoTrackSettings = [videoSettings copy];
        if ([_videoTrackSettings[AVVideoAverageBitRateKey] doubleValue] > 0.0) {
            self.videoBitrate = [_videoTrackSettings[AVVideoAverageBitRateKey] doubleValue];
        }
        if ([_videoTrackSettings[AVVideoCleanApertureWidthKey] intValue] > 0 && [_videoTrackSettings[AVVideoCleanApertureHeightKey] intValue] > 0) {
            self.videoSize = CGSizeMake([_videoTrackSettings[AVVideoCleanApertureWidthKey] intValue],
                                        [_videoTrackSettings[AVVideoCleanApertureHeightKey] intValue]);
        }
    }
}

- (void)addAudioTrackWithSettings:(NSDictionary *)audioSettings {
    @synchronized(self)
    {
        if (_status != MGTEDMovieWriteStatusIdle) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        _audioTrackSettings = [audioSettings copy];
        _isOpenAudioWrite = YES;
        if ([_audioTrackSettings[AVSampleRateKey] doubleValue] > 0.0) {
            self.sampleRate = [_audioTrackSettings[AVSampleRateKey] doubleValue];
        }
    }
}

- (void)prepareToRecord {
    @synchronized(self) {
        if (_status != MGTEDMovieWriteStatusIdle) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already prepared, cannot prepare again" userInfo:nil];
            return;
        }
        
        [self transitionToStatus:MGTEDMovieWriteStatusPreparingToRecord error:nil];
    }
    @weakify(self)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @strongify(self)
        @autoreleasepool {
            
            NSError *error = nil;
            // AVAssetWriter will not write over an existing file.
            [[NSFileManager defaultManager] removeItemAtURL:self->_URL error:NULL];
            
            self->_assetWriter = [[AVAssetWriter alloc] initWithURL:self->_URL fileType:AVFileTypeQuickTimeMovie error:&error];
            
            // Create and add inputs
            if (!error) {
                [self setupAssetWriterVideoInputWithtransform:self->_videoTrackTransform settings:self->_videoTrackSettings error:&error];
            }
            
            if (!error && self.isOpenAudioWrite) {
                [self setupAssetWriterAudioInputWithSettings:self->_audioTrackSettings error:&error];
            }
            
            if (!error) {
                BOOL success = [self->_assetWriter startWriting];
                if (!success) {
                    error = self->_assetWriter.error;
                }
            }
            
            @synchronized(self) {
                if (error) {
                    [self transitionToStatus:MGTEDMovieWriteStatusFailed error:error];
                }
                else {
                    [self transitionToStatus:MGTEDMovieWriteStatusRecording error:nil];
                }
            }
        }
    });
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
}

- (void)appendVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime {
    
    if (pixelBuffer == NULL) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL pixelBuffer buffer" userInfo:nil];
        return;
    }
    
    @synchronized(self) {
        if (_status < MGTEDMovieWriteStatusRecording) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not ready to record yet" userInfo:nil];
            return;
        }
    }
    
    CVPixelBufferRetain(pixelBuffer);
    @weakify(self)
    dispatch_async(_writingQueue, ^{
        @strongify(self)
        @autoreleasepool {
            @synchronized(self) {
                // From the client's perspective the STMovie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when samples are appended and we are no longer recording.
                // Instead of throwing an exception we just release the sample buffers and return.
                if (self->_status > MGTEDMovieWriteStatusFinishingRecordingPart1) {
                    CVPixelBufferRelease(pixelBuffer);
                    return;
                }
            }
            
            if (!self->_haveStartedSession) {
                [self->_assetWriter startSessionAtSourceTime:presentationTime];
                self->_haveStartedSession = YES;
            }
            
            AVAssetWriterInput *input = self->_videoInput;
            
            if (input.readyForMoreMediaData) {
                BOOL success = [self->_pixelAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
                if (!success) {
                    NSError *error = self->_assetWriter.error;
                    @synchronized(self) {
                        [self transitionToStatus:MGTEDMovieWriteStatusFailed error:error];
                    }
                } else {
                    self.allowWriteAudio = YES;
                }
                @synchronized(self) { 
                    double dTimestamp = CMTimeGetSeconds(presentationTime) * 1000;
                    if (self.firstViodeTimestamp == -1) {
                        self.firstViodeTimestamp = dTimestamp;
                    }
                    self.videoTimestamp = dTimestamp - self.firstViodeTimestamp;
                }
            } else {
                NSLog(@"%@ input not ready for more media data, dropping buffer", @"video");
            }
            CVPixelBufferRelease(pixelBuffer);
        }
    });
    
    return;
    
    CMSampleBufferRef sampleBuffer = NULL;
    
    CMSampleTimingInfo timingInfo = {0,};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = presentationTime;
    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    
    OSStatus err = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timingInfo, &sampleBuffer);
    
    CFRelease(videoInfo);
    
    if (sampleBuffer) {
        [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
        CFRelease(sampleBuffer);
    }
    else {
        NSString *exceptionReason = [NSString stringWithFormat:@"sample buffer create failed (%i)", (int)err];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:exceptionReason userInfo:nil];
    }
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (self.allowWriteAudio) {
        [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
    }
}

- (void)appendAudioBufferList:(AudioBufferList)audioBufferList withPresentationTime:(CMTime)presentationTime {
    int len = audioBufferList.mBuffers[0].mDataByteSize;
    int samples = len/4;
    
    AudioStreamBasicDescription asbd = [self getAudioFormat];
    CMSampleBufferRef buff = NULL;
    CMFormatDescriptionRef format = NULL;
    CMSampleTimingInfo timing = {CMTimeMake(1, self.sampleRate), presentationTime, kCMTimeInvalid };
    OSStatus error = 0;
    if(format == NULL)
        error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
    size_t sampleSizeArray[1] = { 4 };
    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, samples, 1, &timing, 1, &sampleSizeArray[0], &buff);
    
    if (error) {
        NSLog(@"CMSampleBufferCreate returned error: %ld", (long)error);
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(buff, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    if(error) {
        NSLog(@"CMSampleBufferSetDataBufferFromAudioBufferList returned error: %ld", (long)error);
    }
    
    if (buff) {
        [self appendAudioSampleBuffer:buff];
    }
}

- (void)finishRecording {
    @synchronized(self) {
        BOOL shouldFinishRecording = NO;
        switch (_status) {
            case MGTEDMovieWriteStatusIdle:
            case MGTEDMovieWriteStatusPreparingToRecord:
            case MGTEDMovieWriteStatusFinishingRecordingPart1:
            case MGTEDMovieWriteStatusFinishingRecordingPart2:
            case MGTEDMovieWriteStatusFinished:
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not recording" userInfo:nil];
                break;
            case MGTEDMovieWriteStatusFailed:
                // From the client's perspective the STMovie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when finishRecording is called and we are in an error state.
                NSLog(@"Recording has failed, nothing to do");
                break;
            case MGTEDMovieWriteStatusRecording:
                shouldFinishRecording = YES;
                break;
        }
        
        if (shouldFinishRecording) {
            [self transitionToStatus:MGTEDMovieWriteStatusFinishingRecordingPart1 error:nil];
        }
        else {
            return;
        }
    }
    @weakify(self)
    dispatch_async(_writingQueue, ^{
        @strongify(self)
        @autoreleasepool {
            @synchronized(self) {
                // We may have transitioned to an error state as we appended inflight buffers. In that case there is nothing to do now.
                if (self->_status != MGTEDMovieWriteStatusFinishingRecordingPart1) {
                    return;
                }
                
                // It is not safe to call -[AVAssetWriter finishWriting*] concurrently with -[AVAssetWriterInput appendSampleBuffer:]
                // We transition to MGTEDMovieWriteStatusFinishingRecordingPart2 while on _writingQueue, which guarantees that no more buffers will be appended.
                [self transitionToStatus:MGTEDMovieWriteStatusFinishingRecordingPart2 error:nil];
            }

            [self->_assetWriter finishWritingWithCompletionHandler:^{
                @synchronized(self) {
                    NSError *error = self->_assetWriter.error;
                    if (error) {
                        [self transitionToStatus:MGTEDMovieWriteStatusFailed error:error];
                    }
                    else {
                        [self transitionToStatus:MGTEDMovieWriteStatusFinished error:nil];
                    }
                }
            }];
        }
    });
}

- (void)dealloc {
    if (_status == MGTEDMovieWriteStatusFinished) {
        [_assetWriter cancelWriting];
    }
}

#pragma mark -
#pragma mark Internal

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType {
    if (sampleBuffer == NULL) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL sample buffer" userInfo:nil];
        return;
    }
    
    @synchronized(self) {
        if (_status < MGTEDMovieWriteStatusRecording) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not ready to record yet" userInfo:nil];
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    @weakify(self)
    dispatch_async(_writingQueue, ^{
        @strongify(self)
        @autoreleasepool {
            @synchronized(self) {
                // From the client's perspective the STMovie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when samples are appended and we are no longer recording.
                // Instead of throwing an exception we just release the sample buffers and return.
                if (self->_status > MGTEDMovieWriteStatusFinishingRecordingPart1) {
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if (!self->_haveStartedSession) {
                [self->_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self->_haveStartedSession = YES;
            }
            
            AVAssetWriterInput *input = (mediaType == AVMediaTypeVideo) ? self->_videoInput : self->_audioInput;
            
            if (input.readyForMoreMediaData) {
                BOOL success = [input appendSampleBuffer:sampleBuffer];
                if (!success) {
                    NSError *error = self->_assetWriter.error;
                    @synchronized(self) {
                        [self transitionToStatus:MGTEDMovieWriteStatusFailed error:error];
                    }
                } else {
                    self.allowWriteAudio = YES;
                }
                if (mediaType == AVMediaTypeVideo) {
                    @synchronized(self) {
                        CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                        double dTimestamp = CMTimeGetSeconds(timeStamp) * 1000;
                        if (self.firstViodeTimestamp == -1) {
                            self.firstViodeTimestamp = dTimestamp;
                        }
                        self.videoTimestamp = dTimestamp - self.firstViodeTimestamp;
                    }
                } else {
                    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    double dTimestamp = CMTimeGetSeconds(timeStamp) * 1000;
                    if (self.firstAudioSampleCnt == -1) {
                        self.firstAudioSampleCnt = dTimestamp;
                    }
                    self.audioSampleCnt = dTimestamp - self.firstAudioSampleCnt;
                }
            } else {
                NSLog(@"%@ input not ready for more media data, dropping buffer", mediaType);
            }
            CFRelease(sampleBuffer);
        }
    });
}

// call under @synchonized(self)
- (void)transitionToStatus:(MGTEDMovieWriteStatus)newStatus error:(NSError *)error {
    BOOL shouldNotifyDelegate = NO;
    
#if DEBUG
    NSLog(@"MovieRecorder state transition: %@->%@", [self stringForStatus:_status], [self stringForStatus:newStatus]);
#endif
    
    if (newStatus != _status) {
        // terminal states
        if ((newStatus == MGTEDMovieWriteStatusFinished) || (newStatus == MGTEDMovieWriteStatusFailed)) {
            shouldNotifyDelegate = YES;
            // make sure there are no more sample buffers in flight before we tear down the asset writer and inputs
            @weakify(self)
            dispatch_async(_writingQueue, ^{
                @strongify(self)
                [self teardownAssetWriterAndInputs];
                if (newStatus == MGTEDMovieWriteStatusFailed) {
                    [[NSFileManager defaultManager] removeItemAtURL:self->_URL error:NULL];
                }
            });

#if DEBUG
            if (error) {
                NSLog(@"STMovieRecorder error: %@, code: %i", error, (int)error.code);
            }
#endif
        }
        else if (newStatus == MGTEDMovieWriteStatusRecording) {
            shouldNotifyDelegate = YES;
        }
        
        _status = newStatus;
    }

    if (shouldNotifyDelegate) {
        @weakify(self)
        dispatch_async(_delegateCallbackQueue, ^{
            @strongify(self)
            @autoreleasepool {
                if (!self->_delegate) {
                    return;
                }
                switch (newStatus) {
                    case MGTEDMovieWriteStatusRecording:
                        [self->_delegate movieRecorderDidFinishPreparing:self];
                        break;
                    case MGTEDMovieWriteStatusFinished:
                        [self->_delegate movieRecorderDidFinishRecording:self];
                        break;
                    case MGTEDMovieWriteStatusFailed:
                        [self->_delegate movieRecorder:self didFailWithError:error];
                        break;
                    default:
                        NSAssert1(NO, @"Unexpected recording status (%i) for delegate callback", (int)newStatus);
                        break;
                }
            }
        });
    }
}

#if DEBUG

- (NSString *)stringForStatus:(MGTEDMovieWriteStatus)status {
    NSString *statusString = nil;
    
    switch (status) {
        case MGTEDMovieWriteStatusIdle:
            statusString = @"Idle";
            break;
        case MGTEDMovieWriteStatusPreparingToRecord:
            statusString = @"PreparingToRecord";
            break;
        case MGTEDMovieWriteStatusRecording:
            statusString = @"Recording";
            break;
        case MGTEDMovieWriteStatusFinishingRecordingPart1:
            statusString = @"FinishingRecordingPart1";
            break;
        case MGTEDMovieWriteStatusFinishingRecordingPart2:
            statusString = @"FinishingRecordingPart2";
            break;
        case MGTEDMovieWriteStatusFinished:
            statusString = @"Finished";
            break;
        case MGTEDMovieWriteStatusFailed:
            statusString = @"Failed";
            break;
        default:
            statusString = @"Unknown";
            break;
    }
    return statusString;
    
}

#endif // LOG_STATUS_TRANSITIONS

- (BOOL)setupAssetWriterAudioInputWithSettings:(NSDictionary *)audioSettings error:(NSError **)errorOut {
    if (!audioSettings) {
        NSLog(@"No audio settings provided, using default settings");
        audioSettings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC) };
    }
    
    if ([_assetWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {
        _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        _audioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_audioInput]) {
            [_assetWriter addInput:_audioInput];
        }
        else {
            if (errorOut) {
                *errorOut = [[self class] cannotSetupInputError];
            }
            return NO;
        }
    }
    else {
        if (errorOut) {
            *errorOut = [[self class] cannotSetupInputError];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)setupAssetWriterVideoInputWithtransform:(CGAffineTransform)transform settings:(NSDictionary *)videoSettings error:(NSError **)errorOut {
   
    if ([_assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {
        _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        _videoInput.expectsMediaDataInRealTime = YES;
        _videoInput.transform = transform;
        
        
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:[NSNumber numberWithUnsignedInt:self.videoSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
        [attributes setObject:[NSNumber numberWithUnsignedInt:self.videoSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
        
        _pixelAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput sourcePixelBufferAttributes:attributes];
        
        if ([_assetWriter canAddInput:_videoInput]) {
            [_assetWriter addInput:_videoInput];
        }
        else {
            if (errorOut) {
                *errorOut = [[self class] cannotSetupInputError];
            }
            return NO;
        }
    }
    else {
        if (errorOut) {
            *errorOut = [[self class] cannotSetupInputError];
        }
        return NO;
    }
    
    return YES;
}

+ (NSError *)cannotSetupInputError {
    NSString *localizedDescription = NSLocalizedString(@"Recording cannot be started", nil);
    NSString *localizedFailureReason = NSLocalizedString(@"Cannot setup asset writer input.", nil);
    NSDictionary *errorDict = @{ NSLocalizedDescriptionKey : localizedDescription,
                                 NSLocalizedFailureReasonErrorKey : localizedFailureReason };
    return [NSError errorWithDomain:@"com.apple.dts.samplecode" code:0 userInfo:errorDict];
}

- (void)teardownAssetWriterAndInputs {
    _videoInput = nil;
    _audioInput = nil;
    _assetWriter = nil;
}

- (NSDictionary *)defaultVideoSetting {
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:self.videoSize.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:self.videoSize.height], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];

    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];

    NSMutableDictionary * compressionProperties1 = [[NSMutableDictionary alloc] init];
    [compressionProperties1 setObject:videoCleanApertureSettings forKey:AVVideoCleanApertureKey];
    [compressionProperties1 setObject:videoAspectRatioSettings forKey:AVVideoPixelAspectRatioKey];
    [compressionProperties1 setObject:[NSNumber numberWithInt: (int)self.videoBitrate] forKey:AVVideoAverageBitRateKey];
    [compressionProperties1 setObject:[NSNumber numberWithInt: 30] forKey:AVVideoMaxKeyFrameIntervalKey];
    [compressionProperties1 setObject:[NSNumber numberWithInt: 30] forKey:AVVideoExpectedSourceFrameRateKey];
    [compressionProperties1 setObject:AVVideoProfileLevelH264HighAutoLevel forKey:AVVideoProfileLevelKey];
    [compressionProperties1 setObject:AVVideoH264EntropyModeCABAC forKey:AVVideoH264EntropyModeKey];
    
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    [settings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [settings setObject:[NSNumber numberWithInt:self.videoSize.width] forKey:AVVideoWidthKey];
    [settings setObject:[NSNumber numberWithInt:self.videoSize.height] forKey:AVVideoHeightKey];
    
    [settings setObject:compressionProperties1 forKey:AVVideoCompressionPropertiesKey];
    
    NSDictionary *settingDict = [NSDictionary dictionaryWithDictionary:settings];
    
    return settingDict;
}

- (NSDictionary *)defaultAudioSetting {
    
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary* audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                        [NSNumber numberWithInt:128000], AVEncoderBitRateKey,
                                        [NSNumber numberWithFloat:self.sampleRate], AVSampleRateKey,
                                        [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                        AVAudioBitRateStrategy_Constant, AVEncoderBitRateStrategyKey,
                                        [NSData dataWithBytes:&acl length:sizeof(acl)], AVChannelLayoutKey,
                                        nil];
    return audioOutputSettings;
}

- (AudioStreamBasicDescription)getAudioFormat {
    AudioStreamBasicDescription desc;
    memset(&desc, 0, sizeof(desc));
    desc.mSampleRate = self.sampleRate;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked);
    desc.mChannelsPerFrame = 2;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = 16;
    desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    return desc;
}

- (NSURL *)currentURL {
    return _URL;
}

@end
