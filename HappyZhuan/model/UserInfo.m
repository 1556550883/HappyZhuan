//
//  UserInfo.m
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/13.
//  Copyright © 2019年 文高坡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserInfo.h"
#import "SQLiteManager.h"
@implementation UserInfo

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)insertUserInfo
{
//    @property (nonatomic, copy) NSString *idfa;
//    @property (nonatomic, copy) NSString *phoneModel;
//    @property (nonatomic, copy) NSString *phoneVersion;
    // 1.通过属性拼接出来,插入语句
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO t_user_info (deviceuuid,idfa,phoneModel,phoneVersion,appid) VALUES ('%@','%@','%@','%@','%@');", self.deviceuuid,self.idfa,self.phoneModel,self.phoneVersion,self.appid];
   
    // 2.执行该sql语句
    if ([[SQLiteManager shareInstance] execSQL:insertSQL]) {
        NSLog(@"插入数据成功");
    }
}

+ (NSArray *)loadData
{
    // 1.封装查询语句
    NSString *querySQL = @"SELECT deviceuuid,idfa,phoneModel,phoneVersion,appid FROM t_user_info;";
    
    return [self loadDataWithQuerySQL:querySQL];
}


+ (NSArray *)loadDataWithKeyword:(NSString *)keyword
{
    // 1.封装查询语句
    NSString *querySQL = [NSString stringWithFormat:@"SELECT  deviceuuid,idfa,phoneModel,phoneVersion,appid FROM t_user_info WHERE deviceuuid like '%%%@%%';", keyword];
    
    return [self loadDataWithQuerySQL:querySQL];
}

+ (NSArray *)loadDataWithQuerySQL:(NSString *)querySQL
{
    // 2.执行查询语句
    NSArray *dictArray = [[SQLiteManager shareInstance] querySQL:querySQL];
    
    // 3.将数组中的字典转成模型对象
    NSMutableArray *stus = [NSMutableArray array];
    for (NSDictionary *dict in dictArray) {
        [stus addObject:[[UserInfo alloc] initWithDict:dict]];
    }
    
    return stus;
}

@end

