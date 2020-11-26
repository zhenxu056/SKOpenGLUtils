//
//  SKParseAudioData.h
//  Pods-SKOpenGLUtilsLib
//
//  Created by Sunflower on 2020/8/27.
//

#import <Foundation/Foundation.h>

#import <CoreAudio/CoreAudioTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKParseAudioData : NSObject

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) AudioStreamPacketDescription packetDescription;

+ (instancetype)parsedAudioDataWithBytes:(const void *)bytes packetDescription:(AudioStreamPacketDescription)packetDescription;


@end

NS_ASSUME_NONNULL_END
