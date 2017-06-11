//
//  AppDelegate.h
//  LLNetworkingDemo
//
//  Created by Lilong on 2017/4/5.
//  Copyright © 2017年 李龙. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

//https://github.com/LiGuanWen/YTKNetwork
