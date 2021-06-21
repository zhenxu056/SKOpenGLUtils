//
//  DVAudioUnit.h
//  iOS_Test
//
//  Created by DV on 2019/1/10.
//  Copyright © 2019年 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKAudioStreamBaseDesc.h"
#import "SKAudioIOUnit.h"
#import "SKAudioMixUnit.h"
#import "SKAudioError.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - <-------------------- DVAudioUnitDelegate  -------------------->
@class SKAudioUnit;
@protocol SKAudioUnitDelegate <NSObject>

@optional
/**
 *  麦克风输入数据 (已转化成NSData)
 *  @param data 数据
 */
- (void)DVAudioUnit:(SKAudioUnit *)audioUnit
         recordData:(NSData *)data
              error:(SKAudioError *)error;

/**
 *  麦克风输入数据 (未转化成NSData)
 *  @param mdata 原始数据
 *  @param mSize 数据长度
 */
- (void)DVAudioUnit:(SKAudioUnit *)audioUnit
         recordData:(void *)mdata
               size:(UInt32)mSize
              error:(SKAudioError *)error;

@end




#pragma mark - <-------------------- DVAudioUnit  -------------------->
@interface SKAudioUnit : NSObject

#pragma mark - <-- Property -->
@property(nonatomic, assign, readonly) AudioUnit audioUnit;
@property(nonatomic, assign, readonly) BOOL isRunning;

@property(nonatomic, weak) id<SKAudioUnitDelegate> delegate;


#pragma mark - <-- Unit -->
@property(nonatomic, strong, readonly) SKAudioIOUnit *IO;
@property(nonatomic, strong, readonly) SKAudioMixUnit *Mix;


#pragma mark - <-- Initializer -->
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithComponentDesc:(AudioComponentDescription)componentDesc
                             delegate:(id<SKAudioUnitDelegate>)delegate
                                error:(NSError ** _Nullable)error;


#pragma mark - <-- Method -->
/// 初始化AudioUnit配置
- (BOOL)setupUnitConfig:(void(^ _Nullable)(SKAudioUnit* au)) block;

/// 清除AudioUnit配置, 注意: 清除AudioUnit配置前,先调用 'stop' 停止运行
- (BOOL)clearUnitConfig;

/// 开始运行, 注意: 运行前,先调用 'setupUnitConfig' 初始化AudioUnit配置
- (BOOL)start;

/// 停止运行
- (BOOL)stop;

@end

NS_ASSUME_NONNULL_END
