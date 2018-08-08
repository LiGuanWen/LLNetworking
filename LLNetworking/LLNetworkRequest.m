//
//  LLNetworkRequest.m
//  AFNetworkingDemo
//
//  Created by huangyibiao on 15/11/15.
//  Copyright © 2015年 huangyibiao. All rights reserved.
//

#import "LLNetworkRequest.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AFNetworking.h"
#import "AFHTTPSessionManager.h"

#import <CommonCrypto/CommonDigest.h>

@interface NSString (md5)

+ (NSString *)LLNetworkRequest_md5:(NSString *)string;

@end

@implementation NSString (md5)

+ (NSString *)LLNetworkRequest_md5:(NSString *)string {
  if (string == nil || [string length] == 0) {
    return nil;
  }
  
  unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
  CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
  NSMutableString *ms = [NSMutableString string];
  
  for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [ms appendFormat:@"%02x", (int)(digest[i])];
  }
  
  return [ms copy];
}

@end

static NSString *sg_privateNetworkBaseUrl = nil;
static BOOL sg_isEnableInterfaceDebug = NO;
static BOOL sg_shouldAutoEncode = NO;
static NSDictionary *sg_httpHeaders = nil;
static LLResponseType sg_responseType = kLLResponseTypeJSON;
static LLRequestType  sg_requestType  = kLLRequestTypePlainText;
static LLNetworkStatus sg_networkStatus = kLLNetworkStatusReachableViaWiFi;
static NSMutableArray *sg_requestTasks;
static BOOL sg_cacheGet = YES;
static BOOL sg_cachePost = NO;
static BOOL sg_shouldCallbackOnCancelRequest = YES;
static NSTimeInterval sg_timeout = 60.0f;
static BOOL sg_shoulObtainLocalWhenUnconnected = NO;
static BOOL sg_isBaseURLChanged = YES;
static AFHTTPSessionManager *sg_sharedManager = nil;
static NSUInteger sg_maxCacheSize = 0;

@implementation LLNetworkRequest

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // 尝试清除缓存
    if (sg_maxCacheSize > 0 && [self totalCacheSize] > 1024 * 1024 * sg_maxCacheSize) {
      [self clearCaches];
    }
  });
}

+ (void)autoToClearCacheWithLimitedToSize:(NSUInteger)mSize {
  sg_maxCacheSize = mSize;
}

+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost {
  sg_cacheGet = isCacheGet;
  sg_cachePost = shouldCachePost;
}

+ (void)updateBaseUrl:(NSString *)baseUrl {
  if (![baseUrl isEqualToString:sg_privateNetworkBaseUrl] && baseUrl && baseUrl.length) {
    sg_isBaseURLChanged = YES;
  } else {
    sg_isBaseURLChanged = NO;
  }
  
  sg_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
  return sg_privateNetworkBaseUrl;
}

+ (void)setTimeout:(NSTimeInterval)timeout {
  sg_timeout = timeout;
}

+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain {
  sg_shoulObtainLocalWhenUnconnected = shouldObtain;
  if (sg_shoulObtainLocalWhenUnconnected && (sg_cacheGet || sg_cachePost)) {
    [self detectNetwork];
  }
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
  sg_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
  return sg_isEnableInterfaceDebug;
}

static inline NSString *cachePath() {
  return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LLNetworkRequestCaches"];
}

+ (void)clearCaches {
  NSString *directoryPath = cachePath();
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
    
    if (error) {
      NSLog(@"LLNetworkRequest clear caches error: %@", error);
    } else {
      NSLog(@"LLNetworkRequest clear caches ok");
    }
  }
}

+ (unsigned long long)totalCacheSize {
  NSString *directoryPath = cachePath();
  BOOL isDir = NO;
  unsigned long long total = 0;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
    if (isDir) {
      NSError *error = nil;
      NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
      
      if (error == nil) {
        for (NSString *subpath in array) {
          NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
          NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                error:&error];
          if (!error) {
            total += [dict[NSFileSize] unsignedIntegerValue];
          }
        }
      }
    }
  }
  
  return total;
}

+ (NSMutableArray *)allTasks {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (sg_requestTasks == nil) {
      sg_requestTasks = [[NSMutableArray alloc] init];
    }
  });
  
  return sg_requestTasks;
}

+ (void)cancelAllRequest {
  @synchronized(self) {
    [[self allTasks] enumerateObjectsUsingBlock:^(LLURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
      if ([task isKindOfClass:[LLURLSessionTask class]]) {
        [task cancel];
      }
    }];
    
    [[self allTasks] removeAllObjects];
  };
}

