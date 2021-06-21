//
//  DVAudioEncoder.h
//  iOS_Test
//
//  Created by DV on 2019/9/25.
//  Copyright © 2019 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN
@protocol SKAudioEncoder;
@protocol SKAudioEncoderDelegate <NSObject>

- (void)DVAudioEncoder:(nullable id<SKAudioEncoder>)encoder
             codedData:(nullable NSData *)data
              userInfo:(nullable void *)userInfo;
@end



@protocol SKAudioEncoder <NSObject>
@optional

#pragma mark - <-- Property -->
@property(nonatomic, weak) id<SKAudioEncoderDelegate> delegate;


#pragma mark - <-- Method -->
- (instancetype)initWithInputBasicDesc:(AudioStreamBasicDescription)inputBasicDesc
                       outputBasicDesc:(AudioStreamBasicDescription)outputBasicDesc
                              delegate:(id<SKAudioEncoderDelegate>)delegate;

- (void)encodeAudioData:(nullable NSData *)data
               userInfo:(nullable void *)userInfo;

- (void)encodeAudioData:(nullable void *)data
                   size:(UInt32)size
               userInfo:(nullable void *)userInfo;

- (void)closeEncoder;


- (NSData *)convertToADTSWithData:(NSData *)sourceData channel:(NSInteger)channel;

@end

NS_ASSUME_NONNULL_END
