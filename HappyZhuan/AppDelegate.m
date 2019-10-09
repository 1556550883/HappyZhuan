//
//  AppDelegate.m
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/12.
//  Copyright © 2019年 文高坡. All rights reserved.
//

#import "AppDelegate.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "MyHTTPConnection.h"
#import "SQLiteManager.h"
#import "UserInfo.h"
#import "BGLocationConfig.h"
#import <sys/utsname.h>
#import <AdSupport/AdSupport.h>
#import "BGRunManager.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CloudPushSDK/CloudPushSDK.h>

@interface AppDelegate ()
@property (nonatomic, strong) NSTimer *timer;
@end

static const int ddLogLevel = LOG_LEVEL_VERBOSE;
@implementation AppDelegate
@synthesize window;
_Bool *weChatBind = false;
_Bool *shouldStopBg = false;
//_shouldStopBg
- (void)startServer
{
    // Start the server (and check for problems)
    
    NSError *error;
    if([httpServer start:&error])
    {
        DDLogInfo(@"Started HTTP Server on port %hu", [httpServer listeningPort]);
    }
    else
    {
        DDLogError(@"Error starting HTTP Server: %@", error);
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    BOOL flag = [[SQLiteManager shareInstance] openDB];
    if (flag) {
        NSLog(@"打开数据库成功");
    } else {
        NSLog(@"打开数据库失败");
    }
   
    [WXApi registerApp:@"wx976c46a725b070f6"];

    // Override point for customization after application launch.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Create server using our custom MyHTTPServer class
    httpServer = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [httpServer setType:@"_http._tcp."];
    
    // Normally there's no need to run our server on any specific port.
    // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
    // However, for easy testing you may want force a certain port so you can just hit the refresh button.
    // [httpServer setPort:12345];
    
    // Serve files from our embedded Web folder
    
    NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
    // printf("%s", webPath);
    DDLogInfo(@"Setting document root: %@", webPath);
    
    [httpServer setDocumentRoot:webPath];
    
    [httpServer setConnectionClass:[MyHTTPConnection class]];
    
    [httpServer setPort:80];
    [self startServer];
    

    // 点击通知将App从关闭状态启动时，将通知打开回执上报
    // [CloudPushSDK handleLaunching:launchOptions];(Deprecated from v1.8.1)
    [self  initCloudPush];
     [self  registerAPNS:application];
    [CloudPushSDK  sendNotificationAck:launchOptions];
      [self  registerMessageReceive];
    
    return YES;
}

/*
 *  App处于启动状态时，通知打开回调
 */
- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
    NSLog(@"Receive one notification.");
    // 取得APNS通知内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    // 内容
    NSString *content = [aps valueForKey:@"alert"];
    // badge数量
    NSInteger badge = [[aps valueForKey:@"badge"] integerValue];
    // 播放声音
    NSString *sound = [aps valueForKey:@"sound"];
    // 取得Extras字段内容
    NSString *Extras = [userInfo valueForKey:@"Extras"]; //服务端中Extras字段，key是自己定义的
    NSLog(@"content = [%@], badge = [%ld], sound = [%@], Extras = [%@]", content, (long)badge, sound, Extras);
    // iOS badge 清0
    application.applicationIconBadgeNumber = 0;
    // 通知打开回执上报
    // [CloudPushSDK handleReceiveRemoteNotification:userInfo];(Deprecated from v1.8.1)
    [CloudPushSDK sendNotificationAck:userInfo];
}

- (NSTimer *)timer{
    if (nil == _timer) {
        _timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            //XLLog(@"运行ing");
        }];
        NSRunLoop *curRun = [NSRunLoop currentRunLoop];
        [curRun addTimer:_timer forMode:NSRunLoopCommonModes];
        
    }
    return _timer;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

