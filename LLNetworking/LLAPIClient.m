//
//  LLAPIClient.m
//  LLNetworking
//
//  Created by Lilong on 2017/10/27.
//  Copyright LLNetworking. All rights reserved.

#import "LLAPIClient.h"
#import <YYKit/YYCache.h>
#import <YYKit/NSObject+YYModel.h>
#import <YYKit/NSString+YYAdd.h>
#define RESPONSE_RESULT_KEY @"result"

#define REQUEST_TIME_OUT 100

// BaseURL 是否统一？
static NSString * const kLLHTTPCacheKey = @"LLHTTPCacheKey";

#pragma mark - LLMedia

@implementation LLMedia
@end

#pragma mark - LLHTTPEntity

@implementation LLHTTPEntity

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cacheEnable = NO;
    }
    return self;
}

+(NSMutableDictionary *)defaultConfig
{
    static dispatch_once_t once;
    static NSMutableDictionary *dfconfigValue;
    dispatch_once(&once, ^{
        //拼接网络请求基本参数 （不变参数）
//        
//        dfconfigValue = [[NSMutableDictionary alloc]init];
//        //渠道号
//        [dfconfigValue setObject:@"iOS" forKey:@"ch"];
//        //    [configValue setObject:@"iOS_s_01" forKey:@"ch"];
//        //    [configValue setObject:@"iOS_Dev" forKey:@"ch"];
//        //api版本号
//        [dfconfigValue setObject:@"21" forKey:@"api"];
//        
//        //app版本号
//        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//        if (appVersion)
//        {
//            [dfconfigValue setObject:appVersion forKey:@"ver"];
//        }
//        //appBuild
//        NSString *appBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
//        if (appBuild) {
//            [dfconfigValue setObject:appBuild forKey:@"build"];
//        }
//        //设备信息
//        NSString * strModel  = [LLUitl iphoneType];
//        if (strModel) {
//            [dfconfigValue setObject:strModel forKey:@"model"];
//        }
//        //系统版本
//        NSString *sv = [NSString stringWithFormat:@"%@ %@",[UIDevice currentDevice].systemName,[UIDevice currentDevice].systemVersion];
//        if (sv) {
//            [dfconfigValue setObject:sv forKey:@"sv"];
//        }
//        
//        //设备名称
//        if ([UIDevice currentDevice].name) {
//            [dfconfigValue setObject:[UIDevice currentDevice].name forKey:@"mn"];
//        }
//
//        
//        Class cls = NSClassFromString(@"UMANUtil");
//        NSString *deviceIDFA = nil;
//        SEL deviceIDFaSelector = @selector(idfa);
//        if(cls && [cls respondsToSelector:deviceIDFaSelector]){
//            deviceIDFA = [cls performSelector:deviceIDFaSelector];
//        }
//        
//        if (deviceIDFA && (![deviceIDFA hasPrefix:@"0000"]) && (![deviceIDFA isEqualToString:@""])) {
//            [dfconfigValue setObject:deviceIDFA forKey:@"imei"];
//            [dfconfigValue setObject:@"0" forKey:@"isopenudid"];
//        }else if ([deviceIDFA hasPrefix:@"0000"] || [deviceIDFA isEqualToString:@""])
//        {
//            NSString *deviceIDFA = nil;
//            SEL deviceIDFaSelector = @selector(openUDIDString);
//            if(cls && [cls respondsToSelector:deviceIDFaSelector]){
//                deviceIDFA = [cls performSelector:deviceIDFaSelector];
//            }
//            [dfconfigValue setObject:deviceIDFA forKey:@"imei"];
//            [dfconfigValue setObject:@"1" forKey:@"isopenudid"];
//        }
    });
    return dfconfigValue;
}

