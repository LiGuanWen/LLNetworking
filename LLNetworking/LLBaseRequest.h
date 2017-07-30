//
//  LLBaseRequest.h
//  Pods
//
//  Created by Lilong on 2017/6/11.
//
//

#import "YTKRequest.h"


// 项目打包上线都不会打印日志，因此可放心。
#ifdef DEBUG
#define LLAppLog(s, ... ) NSLog( @"[%@ in line %d] ===============>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define LLAppLog(s, ... )
#endif
@interface LLBaseRequest : YTKRequest

/**
 请求

 @param requestUrl 请求url
 @param requestbaseUrl 请求baseUrl 可以为空 如果为空就用全局配置的baseUrl
 @param requestMethodType 请求类型
 @param params 请求参数 如果没有传nil 或者@{}
 @param cacheTimeInSeconds 设置请求时间间隔 如果 = 5 则表示 5秒内调用多次只会真正触发请求一次 同时 这个也是设置是否将数据缓存起来 使用条件 大于0
 @return 对象
 */
- (id)initWithRequestUrl:(NSString *)requestUrl requestbaseUrl:(NSString *)requestbaseUrl requestMethodType:(YTKRequestMethod )requestMethodType params:(NSDictionary *)params cacheTimeInSeconds:(NSInteger)cacheTimeInSeconds;
@end
 