-(void) applicationDidEnterBackground:(UIApplication *)application{
    UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    shouldStopBg = false;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        while ( TRUE ) {
            if (shouldStopBg ){ break; }
            float remainTime = [[UIApplication sharedApplication] backgroundTimeRemaining];
            NSLog(@"###!!!BackgroundTimeRemaining: %f",remainTime);
            if ( remainTime < 5.0 ){
                NSLog(@"start play audio!");
                NSError *audioSessionError = nil;
                AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                if ( [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&(audioSessionError)] )
                {
                    NSLog(@"set audio session success!");
                }else{
                    NSLog(@"set audio session fail!");
                }
                NSURL *musicUrl = [[NSURL alloc]initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"slience" ofType:@"mp3"]];
                AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:musicUrl error:nil];
                audioPlayer.numberOfLoops = 0;
                audioPlayer.volume = 0;
                [audioPlayer play];
                [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
            [NSThread sleepForTimeInterval:1.0];
        }
    });
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    shouldStopBg = true;
    NSLog(@"applicationDidBecomeActive=====%s", "applicationDidBecomeActive");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidBecomeActiveNotification" object:self];
    if(weChatBind){
        [self bindWeChat];
        weChatBind = false;
    }
    
    if([self isJailBreak2] || [self isJailBreak1]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"不能使用越狱手机" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alert show];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)bindWeChat{
    if ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi]) {
        SendAuthReq *req = [[SendAuthReq alloc] init];
        req.scope = @"snsapi_userinfo";
        req.state = @"HappyZhuanAPP";
  
        [WXApi sendReq:req];
    }else{
        //把微信登录的按钮隐藏掉
        NSString * msg = @"请先安装您的微信";
        if([WXApi isWXAppSupportApi]){
            msg = @"您的微信版本不支持登录，请更新您的版本！";
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    //NSLog(@"url=====%@ \n  sourceApplication=======%@ \n  annotation======%@", url, sourceApplication, annotation);
    NSString * text = url.absoluteString;
    NSLog(@"text=====%@", text);
    if ([text containsString:@"wechatbind"]) {
        //[self bindWeChat];
        weChatBind = true;
    }
    else if ([text containsString:@"udid="]) {
        //NSString * derange =
        NSRange range = [text rangeOfString:@"="];
        text = [text substringFromIndex: range.location + 1];
        //NSLog(@"text=====%@", text);
        if(text != nil && text != NULL && text.length > 0){
            UserInfo * user = [UserInfo new];
            user.deviceuuid = text;
//            user.idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
//            struct utsname systemInfo;
//            uname(&systemInfo);
//            NSString *phoneModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
//            user.phoneVersion = [[UIDevice currentDevice] systemVersion];
            // 1.删除的SQL
            NSString *deleteSQL = @"DELETE FROM t_user_info;";
            
            // 2.执行SQL
            if ([[SQLiteManager shareInstance] execSQL:deleteSQL]) {
                NSLog(@"删除数据成功");
            }
        
        
            [user insertUserInfo];
        }
    }else if([text containsString:@"isShare"]){
//        NSRange range = [text rangeOfString:@"isShare="];
//        text = [text substringFromIndex: range.location + 8];
//        NSRange range2 = [text rangeOfString:@"userId="];
//        NSString* userid = [text substringFromIndex: range2.location + 7];
        
            WXMediaMessage * message = [WXMediaMessage message];
            message.title = @"我已经通过这款app赚了5000多啦！";
            message.description = @"这是一款边玩手机就能随时随地赚钱多app！";
            [message setThumbImage:[UIImage imageNamed:@"Icon.png"]];
            
            WXWebpageObject * webPageObject = [WXWebpageObject object];
            //webPageObject.webpageUrl = @"https://moneyzhuan.com/invite/guest?id=";
        
            message.mediaObject = webPageObject;
            
            SendMessageToWXReq * req1 = [[SendMessageToWXReq alloc]init];
            req1.bText = NO;
        
            //设置分享到朋友圈(WXSceneTimeline)、好友回话(WXSceneSession)、收藏(WXSceneFavorite)
         if([text containsString:@"Friend"]){
               NSRange range2 = [text rangeOfString:@"Friend="];
                NSString* userid = [text substringFromIndex: range2.location + 7];
               webPageObject.webpageUrl = [@"https://moneyzhuan.com/invite/guest?id=" stringByAppendingString:userid];
             
             req1.message = message;
             req1.scene = WXSceneSession;
         }else{
             NSRange range2 = [text rangeOfString:@"QZone="];
             NSString* userid = [text substringFromIndex: range2.location + 6];
             webPageObject.webpageUrl = [@"https://moneyzhuan.com/invite/guest?id=" stringByAppendingString:userid];
             
              req1.message = message;
             req1.scene = WXSceneTimeline;
         }
        
            dispatch_async(dispatch_get_main_queue(), ^{
            
            [WXApi sendReq:req1]; });
    
        
       
    }else{
        [WXApi handleOpenURL:url delegate:self];
    }
    return YES;
}

-(void) onResp:(BaseResp*)resp{
    /*
     enum  WXErrCode {
     WXSuccess           = 0,    成功
     WXErrCodeCommon     = -1,  普通错误类型
     WXErrCodeUserCancel = -2,    用户点击取消并返回
     WXErrCodeSentFail   = -3,   发送失败
     WXErrCodeAuthDeny   = -4,    授权失败
     WXErrCodeUnsupport  = -5,   微信不支持
     };
     */
    if ([resp isKindOfClass:[SendAuthResp class]]) {   //授权登录的类。
        if (resp.errCode == 0) {  //成功。
            SendAuthResp *resp2 = (SendAuthResp *)resp;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WXLoginSuccessNotification" object:resp2.code];
        }else{ //失败
            NSLog(@"微信绑定失败");
        }
    }
}



- (void)initCloudPush {
    // SDK初始化
    [CloudPushSDK asyncInit:@"25900250" appSecret:@"0138a75c92cc872a508ffb6622756895" callback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            NSLog(@"Push SDK init success, deviceId: %@.", [CloudPushSDK getDeviceId]);
        } else {
            NSLog(@"Push SDK init failed, error: %@", res.error);
        }
    }];
}

