//
//  DVAudioConfig.m
//  iOS_Test
//
//  Created by DV on 2019/1/10.
//  Copyright © 2019年 iOS. All rights reserved.
//

#import "SKAudioConfig.h"

@implementation SKAudioConfig

#pragma mark - <-- Instancetype -->
- (instancetype)initWithSampleRate:(NSUInteger)sampleRate
                    bitsPerChannel:(UInt32)bits
                  numberOfChannels:(UInt32)channels {
    self = [super init];
    if (self) {
        self.sampleRate = sampleRate;
        self.bitsPerChannel = bits;
        self.numberOfChannels = channels;
    }
    return self;
}

+ (instancetype)configWithSampleRate:(NSUInteger)sampleRate
                      bitsPerChannel:(UInt32)bits
                    numberOfChannels:(UInt32)channels {
    return [[SKAudioConfig alloc] initWithSampleRate:sampleRate
                                      bitsPerChannel:bits
                                    numberOfChannels:channels];
}



#pragma mark - <-- Property -->
- (NSUInteger)bitRate {    
    return ( [self numberOfChannels] * [self bitsPerChannel] / 8 ) * [self sampleRate];
}



#pragma mark - <-- PCM -->
+ (SKAudioConfig *)kConfig_8k_16bit_1ch {
    return [self configWithSampleRate:8000 bitsPerChannel:16 numberOfChannels:1];
}

+ (SKAudioConfig *)kConfig_8k_16bit_2ch {
    return [self configWithSampleRate:8000 bitsPerChannel:16 numberOfChannels:2];
}

+ (SKAudioConfig *)kConfig_16k_16bit_1ch {
    return [self configWithSampleRate:16000 bitsPerChannel:16 numberOfChannels:1];
}

+ (SKAudioConfig *)kConfig_16k_16bit_2ch {
    return [self configWithSampleRate:16000 bitsPerChannel:16 numberOfChannels:2];
}

+ (SKAudioConfig *)kConfig_44k_16bit_1ch {
    return [self configWithSampleRate:44100 bitsPerChannel:16 numberOfChannels:1];
}

+ (SKAudioConfig *)kConfig_44k_16bit_2ch {
    return [self configWithSampleRate:44100 bitsPerChannel:16 numberOfChannels:2];
}

+ (SKAudioConfig *)kConfig_48k_16bit_1ch {
    return [self configWithSampleRate:48000 bitsPerChannel:16 numberOfChannels:1];
}

+ (SKAudioConfig *)kConfig_48k_16bit_2ch {
    return [self configWithSampleRate:48000 bitsPerChannel:16 numberOfChannels:2];
}


@end








