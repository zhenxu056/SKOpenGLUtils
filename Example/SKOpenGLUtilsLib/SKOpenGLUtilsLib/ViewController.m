//
//  ViewController.m
//  SKOpenGLUtilsLib
//
//  Created by Sunflower on 2020/4/28.
//  Copyright © 2020 Sunflower. All rights reserved.
//

#import "ViewController.h"
 
#import "SKMicrophoneSource.h"
#import "MGTEDMovieWrite.h"
#import "MGTEDFileManage.h"

@interface ViewController ()<SKMicrophoneSourceDelegate, MGTEDMovieWriteDelegate>

@property (nonatomic, strong) SKMicrophoneSource *microphone;

@property (nonatomic, strong) MGTEDMovieWrite *movieWrite;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.microphone prepareToMicrophone];
    
}

- (IBAction)startGetAudio:(UIButton *)sender {
    [self.microphone startRunning];
}

- (IBAction)startRecord:(UIButton *)sender { 
    NSString *path = [[MGTEDFileManage documentsDir] stringByAppendingString:@"/audio.mp4"];
    [MGTEDFileManage removeItemAtPath:path];
    self.movieWrite = [[MGTEDMovieWrite alloc] initWithURL:[NSURL fileURLWithPath:path] delegate:self callbackQueue:dispatch_get_main_queue()];
    [self.movieWrite prepareToRecord];
}

- (IBAction)closeRecord:(UIButton *)sender {
    [self.microphone stopRunning];
    [self.movieWrite finishRecording];
}

#pragma mark - QRDMicrophoneSourceDelegate

- (void)microphoneSource:(SKMicrophoneSource *)source didGetAudioBuffer:(AudioBufferList)bufList {
    
    if (self.movieWrite) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        CMTime time = CMTimeMake(now, 1000);
        [self.movieWrite appendAudioBufferList:bufList withPresentationTime:time];
    }
     
}

#pragma mark -

/// 准备编码完成
/// @param recorder 编码对象
- (void)movieRecorderDidFinishPreparing:(MGTEDMovieWrite *)recorder {
    
}

/// 编码错误
/// @param recorder 编码对象
/// @param error 错误信息
- (void)movieRecorder:(MGTEDMovieWrite *)recorder didFailWithError:(NSError *)error {
    
}

/// 编码完成
/// @param recorder 编码对象
- (void)movieRecorderDidFinishRecording:(MGTEDMovieWrite *)recorder {
    
}

#pragma mark - SET && GET

- (SKMicrophoneSource *)microphone {
    if (!_microphone) {
        _microphone = [[SKMicrophoneSource alloc] init];
        [_microphone setChannelCount:2];
        [_microphone setSampleRate:44100];
        _microphone.delegate = self;
    }
    return _microphone;
}

@end
