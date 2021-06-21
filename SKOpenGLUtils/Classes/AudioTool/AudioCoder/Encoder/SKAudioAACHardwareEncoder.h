//
//  DVAudioHardwareEncoder.h
//  iOS_Test
//
//  Created by DV on 2019/9/25.
//  Copyright © 2019 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKAudioEncoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKAudioAACHardwareEncoder : NSObject <SKAudioEncoder>

#pragma mark - <-- Initializer -->
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
