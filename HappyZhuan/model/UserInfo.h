//
//  UserInfo.h
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/13.
//  Copyright © 2019年 文高坡. All rights reserved.
//
@interface UserInfo : NSObject
//INTEGER

@property (nonatomic, copy) NSString *deviceuuid;
@property (nonatomic, copy) NSString *idfa;
@property (nonatomic, copy) NSString *phoneModel;
@property (nonatomic, copy) NSString *phoneVersion;
@property (nonatomic, copy) NSString *appid;

- (instancetype)initWithDict:(NSDictionary *)dict;

- (void)insertUserInfo;

+ (NSArray *)loadData;

+ (NSArray *)loadDataWithKeyword:(NSString *)keyword;

@end