+ (void)cancelRequestWithURL:(NSString *)url {
  if (url == nil) {
    return;
  }
  
  @synchronized(self) {
    [[self allTasks] enumerateObjectsUsingBlock:^(LLURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
      if ([task isKindOfClass:[LLURLSessionTask class]]
          && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
        [task cancel];
        [[self allTasks] removeObject:task];
        return;
      }
    }];
  };
}

+ (void)configRequestType:(LLRequestType)requestType
             responseType:(LLResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest {
  sg_requestType = requestType;
  sg_responseType = responseType;
  sg_shouldAutoEncode = shouldAutoEncode;
  sg_shouldCallbackOnCancelRequest = shouldCallbackOnCancelRequest;
}

+ (BOOL)shouldEncode {
  return sg_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
  sg_httpHeaders = httpHeaders;
}

+ (LLURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          success:(LLResponseSuccess)success
                             fail:(LLResponseFail)fail {
  return [self getWithUrl:url
             refreshCache:refreshCache
                   params:nil
                  success:success
                     fail:fail];
}

+ (LLURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(LLResponseSuccess)success
                             fail:(LLResponseFail)fail {
  return [self getWithUrl:url
             refreshCache:refreshCache
                   params:params
                 progress:nil
                  success:success
                     fail:fail];
}

+ (LLURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                         progress:(LLGetProgress)progress
                          success:(LLResponseSuccess)success
                             fail:(LLResponseFail)fail {
  return [self _requestWithUrl:url
                  refreshCache:refreshCache
                     httpMedth:1
                        params:params
                      progress:progress
                       success:success
                          fail:fail];
}

+ (LLURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                           success:(LLResponseSuccess)success
                              fail:(LLResponseFail)fail {
  return [self postWithUrl:url
              refreshCache:refreshCache
                    params:params
                  progress:nil
                   success:success
                      fail:fail];
}

+ (LLURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                          progress:(LLPostProgress)progress
                           success:(LLResponseSuccess)success
                              fail:(LLResponseFail)fail {
  return [self _requestWithUrl:url
                  refreshCache:refreshCache
                     httpMedth:2
                        params:params
                      progress:progress
                       success:success
                          fail:fail];
}

+ (LLURLSessionTask *)_requestWithUrl:(NSString *)url
                          refreshCache:(BOOL)refreshCache
                             httpMedth:(NSUInteger)httpMethod
                                params:(NSDictionary *)params
                              progress:(LLDownloadProgress)progress
                               success:(LLResponseSuccess)success
                                  fail:(LLResponseFail)fail {
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }

  AFHTTPSessionManager *manager = [self manager];
  NSString *absolute = [self absoluteUrlWithPath:url];
  
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      LLAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    NSURL *absoluteURL = [NSURL URLWithString:absolute];
    
    if (absoluteURL == nil) {
      LLAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  LLURLSessionTask *session = nil;
  
  if (httpMethod == 1) {
    if (sg_cacheGet) {
      if (sg_shoulObtainLocalWhenUnconnected) {
        if (sg_networkStatus == kLLNetworkStatusNotReachable ||  sg_networkStatus == kLLNetworkStatusUnknown ) {
          id response = [LLNetworkRequest cahceResponseWithURL:absolute
                                                 parameters:params];
          if (response) {
            if (success) {
              [self successResponse:response callback:success];
              
              if ([self isDebug]) {
                [self logWithSuccessResponse:response
                                         url:absolute
                                      params:params];
              }
            }
            return nil;
          }
        }
      }
      if (!refreshCache) {// 获取缓存
        id response = [LLNetworkRequest cahceResponseWithURL:absolute
                                               parameters:params];
        if (response) {
          if (success) {
            [self successResponse:response callback:success];
            
            if ([self isDebug]) {
              [self logWithSuccessResponse:response
                                       url:absolute
                                    params:params];
            }
          }
          return nil;
        }
      }
    }
    
    session = [manager GET:absolute parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
      if (progress) {
        progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
      }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      [self successResponse:responseObject callback:success];
      
      if (sg_cacheGet) {
        [self cacheResponseObject:responseObject request:task.currentRequest parameters:params];
      }
      
      [[self allTasks] removeObject:task];
      
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:absolute
                              params:params];
      }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      [[self allTasks] removeObject:task];
      
      if ([error code] < 0 && sg_cacheGet) {// 获取缓存
        id response = [LLNetworkRequest cahceResponseWithURL:absolute
                                               parameters:params];
        if (response) {
          if (success) {
            [self successResponse:response callback:success];
            
            if ([self isDebug]) {
              [self logWithSuccessResponse:response
                                       url:absolute
                                    params:params];
            }
          }
        } else {
          [self handleCallbackWithError:error fail:fail];
          
          if ([self isDebug]) {
            [self logWithFailError:error url:absolute params:params];
          }
        }
      } else {
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
          [self logWithFailError:error url:absolute params:params];
        }
      }
    }];
  } else if (httpMethod == 2) {
    if (sg_cachePost ) {// 获取缓存
      if (sg_shoulObtainLocalWhenUnconnected) {
        if (sg_networkStatus == kLLNetworkStatusNotReachable ||  sg_networkStatus == kLLNetworkStatusUnknown ) {
          id response = [LLNetworkRequest cahceResponseWithURL:absolute
                                                 parameters:params];
          if (response) {
            if (success) {
              [self successResponse:response callback:success];
              
              if ([self isDebug]) {
                [self logWithSuccessResponse:response
                                         url:absolute
                                      params:params];
              }
            }
            return nil;
          }
        }
      }
      if (!refreshCache) {
        id response = [LLNetworkRequest cahceResponseWithURL:absolute
                                               parameters:params];
        if (response) {
          if (success) {
            [self successResponse:response callback:success];
            
            if ([self isDebug]) {
              [self logWithSuccessResponse:response
                                       url:absolute
                                    params:params];
            }
          }
          return nil;
        }
      }
    }
    
    session = [manager POST:absolute parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
      if (progress) {
        progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
      }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      [self successResponse:responseObject callback:success];
      
      if (sg_cachePost) {
        [self cacheResponseObject:responseObject request:task.currentRequest  parameters:params];
      }
      
      [[self allTasks] removeObject:task];
      
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:absolute
                              params:params];
      }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      [[self allTasks] removeObject:task];
      
      if ([error code] < 0 && sg_cachePost) {// 获取缓存
        id response = [LLNetworkRequest cahceResponseWithURL:absolute
                                               parameters:params];
        
        if (response) {
          if (success) {
            [self successResponse:response callback:success];
            
            if ([self isDebug]) {
              [self logWithSuccessResponse:response
                                       url:absolute
                                    params:params];
            }
          }
        } else {
          [self handleCallbackWithError:error fail:fail];
          
          if ([self isDebug]) {
            [self logWithFailError:error url:absolute params:params];
          }
        }
      } else {
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
          [self logWithFailError:error url:absolute params:params];
        }
      }
    }];
  }
  
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

