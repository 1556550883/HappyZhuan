//
//  ViewController.m
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/12.
//  Copyright © 2019年 文高坡. All rights reserved.
//

#import "ViewController.h"
#import "UserInfo.h"
#import "NetWorkRequest.h"
#import <AdSupport/AdSupport.h>
#import <sys/utsname.h>
#import "SQLiteManager.h"
#import "wechat/WXApi.h"
#import "wechat/WXApiObject.h"
#import "wechat/WechatAuthSDK.h"

#define GetLoginKey @"GetLoginKey"
#define m_baseUrl @"https://moneyzhuan.com/"

//#define m_baseUrl @"http://192.168.0.101:8080/"
@interface ViewController ()

@end

@implementation ViewController
  NSString *device = @"";
  NSString *appID = @"";
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //监听一个通知，当收到通知时，调用notificationAction方法
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(run) name:@"UIApplicationDidBecomeActiveNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WXLoginSuccess:) name:@"WXLoginSuccessNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WXShare) name:@"WXShareNotification" object:nil];
    
    _tfbgview.userInteractionEnabled = YES;
    _bgimage.userInteractionEnabled = YES;
    _registerudid.userInteractionEnabled = YES;
    
    _start_btn.userInteractionEnabled = YES;
    _openinstall_btn.userInteractionEnabled = YES;
}

- (void)run
{
    [self queryData];
}

- (void)WXShare
{
}

- (void)WXLoginSuccess: (NSNotification *)notification
{
    
    NSString *code = notification.object;
    NSString *requestName = @"getAccess";
    NSString *url = @"https://api.weixin.qq.com/sns/oauth2/access_token?";
    NSMutableDictionary *postInfo = [NSMutableDictionary dictionary];
   
    NSLog(@"code=%@", code);
    postInfo[@"appid"] = @"wx976c46a725b070f6";
    postInfo[@"secret"] = @"1b86568c4efe3c8998e58758338989eb";
    postInfo[@"code"] = code;
    postInfo[@"grant_type"] = @"authorization_code";
    
    [NetWorkRequest netWorkRequestByPostMode:url parameters:postInfo requestName:requestName delegate:self];
}

