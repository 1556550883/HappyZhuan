//
//  AppDelegate.h
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/12.
//  Copyright © 2019年 文高坡. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "wechat/WXApi.h"
@class HTTPServer;

@interface AppDelegate : UIResponder <UIApplicationDelegate,WXApiDelegate>
{
    HTTPServer *httpServer;
    
    UIWindow *window;
}

@property (nonatomic) IBOutlet UIWindow *window;

@end

