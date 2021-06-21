//
//  DVAudioMixUnit.m
//  iOS_Test
//
//  Created by DV on 2019/1/12.
//  Copyright © 2019年 iOS. All rights reserved.
//

#import "SKAudioMixUnit.h"
#import "SKAudioUnit.h"

@interface SKAudioMixUnit()

@property (nonatomic, weak)  SKAudioUnit* wAudioUnit;

@end

@implementation SKAudioMixUnit

- (void)dealloc {
    _wAudioUnit = nil;
}

@end