+ (LLURLSessionTask *)uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(LLUploadProgress)progress
                                 success:(LLResponseSuccess)success
                                    fail:(LLResponseFail)fail {
  if ([NSURL URLWithString:uploadingFile] == nil) {
    LLAppLog(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
    return nil;
  }
  
  NSURL *uploadURL = nil;
  if ([self baseUrl] == nil) {
    uploadURL = [NSURL URLWithString:url];
  } else {
    uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]];
  }
  
  if (uploadURL == nil) {
    LLAppLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
    return nil;
  }
  
  AFHTTPSessionManager *manager = [self manager];
  NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
  LLURLSessionTask *session = nil;
  
  [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
    if (progress) {
      progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
    }
  } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
    [[self allTasks] removeObject:session];
    
    [self successResponse:responseObject callback:success];
    
    if (error) {
      [self handleCallbackWithError:error fail:fail];
      
      if ([self isDebug]) {
        [self logWithFailError:error url:response.URL.absoluteString params:nil];
      }
    } else {
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:response.URL.absoluteString
                              params:nil];
      }
    }
  }];
  
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

+ (LLURLSessionTask *)uploadWithImage:(UIImage *)image
                                   url:(NSString *)url
                              filename:(NSString *)filename
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(LLUploadProgress)progress
                               success:(LLResponseSuccess)success
                                  fail:(LLResponseFail)fail {
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      LLAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
      LLAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  NSString *absolute = [self absoluteUrlWithPath:url];
  
  AFHTTPSessionManager *manager = [self manager];
  LLURLSessionTask *session = [manager POST:absolute parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    
    NSString *imageFileName = filename;
    if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      NSString *str = [formatter stringFromDate:[NSDate date]];
      imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
    }
    
    // 上传图片，以文件流的格式
    [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
  } progress:^(NSProgress * _Nonnull uploadProgress) {
    if (progress) {
      progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
    }
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    [[self allTasks] removeObject:task];
    [self successResponse:responseObject callback:success];
    
    if ([self isDebug]) {
      [self logWithSuccessResponse:responseObject
                               url:absolute
                            params:parameters];
    }
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    [[self allTasks] removeObject:task];
    
    [self handleCallbackWithError:error fail:fail];
    
    if ([self isDebug]) {
      [self logWithFailError:error url:absolute params:nil];
    }
  }];
  
  [session resume];
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

