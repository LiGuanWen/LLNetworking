//
//  LLBaseRequest.h
//  Pods
//
//  Created by Lilong on 2017/6/11.
//
//

#import "YTKRequest.h"

@interface LLBaseRequest : YTKRequest

- (id)initWithRequestUrl:(NSString *)requestUrl requestbaseUrl:(NSString *)requestbaseUrl requestMethodType:(YTKRequestMethod )requestMethodType ;
@end
