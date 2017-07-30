//
//  ViewController.m
//  LLNetworkingDemo
//
//  Created by Lilong on 2017/4/5.
//  Copyright © 2017年 李龙. All rights reserved.
//

#import "ViewController.h"
#import "LLBaseRequest.h"
#import "LLAPIClient.h"
#import "LLNetworkRequest.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}


/**
 GET
 */
- (IBAction)getRequestAction:(id)sender {
//    [self LLBaseRequest];
//    [self LLAPIClient];
    [self LLNetworkRequest];
}

- (IBAction)postRequestAction:(id)sender {
}


- (IBAction)headRequestAction:(id)sender {
}


/**
 猿题库 方式封装
 */
- (void)LLBaseRequest{
    LLBaseRequest *api = [[LLBaseRequest alloc] initWithRequestUrl:@"/api3/user/goodsList" requestbaseUrl:nil requestMethodType:YTKRequestMethodGET params:nil cacheTimeInSeconds:40];
    if ([api loadCacheWithError:nil]) {
        NSDictionary *json = [api responseJSONObject];
        NSLog(@"json = %@", json);
        // show cached data
    }
    [api startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSLog(@"");
        NSLog(@"%@",api.description);
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSLog(@"");
    }];
}

- (void)LLAPIClient{
    LLHTTPEntity *entity = [LLHTTPEntity new];
    entity.method = LLHTTPMethodGET;
    entity.path = @"/api3/user/goodsList";
    entity.params = @{};
    
    [LLAPIClient requireWithEntity:entity completion:^(id viewModel) {
        NSLog(@"成功");
    } failure:^(NSError *error) {
        NSLog(@"失败");
    }];
}


/**
 LLNetworkRequest 请求方式
 */
- (void)LLNetworkRequest{
    [LLNetworkRequest getWithUrl:@"http://api.autoplusone.com/api3/user/goodsList" refreshCache:NO
    success:^(id response) {
        NSLog(@"成功");
    } fail:^(NSError *error) {
        NSLog(@"失败");
    }];
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