+ (LLURLSessionTask *)downloadWithUrl:(NSString *)url
                            saveToPath:(NSString *)saveToPath
                              progress:(LLDownloadProgress)progressBlock
                               success:(LLResponseSuccess)success
                               failure:(LLResponseFail)failure {
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      LLAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
      LLAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
  AFHTTPSessionManager *manager = [self manager];
  
  LLURLSessionTask *session = nil;
  
  session = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
    if (progressBlock) {
      progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
    }
  } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
    return [NSURL fileURLWithPath:saveToPath];
  } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
    [[self allTasks] removeObject:session];
    
    if (error == nil) {
      if (success) {
        success(filePath.absoluteString);
      }
      
      if ([self isDebug]) {
        LLAppLog(@"Download success for url %@",
                  [self absoluteUrlWithPath:url]);
      }
    } else {
      [self handleCallbackWithError:error fail:failure];
      
      if ([self isDebug]) {
        LLAppLog(@"Download fail for url %@, reason : %@",
                  [self absoluteUrlWithPath:url],
                  [error description]);
      }
    }
  }];
  
  [session resume];
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

#pragma mark - Private
+ (AFHTTPSessionManager *)manager {
  @synchronized (self) {
    // 只要不切换baseurl，就一直使用同一个session manager
    if (sg_sharedManager == nil || sg_isBaseURLChanged) {
      // 开启转圈圈
      [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
      
      AFHTTPSessionManager *manager = nil;;
      if ([self baseUrl] != nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
      } else {
        manager = [AFHTTPSessionManager manager];
      }
      
      switch (sg_requestType) {
        case kLLRequestTypeJSON: {
          manager.requestSerializer = [AFJSONRequestSerializer serializer];
          break;
        }
        case kLLRequestTypePlainText: {
          manager.requestSerializer = [AFHTTPRequestSerializer serializer];
          break;
        }
        default: {
          break;
        }
      }
      
      switch (sg_responseType) {
        case kLLResponseTypeJSON: {
          manager.responseSerializer = [AFJSONResponseSerializer serializer];
          break;
        }
        case kLLResponseTypeXML: {
          manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
          break;
        }
        case kLLResponseTypeData: {
          manager.responseSerializer = [AFHTTPResponseSerializer serializer];
          break;
        }
        default: {
          break;
        }
      }
      
      manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
      
      
      for (NSString *key in sg_httpHeaders.allKeys) {
        if (sg_httpHeaders[key] != nil) {
          [manager.requestSerializer setValue:sg_httpHeaders[key] forHTTPHeaderField:key];
        }
      }
      
      manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                @"text/html",
                                                                                @"text/json",
                                                                                @"text/plain",
                                                                                @"text/javascript",
                                                                                @"text/xml",
                                                                                @"image/*"]];
      
      manager.requestSerializer.timeoutInterval = sg_timeout;
      
      // 设置允许同时最大并发数量，过大容易出问题
      manager.operationQueue.maxConcurrentOperationCount = 3;
      sg_sharedManager = manager;
    }
  }
  
  return sg_sharedManager;
}

+ (void)detectNetwork {
  AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
  
  [reachabilityManager startMonitoring];
  [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
    if (status == AFNetworkReachabilityStatusNotReachable){
      sg_networkStatus = kLLNetworkStatusNotReachable;
    } else if (status == AFNetworkReachabilityStatusUnknown){
      sg_networkStatus = kLLNetworkStatusUnknown;
    } else if (status == AFNetworkReachabilityStatusReachableViaWWAN){
      sg_networkStatus = kLLNetworkStatusReachableViaWWAN;
    } else if (status == AFNetworkReachabilityStatusReachableViaWiFi){
      sg_networkStatus = kLLNetworkStatusReachableViaWiFi;
    }
  }];
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
  LLAppLog(@"\n");
  LLAppLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
            [self generateGETAbsoluteURL:url params:params],
            params,
            [self tryToParseData:response]);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
  NSString *format = @" params: ";
  if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
    format = @"";
    params = @"";
  }
  
  LLAppLog(@"\n");
  if ([error code] == NSURLErrorCancelled) {
    LLAppLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              format,
              params);
  } else {
    LLAppLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              format,
              params,
              [error localizedDescription]);
  }
}

