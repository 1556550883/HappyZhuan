//
//  BGRunManager.h
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/17.
//  Copyright © 2019年 文高坡. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BGRunManager : NSObject
+ (BGRunManager *)sharedManager;

/**
 开启后台运行
 */
- (void)startBGRun;

/**
 关闭后台运行
 */
- (void)stopBGRun;
@end
