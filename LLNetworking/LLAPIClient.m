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
        dfconfigValue = [[NSMutableDictionary alloc]init];

    });
    return dfconfigValue;
}

- (NSString *)configurePath
{
    NSMutableString *newUrl = [NSMutableString stringWithString:_path];

    NSMutableDictionary *configValue = [[NSMutableDictionary alloc]initWithDictionary:[LLHTTPEntity defaultConfig]];
 

    NSMutableArray *configString = [[NSMutableArray alloc]init];
    
    NSArray *key = [configValue allKeys];
    
    for (int i = 0; i < key.count; i++) {
        
        NSString *value = [configValue objectForKey:key[i]];
        [configString addObject:[NSString stringWithFormat:@"%@=%@",key[i],[value stringByURLEncode]]];
    }
    if ([newUrl rangeOfString:@"?"].location != NSNotFound) {
        [newUrl appendFormat:@"&%@",[configString componentsJoinedByString:@"&"]];
    }
    else
    {
        [newUrl appendFormat:@"?%@",[configString componentsJoinedByString:@"&"]];
    }
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
            return [[LLAPIClient sharedClient] GET:[entity configurePath] parameters:entity.params ?: @{} progress:^(NSProgress * _Nonnull downloadProgress) {
                
            }success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
            {
                [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
            {
                [LLAPIClient handleFailureWithEntity:entity completion:completion failure:failure error:error];
            }];
        } break;
        
        case LLHTTPMethodPOST:
        {
            return [[LLAPIClient sharedClient] POST:[entity configurePath] parameters:entity.params
            progress:^(NSProgress * _Nonnull downloadProgress) {
                                               
            }success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [LLAPIClient handleFailureWithEntity:entity completion:completion failure:failure error:error];
            }];
        } break;
        
        case LLHTTPMethodPOSTWithMultiMedia:
        {
            [LLAPIClient sharedClient].requestSerializer.timeoutInterval = REQUEST_TIME_OUT * 3;
            return [[LLAPIClient sharedClient] POST:[entity configurePath] parameters:entity.params ?: @{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData){
                if (entity.media.medias.count){
                    for (NSInteger i = 0; i < entity.media.medias.count; i ++) {
                        if (entity.media.type == LLMediaTypeImage)
                        {
                            UIImage * image = entity.media.medias[i];
                            [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 0.7) name: entity.media.name?:@"" fileName:entity.media.fileName?:@"" mimeType:@"image/jpeg"];
                        }
                    }
                }
            }
            progress:^(NSProgress * _Nonnull downloadProgress) {
                                               
            }success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
            return [[LLAPIClient sharedClient] GET:[entity configurePath] ?: @"" parameters:entity.params ?: @{}
            progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                [LLAPIClient handleResponseObject:responseObject entity:entity completion:completion warning:warning];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [LLAPIClient handleFailureWithEntity:entity completion:completion warning:warning failure:failure error:error];
            }];
        } break;
            
        case LLHTTPMethodPOST:
        {
            return [[LLAPIClient sharedClient] POST:[entity configurePath] ?: @"" parameters:entity.params ?: @{}
           progress:^(NSProgress * _Nonnull downloadProgress) {
                                               
           }success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
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
                    }
                   progress:^(NSProgress * _Nonnull downloadProgress) {
                       
                   }success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
        if (entity.targetClass) {
            id viewModel = [entity.targetClass modelWithJSON:responseObject];
            [self networkCodeWithViewModel:result];
            if (viewModel)
            {
                if (completion) {
                    completion(viewModel);
                }
            }
        }else{
            if (completion) {
                completion(responseObject);
            }
        }
    }
    else
    {
        if ([[LLAPIClient cache] containsObjectForKey:cacheKey] && entity.cacheEnable)
        {
            id json = [[LLAPIClient cache] objectForKey:cacheKey];
            NSLog(@"JSON from cache : %@", json);
            if (entity.targetClass) {
                id viewModel = [entity.targetClass modelWithJSON:json];
                if (completion) {
                    completion(viewModel);
                }
            }else{
                if (completion) {
                    completion(json);
                }
            }
        }
        else {
            if (completion) {
                completion(nil);
            }
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
        if (entity.targetClass) {
            id viewModel = [entity.targetClass modelWithJSON:responseObject];
            if ([result integerValue] == 1) {
                completion(viewModel);
            } else{
                warning(viewModel);
            }
        } else {
            if ([result integerValue] == 1) {
                completion(responseObject);
            } else{
                warning(responseObject);
            }
        }
        [self networkCodeWithViewModel:result];
    }else{
        if (entity.cacheEnable && [[LLAPIClient cache] containsObjectForKey:cacheKey])
        {
            id json = [[LLAPIClient cache] objectForKey:cacheKey];
            NSLog(@"JSON from cache : %@", json);
            NSString *result = [json objectForKey:RESPONSE_RESULT_KEY];
            if (entity.targetClass) {
                id viewModel = [entity.targetClass modelWithJSON:json];
                if ([result integerValue] == 1) {
                    completion(viewModel);
                }
                else
                {
                    warning(viewModel);
                }
            } else {
                if ([result integerValue] == 1) {
                    completion(json);
                }
                else{
                    warning(json);
                }
            }
        }else{
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
        if (entity.targetClass) {
            id viewModel = [entity.targetClass modelWithJSON:json];
            completion(viewModel);
        } else {
            completion(json);
        }
    }else{
        if (failure){
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
        NSString *result = [json objectForKey:RESPONSE_RESULT_KEY];
        if (entity.targetClass) {
            id viewModel = [entity.targetClass modelWithJSON:json];
            if ([result integerValue] == 1) {
                completion(viewModel);
            } else{
                warning(viewModel);
            }
        } else {
            if ([result integerValue] == 1) {
                completion(json);
            } else{
                warning(json);
            }
        }
    }else{
        if (failure){
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
