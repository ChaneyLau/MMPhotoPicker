//
//  AppDelegate.m
//  MMPhotoPickerPodDemo
//
//  Created by LEA on 2024/10/14.
//  Copyright © 2024 LEA. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "UIImage+Color.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    ViewController *controller = [[ViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    navigation.navigationBar.tintColor = [UIColor whiteColor];
    navigation.navigationBar.translucent = NO;
    
    NSMutableDictionary *atts = [NSMutableDictionary new];
    [atts setObject:[UIFont boldSystemFontOfSize:19.0] forKey:NSFontAttributeName];
    [atts setObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]]];
        [appearance setTitleTextAttributes:atts];
        navigation.navigationBar.standardAppearance = appearance;
        navigation.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        [navigation.navigationBar setTitleTextAttributes:atts];
        [navigation.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forBarMetrics:UIBarMetricsDefault];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
