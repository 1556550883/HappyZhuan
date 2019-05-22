
#import "MyHTTPConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPFileResponse.h"
#import "SQLiteManager.h"
#import "UserInfo.h"
#import <objc/runtime.h>
#import "NetWorkRequest.h"
#import <AdSupport/AdSupport.h>
#import "wechat/WXApi.h"
#import "wechat/WXApiObject.h"
#import "wechat/WechatAuthSDK.h"

#define m_baseUrl @"https://moneyzhuan.com/"
// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE; // | HTTP_LOG_FLAG_TRACE;


/**
 * All we have to do is override appropriate methods in HTTPConnection.
 **/

@implementation MyHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    HTTPLogTrace();
    if ([path isEqualToString:@"/getDeviceudid"])
    {
        NSString * deviceuuid = @"";
        NSString * firstidfa = @"";
        NSArray *userInfos = [UserInfo loadData];
        if(userInfos == nil || userInfos.count <= 0){
          
        }else{
            UserInfo *user = userInfos[0];
            deviceuuid = [NSString stringWithFormat:@"%@", user.deviceuuid];
            firstidfa = [NSString stringWithFormat:@"%@", user.idfa];
            
            
            NSString *idfas = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            
            if(![firstidfa isEqualToString:idfas]){
                NSString *url = [m_baseUrl stringByAppendingString:@"app/user/updateUserByUdid?"];
                NSMutableDictionary *postInfo = [NSMutableDictionary dictionary];
                
                postInfo[@"udid"] = user.deviceuuid;
                postInfo[@"idfa"] = idfas;
                postInfo[@"phoneModel"] = user.phoneModel;
                postInfo[@"phoneVersion"] =user.phoneVersion;
                NSString *requestName = @"update";
                [NetWorkRequest netWorkRequestByPostMode:url parameters:postInfo requestName:requestName delegate:self];
            }
        }
        
        NSMutableData * muData = [[NSMutableData alloc] init];
        NSData *data =  [deviceuuid dataUsingEncoding:NSUTF8StringEncoding];
        NSData *version =  [ @"-v1.6" dataUsingEncoding:NSUTF8StringEncoding];
        [muData appendData:data];
        [muData appendData:version];
        HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:muData];
        return response;
    }
    
    if ([path containsString:@"/isAppInstalled"])
    {
        NSString *result = @"0";
        NSString * bundleId = @"";
        NSRange range = [path rangeOfString:@"bundleId="];
        bundleId = [path substringFromIndex: range.location + 9];
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        
        NSObject * workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
        
        BOOL isopen = [workspace performSelector:@selector(openApplicationWithBundleID:) withObject:bundleId];
       
        if(isopen){
            result = @"1";
        }
        
        NSData *data =  [result dataUsingEncoding:NSUTF8StringEncoding];
        HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:data];
        return response;
    }
    
    
    if ([path containsString:@"/isShare"])
    {
        NSString * type = @"";
        NSRange range = [path rangeOfString:@"shareType="];
        type = [path substringFromIndex: range.location + 10];
        NSLog(@"code=%@", type);
        if([type  isEqual: @"0"]){
         
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WXShareNotification" object:self];
        }else{
            
        }
    }
 
    if ([path containsString:@"/openTaskApp"])
    {
        NSString *bundleId = @"";
        NSString *adverId = @"";
        NSRange range = [path rangeOfString:@"bundleId="];
        NSString *temp = [path substringFromIndex: range.location + 9];
        range = [temp rangeOfString:@"&adverId="];
        bundleId = [temp substringToIndex:range.location];
        adverId = [temp substringFromIndex: range.location + 9];
    
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        
        NSObject * workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
        
        BOOL isopen = [workspace performSelector:@selector(openApplicationWithBundleID:) withObject:bundleId];
        
        NSString *result = @"0";
        if(isopen){
            
            result = @"1";
            
            NSString *requestName = @"openApp";
            NSString *url = [m_baseUrl stringByAppendingString:@"app/duijie/openApp?"];
            
            NSMutableDictionary *postInfo = [NSMutableDictionary dictionary];
            
            NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            postInfo[@"idfa"] = idfa;
            postInfo[@"adverId"] = adverId;
           
            [NetWorkRequest netWorkRequestByPostMode:url parameters:postInfo requestName:requestName delegate:self];
        }
        
        NSData *data =  [result dataUsingEncoding:NSUTF8StringEncoding];
        HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:data];
        return response;
    }
    // default behavior for all other paths
    return [super httpResponseForMethod:method URI:path];
}



//- (void)openApp:(NSString *) bundle
//{
//    //创建一个url，这个url就是WXApp的url，记得加上：//
//    NSURL *url = [NSURL URLWithString:@"weixin://"];
//    
//    //打开url
//    [[UIApplication sharedApplication] openURL:url];
//}
@end
