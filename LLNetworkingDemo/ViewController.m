//
//  ViewController.m
//  LLNetworkingDemo
//
//  Created by Lilong on 2017/4/5.
//  Copyright © 2017年 李龙. All rights reserved.
//

#import "ViewController.h"
#import "LLBaseRequest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getAPITest];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)getAPITest{
    LLBaseRequest *request = [[LLBaseRequest alloc] initWithRequestUrl:@"/beating_heart.json" requestbaseUrl:@"http://oqyot9383.bkt.clouddn.com" requestMethodType:YTKRequestMethodGET];
    [request startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSLog(@"");
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSLog(@"");
    }];

}

- (void)postAPITest{

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
