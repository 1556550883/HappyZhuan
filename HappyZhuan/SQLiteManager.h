//
//  SQLiteManager.h
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/13.
//  Copyright © 2019年 文高坡. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface SQLiteManager : NSObject

+ (instancetype)shareInstance;

- (BOOL)openDB;

- (BOOL)execSQL:(NSString *)sql;

- (NSArray *)querySQL:(NSString *)querySQL;

@end

