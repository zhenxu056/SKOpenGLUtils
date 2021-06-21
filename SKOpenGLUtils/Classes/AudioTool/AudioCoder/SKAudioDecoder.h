//
//  DVAudioDecoder.h
//  iOS_Test
//
//  Created by DV on 2019/9/25.
//  Copyright © 2019 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - <-------------------- DVAudioDecoderDelegate -------------------->
@protocol SKAudioDecoder;
@protocol SKAudioDecoderDelegate <NSObject>

- (void)DVAudioDecoder:(id<SKAudioDecoder>)decoder
           decodedData:(NSData *)data
              userInfo:(nullable void *)userInfo;

@end


#pragma mark - <-------------------- DVAudioDecoder -------------------->
@protocol SKAudioDecoder <NSObject>
@optional

#pragma mark - <-- Property -->
@property(nonatomic, weak) id<SKAudioDecoderDelegate> delegate;


#pragma mark - <-- Method -->
- (instancetype)initWithInputBasicDesc:(AudioStreamBasicDescription)inputBasicDesc
                       outputBasicDesc:(AudioStreamBasicDescription)outputBasicDesc
                              delegate:(id<SKAudioDecoderDelegate>)delegate;

- (void)decodeAudioData:(nullable NSData *)data
               userInfo:(nullable void *)userInfo;

- (void)decodeAudioData:(nullable void *)data
                   size:(UInt32)size
               userInfo:(nullable void *)userInfo;

- (void)closeDecoder;

@end

NS_ASSUME_NONNULL_END
