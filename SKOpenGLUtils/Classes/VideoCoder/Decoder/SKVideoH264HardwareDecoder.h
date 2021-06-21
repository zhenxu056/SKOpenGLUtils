//
//  SKVideoH264HardwareDecoder.h
//
//
//  Created by  on 2019/3/23.
//  Copyright © 2019 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKVideoDecoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKVideoH264HardwareDecoder : NSObject <SKVideoDecoder>

#pragma mark - <-- Initializer -->
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithSps:(NSData *)sps
                        pps:(NSData *)pps
                   delegate:(id<SKVideoDecoderDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
