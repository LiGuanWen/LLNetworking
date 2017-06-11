//
//  LLBaseRequest.m
//  Pods
//
//  Created by Lilong on 2017/6/11.
//
//

#import "LLBaseRequest.h"

@implementation LLBaseRequest{
    NSString *_requestUrl;
    YTKRequestMethod _requestMethodType;
    NSString *_requestbaseUrl;
}


- (id)initWithRequestUrl:(NSString *)requestUrl requestbaseUrl:(NSString *)requestbaseUrl requestMethodType:(YTKRequestMethod )requestMethodType {
    self = [super init];
    if (self) {
        _requestUrl = requestUrl;
        _requestMethodType = requestMethodType;
        _requestbaseUrl = requestbaseUrl;
    }
    return self;
}

- (NSString *)baseUrl {
    if (_requestbaseUrl) {
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

- (BOOL)useCDN {
    return YES;
}


@end
