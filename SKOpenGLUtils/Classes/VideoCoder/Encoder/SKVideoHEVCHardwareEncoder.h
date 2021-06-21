//
//  SKVideoHEVCHardwareEncoder.h
//  iOS_Test
//
//  Created by SK on 2019/10/11.
//  Copyright © 2019 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKVideoEncoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKVideoHEVCHardwareEncoder : NSObject <SKVideoEncoder>

#pragma mark - <-- Initializer -->
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