- (NSString *)configurePath
{
    NSMutableString *newUrl = [NSMutableString stringWithString:_path];

    NSMutableDictionary *configValue = [[NSMutableDictionary alloc]initWithDictionary:[LLHTTPEntity defaultConfig]];
  
    //拼接网络请求参数 （会变化的  和需要加密的）
//    //经纬度
//    NSString *longt = NSStringFromFloat(CURRENT_BMAP_LONG);
//    if (longt)
//    {
//        [configValue setObject:longt forKey:@"long"];
//    }
//    NSString *lat = NSStringFromFloat(CURRENT_BMAP_LAT);
//    if (lat)
//    {
//        [configValue setObject:lat forKey:@"lat"];
//
//    }
//    //地区ID
//    NSString *areaId = NSStringFromInt(CURRENT_CITY_ID);
//    if (areaId)
//    {
//        [configValue setObject:areaId forKey:@"area_id"];
//    }
//    //用户Uid
//    NSString *currentId = [LLUserManager sharedInstance].userId;
//    if (currentId)
//    {
//        [configValue setObject:currentId forKey:@"user_id"];
//    }
//    //用户token
//    NSString *currentToken = [LLUserManager sharedInstance].token;
//    if (currentToken)
//    {
//        [configValue setObject:currentToken forKey:@"token"];
//    }
//    NSString *t = [LLUitl unixTimestamp];
//    //时间戳
//    [configValue setObject:t forKey:@"nonce"];
//
//    
//    NSMutableArray *array = [[NSMutableArray alloc]initWithObjects:HePaiPayKey,HePaiImKey,HePaiQWKey,HePaiContactsKey,HePaiBaseKey, nil];
//    NSString *str = [array componentsJoinedByString:@"/"];
//    
//    NSMutableString *tt = [[NSMutableString alloc]initWithCapacity:t.length];
//    
//    for (int i = t.length-1 ; i >= 0 ; i--) {
//        [tt appendFormat:@"%c", [t characterAtIndex:i]];
//    }
//    int ttt = (arc4random() % 100001) + 899999;
//    
//    NSString *tttt = [NSString stringWithFormat:@"%d%@",ttt,tt];
//    
//    NSString *hpid = [[NSUserDefaults standardUserDefaults] objectForKey:@"HePai_hpid"];
//    if (hpid && hpid.length > 1) {
//        [configValue setObject:hpid forKey:@"hpid"];
//    }
//    
//    NSString *as = [LLRSAUtil encryptString:[NSString stringWithFormat:@"%@:%@:%@",tttt,configValue[@"imei"],configValue[@"build"]] publicKey:[array componentsJoinedByString:@"/"]];
//    if (as &&as.length >0) {
//        [configValue setObject:as forKey:@"sa"];
//    }
//    
//    //融云token
//    NSString *rctk = [LLUserManager sharedInstance].rongcloudToken;
//    if (rctk && rctk.length > 0) {
//        [configValue setObject:rctk forKey:@"rctk"];
//    }
//    //网易token
//    NSString *netk = [LLUserManager sharedInstance].neteaseToken;
//    if (netk && netk.length > 0) {
//        [configValue setObject:netk forKey:@"netk"];
//    }
//    
//    
//    NSMutableArray *configString = [[NSMutableArray alloc]init];
//    
//    NSArray *key = [configValue allKeys];
//    
//    for (int i = 0; i < key.count; i++) {
//        
//        NSString *value = [configValue objectForKey:key[i]];
//        [configString addObject:[NSString stringWithFormat:@"%@=%@",key[i],[value stringByURLEncode]]];
//    }
//    if ([newUrl rangeOfString:@"?"].location != NSNotFound) {
//        [newUrl appendFormat:@"&%@",[configString componentsJoinedByString:@"&"]];
//    }
//    else
//    {
//        [newUrl appendFormat:@"?%@",[configString componentsJoinedByString:@"&"]];
//    }
    NSLog(@"API:%@  必要参数:%@  提交参数为: %@",kLLBaseURL,newUrl,self.params);
    return newUrl;
}

@end

#pragma mark - LLAPIClient

@implementation LLAPIClient

+ (YYCache *)cache
{
    static YYCache * cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[YYCache alloc] initWithName:kLLHTTPCacheKey];
    });
    return cache;
}

+ (instancetype)sharedClient
{
    static LLAPIClient * sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[LLAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kLLBaseURL]];
        sharedClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        sharedClient.requestSerializer.timeoutInterval = REQUEST_TIME_OUT;
//        [sharedClient.requestSerializer setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
//        NSSet * set = [NSSet setWithObjects:@"text/html",@"application/json", nil];
//        sharedClient.responseSerializer.acceptableContentTypes = set;
    });
    
    return sharedClient;
}

/**
 设置请求url
 */
+ (void)setLLBaseUrl:(NSString *)baseUrl{
    kLLBaseURL = baseUrl;
}
/**
 获取基本的请求头部
 */
+ (NSString *)baseUrl{
    return kLLBaseURL;
}



#pragma mark - 统一请求方法

