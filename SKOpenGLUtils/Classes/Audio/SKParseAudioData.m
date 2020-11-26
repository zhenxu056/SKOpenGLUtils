//
//  SKParseAudioData.m
//  Pods-SKOpenGLUtilsLib
//
//  Created by Sunflower on 2020/8/27.
//

#import "SKParseAudioData.h"

@implementation SKParseAudioData

@synthesize  data = _data;
@synthesize  packetDescription = _packetDescription;

+ (instancetype)parsedAudioDataWithBytes:(const void *)bytes packetDescription:(AudioStreamPacketDescription)packetDescription
{
    return [[self alloc]initWithBytes:bytes packetDescription:packetDescription];
}

- (instancetype)initWithBytes:(const void *)bytes packetDescription:(AudioStreamPacketDescription)packDescription
{
    if (bytes == NULL || packDescription.mDataByteSize == 0) {
        return nil;
    }
    if (self = [super init]) {
        _data = [NSData dataWithBytes:bytes length:packDescription.mDataByteSize];
        _packetDescription = packDescription;
    }
    return self;
}

@end
