//
//  LLAPIClient.h
//  LLNetworking
//
//  Created by Lilong on 2017/10/27.
//  Copyright LLNetworking. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
//请求api 头部
static NSString *kLLBaseURL = nil;


//请求成功的code 字段   //默认 result   //如果需要区分waring的话
static NSString *kLL_RESPONSE_RESULT_KEY = @"result";
//请求成功的code 字段   默认 1 
static NSInteger kLL_RESPONSE_RESULT_VALUE = 1;


typedef void(^LLHTTPCompletionBlock)(id viewModel);  //请求成功，返回result为1的结果
typedef void(^LLHTTPFailureBlock)(NSError * error);  //请求失败，放回error
typedef void(^LLHTTPWarningBlock)(id viewModel);     //请求成功，返回result为0的结果

/**
 请求类型
 */
typedef NS_ENUM(NSInteger, LLHTTPMethod){
    LLHTTPMethodGET = 0,
    LLHTTPMethodPOST,
    LLHTTPMethodPOSTWithMultiMedia,
};


/**
 媒体类型
 */
typedef NS_ENUM(NSInteger, LLMediaType){
    LLMediaTypeImage = 0,
    LLMediaTypeAudio,
    LLMediaTypeVideo,
};

@interface LLMedia : NSObject
@property (assign, nonatomic) LLMediaType type;
@property (copy, nonatomic) NSArray * medias;
@property (copy, nonatomic) NSString * name;//单个key对应一张或多张图片
@property (copy, nonatomic) NSArray *names;//多个key个对应一张图片  fileName xxx1的形式
@property (nonatomic, copy) NSString * fileName;

@end


@interface LLHTTPEntity : NSObject

@property (assign, nonatomic) LLHTTPMethod method;
@property (strong, nonatomic) LLMedia * media;

/**
 如果 privateBaseUrl 有值 则请求privateBaseUrl的地址
 */
@property (copy, nonatomic) NSString * privateBaseUrl;
@property (copy, nonatomic) NSString * path;
@property (copy, nonatomic) NSDictionary * params;
@property (strong, nonatomic) Class targetClass;
@property (nonatomic, assign) BOOL cacheEnable;   //是否缓存请求结果, default is NO.


- (NSString *)configurePath;

@end

@interface LLAPIClient : AFHTTPSessionManager

#pragma mark  配置基本参数
/**
 设置请求url
 */
+ (void)setLLBaseUrl:(NSString *)baseUrl;

/**
 获取基本的请求头部
 */
+ (NSString *)baseUrl;

+ (instancetype)sharedClient;


+ (id)requireWithEntity:(LLHTTPEntity *)entity
             completion:(LLHTTPCompletionBlock)completion
                failure:(LLHTTPFailureBlock)failure;


+ (id)requireWithEntity:(LLHTTPEntity *)entity
             completion:(LLHTTPCompletionBlock)completion
                warning:(LLHTTPWarningBlock)warning
                failure:(LLHTTPFailureBlock)failure;


    
@end
