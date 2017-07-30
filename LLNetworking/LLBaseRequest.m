//
//  LLBaseRequest.m
//  Pods
//
//  Created by Lilong on 2017/6/11.
//
//

#import "LLBaseRequest.h"

@implementation LLBaseRequest{
    NSString *_requestUrl;  //请求的url
    YTKRequestMethod _requestMethodType;  //请求类型
    NSString *_requestbaseUrl;   //请求的baseUrl
    NSDictionary *_params;   //请求参数
    NSInteger _cacheTimeInSeconds;  //按时间缓存内容
}


- (id)initWithRequestUrl:(NSString *)requestUrl requestbaseUrl:(NSString *)requestbaseUrl requestMethodType:(YTKRequestMethod )requestMethodType params:(NSDictionary *)params cacheTimeInSeconds:(NSInteger)cacheTimeInSeconds{
    self = [super init];
    if (self) {
        _requestUrl = requestUrl;
        _requestMethodType = requestMethodType;
        _requestbaseUrl = requestbaseUrl;
        _params = params;
        _cacheTimeInSeconds = cacheTimeInSeconds;
    }
    return self;
}

- (NSString *)baseUrl {
    if (_requestbaseUrl && _requestbaseUrl.length > 0 ) {
        return _requestbaseUrl;
    }else{
        return @"";
    }
}

- (NSString *)requestUrl {
    return _requestUrl;
}

- (YTKRequestMethod)requestMethod {
    return _requestMethodType;
}

- (id)requestArgument {
    if (_params && ([_params isKindOfClass:[NSDictionary class]] || [_params isKindOfClass:[NSMutableDictionary class]])) {
        return _params;
    }else{
        return @{
                 };
    }
}

- (NSInteger)cacheTimeInSeconds {
    if (!_cacheTimeInSeconds || _cacheTimeInSeconds <= 0) {
        return -1;
    }else{
        return _cacheTimeInSeconds;
    }
}

//- (BOOL)useCDN {
//    return YES;
//}




@end
