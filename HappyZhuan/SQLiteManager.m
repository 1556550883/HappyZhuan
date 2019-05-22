//
//  SQLiteManager.m
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/13.
//  Copyright © 2019年 文高坡. All rights reserved.
//
#import "SQLiteManager.h"
#import <sqlite3.h>

@interface SQLiteManager ()

@property (nonatomic, assign) sqlite3 *db;

@end

@implementation SQLiteManager

static id _instance;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

#pragma mark - 创建或者打开数据库
- (BOOL)openDB
{
    // 获取沙盒路径,将数据库放入沙盒中
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    filePath = [filePath stringByAppendingPathComponent:@"my.sqlite"];
    
    // 如果有对应的数据库,则打开对应的数据库.如果没有对应的数据库,则创建数据库
    // 1> 参数一:文件路径(数据库的存放路径)
    // 2> 参数二:操作数据库的对象
    if (sqlite3_open(filePath.UTF8String, &_db) != SQLITE_OK) {
        NSLog(@"打开数据库失败");
        return NO;
    }
    
    // 如果打开数据成功,则创建一张表,用于之前存放数据
    return [self createTable];
}

- (BOOL)createTable {
    // 1.定义创建表的SQL语句
    NSString *createTableSQL = @"CREATE TABLE IF NOT EXISTS 't_user_info' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'deviceuuid' TEXT,'idfa' TEXT,'phoneModel' TEXT,'phoneVersion' TEXT,'appid' TEXT);";
    
    // 2.执行SQL语句
    return [self execSQL:createTableSQL];
}

- (BOOL)execSQL:(NSString *)sql
{
    // 执行sql语句
    // 1> 参数一:数据库sqlite3对象
    // 2> 参数二:执行的sql语句
    return sqlite3_exec(self.db, sql.UTF8String, nil, nil, nil) == SQLITE_OK;
}

#pragma mark - 查询数据
- (NSArray *)querySQL:(NSString *)querySQL
{
    // 定义游标对象
    sqlite3_stmt *stmt = nil;
    
    // 准备工作(获取查询的游标对象)
    // 1> 参数三:查询语句的长度, -1自动计算
    // 2> 参数四:查询的游标对象地址
    if (sqlite3_prepare_v2(self.db, querySQL.UTF8String, -1, &stmt, nil) != SQLITE_OK) {
        NSLog(@"没有准备成功");
        return nil;
    }
    
    // 取出某一个行数的数据
    NSMutableArray *tempArray = [NSMutableArray array];
    // 获取字段的个数
    int count = sqlite3_column_count(stmt);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (int i = 0; i < count; i++) {
            // 1.取出当前字段的名称(key)
            NSString *key = [NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
            
            // 2.取出当前字段对应的值(value)
            const char *cValue = (const char *)sqlite3_column_text(stmt, i);
            NSString *value = [NSString stringWithUTF8String:cValue];
            
            // 3.将键值对放入字典中
            [dict setObject:value forKey:key];
        }
        
        [tempArray addObject:dict];
    }
    
    // 不再使用游标时,需要释放对象
    sqlite3_finalize(stmt);
    
    return tempArray;
}

@end