- (IBAction)registerUser:(id)obj{

    NSString *url = [m_baseUrl stringByAppendingString:@"download/happyzhuan.mobileconfig"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (IBAction)startTask:(id)obj{
    NSString *url = @"http://moneyzhuan.com/main";
    NSLog(@"==============this is url%@", url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (IBAction)installOpen:(id)obj{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Hellworld" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
    
    NSString *url = [m_baseUrl stringByAppendingString:@"download/happywebclip.mobileconfig"];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}


- (void)setUnderLineForButton:(UIButton *)btn withTitle:(NSString *)title{
    
    //利用富文本的方式增加button下划线
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithString:title];
    
    NSRange strRange = {0,[str length]};
    
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    
    [btn setAttributedTitle:str forState:UIControlStateNormal];
    
}


- (void)queryData
{
    NSArray *userInfos = [UserInfo loadData];
    if(userInfos == nil || userInfos.count <= 0){
        _registerudid.hidden = false;
        return;
    }
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithString:@"点击安装入口，永不丢失！"];
    
    NSRange strRange = {0,[str length]};
    
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    
    [_openinstall_btn setAttributedTitle:str forState:UIControlStateNormal];
    
    
    UserInfo *user = userInfos[0];
    
    NSLog(@"udid-------%@", user.deviceuuid);
    device = user.deviceuuid;
   
    NSString *idfas = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *phoneModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *phoneVersion = [[UIDevice currentDevice] systemVersion];
    
    NSString *requestName = GetLoginKey;
    NSString *url = [m_baseUrl stringByAppendingString:@"app/user/updateUserByUdid?"];
    
    if([self isBlankString:user.idfa]){
        NSMutableDictionary *postInfo = [NSMutableDictionary dictionary];
        
        postInfo[@"udid"] = user.deviceuuid;
        postInfo[@"idfa"] = idfas;
        postInfo[@"phoneModel"] = phoneModel;
        postInfo[@"phoneVersion"] =phoneVersion;
        [NetWorkRequest netWorkRequestByPostMode:url parameters:postInfo requestName:requestName delegate:self];
    }else{
        _registerudid.hidden = true;
        _start_btn.hidden = false;
        _openinstall_btn.hidden = false;
        _registerudid.hidden = true;
        _tip_label.hidden = false;
        _appid_label.hidden = false;
        _appid_label.text=user.appid;
    }
}

- (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    if ([string isEqualToString:@"(null)"]||[string isEqualToString:@"<null>"]||[string isEqualToString:@"null"]) {
        return YES;
    }
    return NO;
}

-(void)netWorkRequestSuccess:(id)data userInfo:(NSDictionary *)userInfo parameters:(NSDictionary *)getparameters
{
    //服务器连接成功
    NSString *requestUsername = [userInfo objectForKey:@"username"];
    
    if ([requestUsername isEqualToString:GetLoginKey]) {
        
        NSDictionary *dicR = (NSDictionary *)data;
        
        NSString *result = [dicR objectForKey:@"result"];
         NSLog(@"result========%@",result);
        //请求成功
        NSString *codeStr = [NSString stringWithFormat:@"%@",result];

        if([codeStr isEqualToString: @"1"]){
            appID = [dicR objectForKey:@"obj"];
            appID = [NSString stringWithFormat:@"%@",appID];
            [self updateData];
            
            _registerudid.hidden = true;
            _start_btn.hidden = false;
            _openinstall_btn.hidden = false;
            _registerudid.hidden = true;
            //设置appid
            _tip_label.hidden = false;
            _appid_label.hidden = false;
            _appid_label.text= appID;
        }
    }
    else if([requestUsername isEqualToString:@"getAccess"]){
         NSDictionary *dicR = (NSDictionary *)data;
         NSString *access_token = [dicR objectForKey:@"access_token"];
         NSString *openid = [dicR objectForKey:@"openid"];
        
        NSString *requestName = @"updateUserWeiXin";
        NSString *url = [m_baseUrl stringByAppendingString:@"app/user/getWeChatApi?"];
        //NSString *url = [@"http://192.168.0.101:8080/" stringByAppendingString:@"app/user/getWeChatApi?"];
        NSMutableDictionary *postInfo = [NSMutableDictionary dictionary];
        postInfo[@"accessToken"] = access_token;
        postInfo[@"udid"] = device;
        postInfo[@"openID"] =openid;
        [NetWorkRequest netWorkRequestByPostMode:url parameters:postInfo requestName:requestName delegate:self];
    } else if([requestUsername isEqualToString:@"updateUserWeiXin"]){
         NSLog(@"updateUserWeiXin========%@",@"updateUserWeiXin");
        NSString *url = @"http://moneyzhuan.com/main";
        NSLog(@"==============this is url%@", url);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    
}



- (void)updateData
{
    // 1.更新的SQL
    NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *phoneModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *phoneVersion = [[UIDevice currentDevice] systemVersion];
    
    NSString *updateSQL = [NSString stringWithFormat:@"UPDATE t_user_info SET idfa = '%@',phoneModel='%@',phoneVersion='%@',appid='%@' WHERE deviceuuid = '%@';", idfa,phoneModel,phoneVersion,appID,device];
    
    // 2.执行sql
    if ([[SQLiteManager shareInstance] execSQL:updateSQL]) {
        NSLog(@"updateData===================更新数据成功");
    }
}


-(void)netWorkRequestFailed:(NSError*)error userInfo:(NSDictionary *)userInfo parameters:(NSDictionary *)getparameters
{
    //服务器连接失败请重试
    NSLog(@"%@",error);
}


@end