+ (id)requireWithEntity:(LLHTTPEntity *)entity
             completion:(LLHTTPCompletionBlock)completion
                failure:(LLHTTPFailureBlock)failure
{
    [LLAPIClient sharedClient].requestSerializer.timeoutInterval = REQUEST_TIME_OUT;
    switch (entity.method)
    {
        case LLHTTPMethodGET:
        {
            return [[LLAPIClient sharedClient] GET:[entity configurePath] parameters:entity.params ?: @{} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
            {
                [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
            {
                [LLAPIClient handleFailureWithEntity:entity completion:completion failure:failure error:error];
            }];
        } break;
        
        case LLHTTPMethodPOST:
        {
            return [[LLAPIClient sharedClient] POST:[entity configurePath] parameters:entity.params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [LLAPIClient handleFailureWithEntity:entity completion:completion failure:failure error:error];
            }];
        } break;
        
        case LLHTTPMethodPOSTWithMultiMedia:
        {
            [LLAPIClient sharedClient].requestSerializer.timeoutInterval = REQUEST_TIME_OUT * 3;
            return [[LLAPIClient sharedClient] POST:[entity configurePath] parameters:entity.params ?: @{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData)
            {
                if (entity.media.medias.count)
                {
                    for (NSInteger i = 0; i < entity.media.medias.count; i ++)
                    {
                        LLMedia * media = entity.media.medias[i];
                        if (entity.media.type == LLMediaTypeImage)
                        {
                            UIImage * image = entity.media.medias[i];
                            [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 0.7) name: entity.media.name?:@"" fileName:entity.media.fileName?:@"" mimeType:@"image/jpeg"];
                        }
                    }
                }
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [[self class] handleResponseObject:responseObject entity:entity completion:completion];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [[self class] handleFailureWithEntity:entity completion:completion failure:failure error:error];
            }];
        } break;
        default:
            return nil;
            break;
    }
}

+ (id)requireWithEntity:(LLHTTPEntity *)entity
             completion:(LLHTTPCompletionBlock)completion
                warning:(LLHTTPWarningBlock)warning
                failure:(LLHTTPFailureBlock)failure
{
    [LLAPIClient sharedClient].requestSerializer.timeoutInterval = REQUEST_TIME_OUT;
    switch (entity.method)
    {
        case LLHTTPMethodGET:
        {
            return [[LLAPIClient sharedClient] GET:[entity configurePath] ?: @"" parameters:entity.params ?: @{} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion warning:warning];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [LLAPIClient handleFailureWithEntity:entity completion:completion warning:warning failure:failure error:error];
            }];
        } break;
            
        case LLHTTPMethodPOST:
        {
            return [[LLAPIClient sharedClient] POST:[entity configurePath] ?: @"" parameters:entity.params ?: @{} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion warning:warning];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [LLAPIClient handleFailureWithEntity:entity completion:completion warning:warning failure:failure error:error];
            }];
        } break;
            
        case LLHTTPMethodPOSTWithMultiMedia:
        {
            [LLAPIClient sharedClient].requestSerializer.timeoutInterval = REQUEST_TIME_OUT * 3;
            return [[LLAPIClient sharedClient] POST:[entity configurePath] ?: @"" parameters:entity.params ?: @{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData)
                    {
                        if (entity.media.medias.count)
                        {
                            for (NSInteger i = 0; i < entity.media.medias.count; i ++)
                            {
                                LLMedia * media = entity.media.medias[i];
                                
                                if (entity.media.type == LLMediaTypeImage)
                                {
                                    UIImage * image = entity.media.medias[i];
                                    NSString *imageName = entity.media.name;
                                    NSString *fileName = entity.media.fileName;
                                    if (!imageName) {
                                        NSArray *imageNames = entity.media.names;
                                        if (imageNames.count > i) {
                                            imageName = [imageNames objectAtIndex:i];
                                            fileName = [fileName stringByAppendingString:[NSString stringWithFormat:@"%zd",i]];
                                        }
                                    }
                                    [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 0.7) name:imageName fileName:fileName mimeType:@"image/jpeg"];
                                }
                            }
                        }
                    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion warning:warning];
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        [LLAPIClient handleFailureWithEntity:entity completion:completion warning:warning failure:failure error:error];
                    }];
        } break;
        default:
            return nil;
            break;
    }

}

#pragma mark - 统一处理成功和失败回调

+ (void)handleResponseObject:(id) responseObject
                      entity:(LLHTTPEntity *) entity
                  completion:(LLHTTPCompletionBlock) completion
{
    NSMutableString * cacheKey = [NSMutableString stringWithFormat:@"%@", entity.path];
    if ([[entity.params allKeys] containsObject:@"page"])
    {
        [cacheKey appendFormat:@"%@", entity.params[@"page"]];
    }
    if (responseObject)
    {
        NSLog(@"JSON from response: %@", responseObject);
        NSString *result = [responseObject objectForKey:RESPONSE_RESULT_KEY];
        if (entity.cacheEnable)
        {
            [[LLAPIClient cache] setObject:responseObject forKey:cacheKey];
        }
        
        id viewModel = [entity.targetClass modelWithJSON:responseObject];
        [self networkCodeWithViewModel:result];
        if (viewModel)
        {
            completion(viewModel);
        }
    }
    else
    {
        if ([[LLAPIClient cache] containsObjectForKey:cacheKey] && entity.cacheEnable)
        {
            id json = [[LLAPIClient cache] objectForKey:cacheKey];
            NSLog(@"JSON from cache : %@", json);
            id viewModel = [entity.targetClass modelWithJSON:json];
            completion(viewModel);
        }
        else
        {
            completion(nil);
        }
    }
}

