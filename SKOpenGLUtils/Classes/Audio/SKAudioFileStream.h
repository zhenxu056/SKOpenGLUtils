//
//  SKAudioFileStream.h
//  Pods-SKOpenGLUtilsLib
//
//  Created by Sunflower on 2020/8/27.
//

#import <Foundation/Foundation.h>

#import <AudioToolbox/AudioToolbox.h>
#import "SKParseAudioData.h"

NS_ASSUME_NONNULL_BEGIN

@class SKAudioFileStream;
@protocol SKAudioFileStreamDelegate <NSObject>
@required
- (void)audioFileStream:(SKAudioFileStream *)audioFileStream audioDataParsed:(NSArray *)audioData;
@optional
- (void)audioFileStreamReadyToProducePackets:(SKAudioFileStream *)audioFileStream;
@end

@interface SKAudioFileStream : NSObject

@property (nonatomic, assign) AudioFileTypeID fileType;
@property (nonatomic, assign) BOOL available;
@property (nonatomic, assign) BOOL readyToProducePackets;
@property (nonatomic, weak) id<SKAudioFileStreamDelegate> delegate;

@property (nonatomic, assign) AudioStreamBasicDescription format;
@property (nonatomic, assign) unsigned long long fileSize;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) UInt32 bitRate;
@property (nonatomic, assign) UInt32 maxPacketSize;
@property (nonatomic, assign) UInt64 audioDataByteCount;


- (instancetype)initWithFileType:(AudioFileTypeID)fileType fileSize:(unsigned long long)fileSize error:(NSError **)error;

- (BOOL)parseData:(NSData *)data error:(NSError **)error;

- (SInt64)seekToTime:(NSTimeInterval *)time;

- (NSData *)fetchMagicCookie;

- (void)close;

@end

NS_ASSUME_NONNULL_END