/**
 *    注册苹果推送，获取deviceToken用于推送
 *
 *    @param     application
 */
- (void)registerAPNS:(UIApplication *)application {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        // iOS 8 Notifications
        [application registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:
          (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                           categories:nil]];
        [application registerForRemoteNotifications];
    }
    else {
        // iOS < 8 Notifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
}
/*
 *  苹果推送注册成功回调，将苹果返回的deviceToken上传到CloudPush服务器
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [CloudPushSDK registerDevice:deviceToken withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            NSLog(@"Register deviceToken success.%@",deviceToken);
         
        } else {
            NSLog(@"Register deviceToken failed, error: %@", res.error);
        }
    }];
}
/*
 *  苹果推送注册失败回调
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", error);
}

//推送消息到来监听
/**
 *    注册推送消息到来监听
 */
- (void)registerMessageReceive {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageReceived:)
                                                 name:@"CCPDidReceiveMessageNotification"
                                               object:nil];
}
/**
 *    处理到来推送消息
 *
 *    @param     notification
 */
- (void)onMessageReceived:(NSNotification *)notification {
    CCPSysMessage *message = [notification object];
    NSString *title = [[NSString alloc] initWithData:message.title encoding:NSUTF8StringEncoding];
    NSString *body = [[NSString alloc] initWithData:message.body encoding:NSUTF8StringEncoding];
    NSLog(@"Receive message title: %@, content: %@.", title, body);
}

- (BOOL)isJailBreak1 {
    NSArray *jailbreak_tool_paths = @[
                                      @"/Applications/Cydia.app",
                                      @"/Library/MobileSubstrate/MobileSubstrate.dylib",
                                      @"/bin/bash",
                                      @"/usr/sbin/sshd",
                                      @"/etc/apt"
                                      ];
    
    for (int i=0; i<jailbreak_tool_paths.count; i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:jailbreak_tool_paths[i]]) {
            NSLog(@"The device is jail broken!");
            return YES;
        }
    }
    NSLog(@"The device is NOT jail broken!");
    return NO;
}

- (BOOL)isJailBreak2 {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"User/Applications/"]) {
        NSLog(@"The device is jail broken!");
        NSArray *appList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"User/Applications/" error:nil];
        NSLog(@"appList = %@", appList);
        return YES;
    }
    NSLog(@"The device is NOT jail broken!");
    return NO;
}

//通知打开监听

@end