+ (void)handleResponseObject:(id) responseObject
                      entity:(LLHTTPEntity *) entity
                  completion:(LLHTTPCompletionBlock) completion
                     warning:(LLHTTPWarningBlock)warning
{
    NSMutableString * cacheKey = [NSMutableString stringWithFormat:@"%@", entity.path];
    if ([[entity.params allKeys] containsObject:@"page"])
    {
        [cacheKey appendFormat:@"%@", entity.params[@"page"]];
    }
    if (responseObject)
    {
        NSLog(@"JSON from response: %@", responseObject);
        if (entity.cacheEnable)
        {
            [[LLAPIClient cache] setObject:responseObject forKey:cacheKey];
        }

        NSString *result = [responseObject objectForKey:RESPONSE_RESULT_KEY];
        id viewModel = [entity.targetClass modelWithJSON:responseObject];
        [self networkCodeWithViewModel:result];

        if ([result integerValue] == 1) {
            completion(viewModel);
        }
        else
        {
            warning(viewModel);
        }
    }
    else
    {
        if (entity.cacheEnable && [[LLAPIClient cache] containsObjectForKey:cacheKey])
        {
            id json = [[LLAPIClient cache] objectForKey:cacheKey];
            NSLog(@"JSON from cache : %@", json);
            id viewModel = [entity.targetClass modelWithJSON:json];
            NSString *result = [json objectForKey:RESPONSE_RESULT_KEY];
            if ([result integerValue] == 1) {
                completion(viewModel);
            }
            else
            {
                warning(viewModel);
            }
        }
        else
        {
            completion(nil);
        }
    }
}


+ (void)handleFailureWithEntity:(LLHTTPEntity *) entity
                     completion:(LLHTTPCompletionBlock) completion
                        failure:(LLHTTPFailureBlock) failure
                          error:(NSError *) error
{
    NSMutableString * cacheKey = [NSMutableString stringWithFormat:@"%@", entity.path];
    if ([[entity.params allKeys] containsObject:@"page"])
    {
        [cacheKey appendFormat:@"%@", entity.params[@"page"]];
    }
    if ([[LLAPIClient cache] containsObjectForKey:cacheKey])
    {
        id json = [[LLAPIClient cache] objectForKey:cacheKey];
        NSLog(@"JSON from cache : %@", json);
        id viewModel = [entity.targetClass modelWithJSON:json];
        completion(viewModel);
    }
    else
    {
        if (failure)
        {
            failure(error);
        }
    }
    NSLog(@"error = %@", [error localizedDescription]);
}

+ (void)handleFailureWithEntity:(LLHTTPEntity *) entity
                     completion:(LLHTTPCompletionBlock) completion
                        warning:(LLHTTPWarningBlock)warning
                        failure:(LLHTTPFailureBlock) failure
                          error:(NSError *) error
{
    NSMutableString * cacheKey = [NSMutableString stringWithFormat:@"%@", entity.path];
    if ([[entity.params allKeys] containsObject:@"page"])
    {
        [cacheKey appendFormat:@"%@", entity.params[@"page"]];
    }
    if (entity.cacheEnable && [[LLAPIClient cache] containsObjectForKey:cacheKey])
    {
        id json = [[LLAPIClient cache] objectForKey:cacheKey];
        NSLog(@"JSON from cache : %@", json);
        id viewModel = [entity.targetClass modelWithJSON:json];
        NSString *result = [json objectForKey:RESPONSE_RESULT_KEY];
        if ([result integerValue] == 1) {
            completion(viewModel);
        }
        else
        {
            warning(viewModel);
        }
    }
    else
    {
        if (failure)
        {
            failure(error);
        }
    }
    NSLog(@"error = %@", [error localizedDescription]);
}



/**
 errorCode
 */
+ (void)networkCodeWithViewModel:(NSString *)resultCode{
    NSInteger errcode = [resultCode integerValue];
    if (errcode == 2 ) {  //判断是否需要弹出输入验证码提示框
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kHEPErrorCodeISTwoHandle" object:nil userInfo:nil];
    }
}
    
@end
