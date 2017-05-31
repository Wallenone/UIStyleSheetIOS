//
//  EZJUIStyleHelper.h
//  UIStyleSheetIOS
//
//  Created by Easy233 on 16/1/14.
//  Copyright © 2016年 wallen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface EZJUIStyleHelper : NSObject


+ (instancetype)shared;

//加载yaml文件
- (void)paserStyleWithStyle:(NSString *)styleFile;


//解析yaml数据
-(void)setUIControlStyle:(id)obj;

@end
