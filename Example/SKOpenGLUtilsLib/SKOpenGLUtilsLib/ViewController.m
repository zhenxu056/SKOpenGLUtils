//
//  ViewController.m
//  SKOpenGLUtilsLib
//
//  Created by Sunflower on 2020/4/28.
//  Copyright © 2020 Sunflower. All rights reserved.
//

#import "ViewController.h"

#import "SKAudioFileStream.h"

@interface ViewController ()<SKAudioFileStreamDelegate>

@property (nonatomic, strong) SKAudioFileStream *audioFileStream;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"47061" ofType:@"mp3"];
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:path];
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    NSError *error = nil;
    _audioFileStream = [[SKAudioFileStream alloc]initWithFileType:kAudioFileFLACType fileSize:fileSize error:&error];
    _audioFileStream.delegate = self;
    
    if (error) {
        _audioFileStream = nil;
        NSLog(@"create file stream failed ,error : %@",[error description]);
    }else{
        NSLog(@"audio file open");
        if (file) {
            NSUInteger lengthPerRead = 1024;
            while (fileSize > 0) {
                NSData *data = [file readDataOfLength:lengthPerRead];
                fileSize -= [data length];
                [_audioFileStream parseData:data error:&error];
                if (error) {
                    if (error.code == kAudioFileStreamError_NotOptimized) {
                        NSLog(@"audio not  optimized");
                    }
                    break;
                }
            }
            
            NSLog(@"audio format: bitrate = %u, duration = %lf.",(unsigned int)_audioFileStream.bitRate,_audioFileStream.duration);
            [_audioFileStream close];
            _audioFileStream = nil;
            NSLog(@"xxxxxxxxx_________xxxxxxxxxx");
            [file closeFile];
        }
    }
    
}

- (void)audioFileStreamReadyToProducePackets:(SKAudioFileStream *)audioFileStream
{
    NSLog(@"audio ready to produce packets");
}

- (void)audioFileStream:(SKAudioFileStream *)audioFileStream audioDataParsed:(NSArray *)audioData
{
    NSLog(@"data parse");
}


@end
