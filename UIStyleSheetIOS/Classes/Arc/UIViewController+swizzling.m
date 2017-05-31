//
//  UIViewController+swizzling.m
//  iOSSwizzlingDemo
//
//  Created by wallen on 16/1/15
//  Copyright (c) 2016年 wallen. All rights reserved.
//

#import "UIViewController+swizzling.h"
#import <objc/runtime.h>
#import "EZJUIStyleHelper.h"

@implementation UIViewController (swizzling)

+ (void)load
{
    
    SEL origSel = @selector(viewWillAppear:);
    SEL swizSel = @selector(swiz_viewWillAppear:);
    SEL origSelWill = @selector(viewWillDisappear:);
    SEL swizSelWill = @selector(swiz_WillViewDidAppear:);
    SEL origSelLoad = @selector(viewDidLoad);
    SEL swizSelLoad = @selector(swiz_viewDidLoad);
    
    [UIViewController swizzleMethods:[self class] originalSelector:origSel swizzledSelector:swizSel];//viewDidAppear方法
    [UIViewController swizzleMethods:[self class] originalSelector:origSelWill swizzledSelector:swizSelWill]; //viewWillDisappear方法
    [UIViewController swizzleMethods:[self class] originalSelector:origSelLoad swizzledSelector:swizSelLoad]; //viewDidLoad方法
}

+ (void)swizzleMethods:(Class)class originalSelector:(SEL)origSel swizzledSelector:(SEL)swizSel
{
    Method origMethod = class_getInstanceMethod(class, origSel);
    Method swizMethod = class_getInstanceMethod(class, swizSel);
    
    BOOL didAddMethod = class_addMethod(class, origSel, method_getImplementation(swizMethod), method_getTypeEncoding(swizMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swizSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}


- (void)swiz_viewWillAppear:(BOOL)animated
{
    //需要注入的代码写在此处
    [self swiz_viewWillAppear:animated];
}

- (void)swiz_WillViewDidAppear:(BOOL)animated
{
    //需要注入的代码写在此处
    [self swiz_WillViewDidAppear:animated];
}

- (void)swiz_viewDidLoad
{
    NSString *className= NSStringFromClass([self class]);
    className=[NSString stringWithFormat:@"%@.yaml",className];
    BOOL state=[self judgeFileExist:className];
    if (state) {
        [[EZJUIStyleHelper shared] paserStyleWithStyle:className];
        
        [[EZJUIStyleHelper shared] setUIControlStyle:self];
        [self swiz_viewDidLoad];
    }
    
    
}

-(BOOL)judgeFileExist:(NSString * )fileName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@""];
    if(path==NULL){
        return NO;
    }else{
        return YES;
    }
    
    
    
}


@end