// 仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
  if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
    return url;
  }
  
  NSString *queries = @"";
  for (NSString *key in params) {
    id value = [params objectForKey:key];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
      continue;
    } else if ([value isKindOfClass:[NSArray class]]) {
      continue;
    } else if ([value isKindOfClass:[NSSet class]]) {
      continue;
    } else {
      queries = [NSString stringWithFormat:@"%@%@=%@&",
                 (queries.length == 0 ? @"&" : queries),
                 key,
                 value];
    }
  }
  
  if (queries.length > 1) {
    queries = [queries substringToIndex:queries.length - 1];
  }
  
  if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
    if ([url rangeOfString:@"?"].location != NSNotFound
        || [url rangeOfString:@"#"].location != NSNotFound) {
      url = [NSString stringWithFormat:@"%@%@", url, queries];
    } else {
      queries = [queries substringFromIndex:1];
      url = [NSString stringWithFormat:@"%@?%@", url, queries];
    }
  }
  
  return url.length == 0 ? queries : url;
}


+ (NSString *)encodeUrl:(NSString *)url {
  return [self LL_URLEncode:url];
}

+ (id)tryToParseData:(id)responseData {
  if ([responseData isKindOfClass:[NSData class]]) {
    // 尝试解析成JSON
    if (responseData == nil) {
      return responseData;
    } else {
      NSError *error = nil;
      NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
      
      if (error != nil) {
        return responseData;
      } else {
        return response;
      }
    }
  } else {
    return responseData;
  }
}

+ (void)successResponse:(id)responseData callback:(LLResponseSuccess)success {
  if (success) {
    success([self tryToParseData:responseData]);
  }
}

+ (NSString *)LL_URLEncode:(NSString *)url {
  return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
  // 采用下面的方式反而不能请求成功
//  NSString *newString =
//  CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                            (CFStringRef)url,
//                                                            NULL,
//                                                            CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
//  if (newString) {
//    return newString;
//  }
//  
//  return url;
}

+ (id)cahceResponseWithURL:(NSString *)url parameters:params {
  id cacheData = nil;
  
  if (url) {
    // Try to get datas from disk
    NSString *directoryPath = cachePath();
    NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
    NSString *key = [NSString LLNetworkRequest_md5:absoluteURL];
    NSString *path = [directoryPath stringByAppendingPathComponent:key];
    
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    if (data) {
      cacheData = data;
      LLAppLog(@"Read data from cache for url: %@\n", url);
    }
  }
  
  return cacheData;
}

+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request parameters:params {
  if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
    NSString *directoryPath = cachePath();
    
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
      [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&error];
      if (error) {
        LLAppLog(@"create cache dir error: %@\n", error);
        return;
      }
    }
    
    NSString *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params];
    NSString *key = [NSString LLNetworkRequest_md5:absoluteURL];
    NSString *path = [directoryPath stringByAppendingPathComponent:key];
    NSDictionary *dict = (NSDictionary *)responseObject;
    
    NSData *data = nil;
    if ([dict isKindOfClass:[NSData class]]) {
      data = responseObject;
    } else {
      data = [NSJSONSerialization dataWithJSONObject:dict
                                             options:NSJSONWritingPrettyPrinted
                                               error:&error];
    }
    
    if (data && error == nil) {
      BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
      if (isOk) {
        LLAppLog(@"cache file ok for request: %@\n", absoluteURL);
      } else {
        LLAppLog(@"cache file error for request: %@\n", absoluteURL);
      }
    }
  }
}

+ (NSString *)absoluteUrlWithPath:(NSString *)path {
  if (path == nil || path.length == 0) {
    return @"";
  }
  
  if ([self baseUrl] == nil || [[self baseUrl] length] == 0) {
    return path;
  }
  
  NSString *absoluteUrl = path;
  
  if (![path hasPrefix:@"http://"] && ![path hasPrefix:@"https://"]) {
    if ([[self baseUrl] hasSuffix:@"/"]) {
      if ([path hasPrefix:@"/"]) {
        NSMutableString * mutablePath = [NSMutableString stringWithString:path];
        [mutablePath deleteCharactersInRange:NSMakeRange(0, 1)];
        absoluteUrl = [NSString stringWithFormat:@"%@%@",
                       [self baseUrl], mutablePath];
      } else {
        absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
      }
    } else {
      if ([path hasPrefix:@"/"]) {
        absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
      } else {
        absoluteUrl = [NSString stringWithFormat:@"%@/%@",
                       [self baseUrl], path];
      }
    }
  }
  
  return absoluteUrl;
}

+ (void)handleCallbackWithError:(NSError *)error fail:(LLResponseFail)fail {
  if ([error code] == NSURLErrorCancelled) {
    if (sg_shouldCallbackOnCancelRequest) {
      if (fail) {
        fail(error);
      }
    }
  } else {
    if (fail) {
      fail(error);
    }
  }
}

@end
