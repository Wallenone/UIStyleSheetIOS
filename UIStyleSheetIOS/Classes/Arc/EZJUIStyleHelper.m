//
//  EZJUIStyleHelper.m
//  UIStyleSheetIOS
//
//  Created by Easy233 on 16/1/14.
//  Copyright © 2016年 wallen. All rights reserved.
//

#import "EZJUIStyleHelper.h"
#import "YAMLSerialization.h"
#import <objc/runtime.h>
#import <sys/utsname.h>
#import "Masonry.h"

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width

#define SCREENWIDTHRADIO = ((kScreenWidth) / 320.0)
#define SCREENHEIGHTRADIO = ((kScreenHeight) / 320.0)

#define kPointValue(a) (a/2.0)
#define MAS_SHORTHAND

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define IPHONE_6_SCREEN_RADIO ((SCREEN_RADIO) / (375.0/320))
#define SCREEN_RADIO (IS_IPHONE_6 ? (375.0/320) : (IS_IPHONE_6P ? (414.0/320) : 1.0))


static EZJUIStyleHelper *static_styleHelper;
@interface EZJUIStyleHelper (){
    NSDictionary *controlDict;
    NSArray *_marginS;
    NSArray *_otherS;
}
@property (nonatomic, strong) NSDictionary *styleDict;
@property (nonatomic, strong, readonly) NSDictionary *imageSytleDict;  //图片样式
@property (nonatomic, strong, readonly) NSDictionary *sizeSytleDict;   //尺寸样式
@end
@implementation EZJUIStyleHelper

+ (instancetype)shared
{
    if (static_styleHelper == nil) {
        static_styleHelper = [[EZJUIStyleHelper alloc] init];
    }
    return static_styleHelper;
}

- (instancetype)init
{
    if (self = [super init]) {
        controlDict=nil;
        _marginS=@[@"marginLeft", @"marginRight",@"marginTop",@"marginBottom",@"marginCenterX",@"marginCenterY",@"marginWidth",@"marginHeight",@"marginCenter_X",@"marginCenter_Y"];
        _otherS=@[@"buttonTintColor",@"buttonFont",@"buttonTitle",@"buttonBackgroundImage"];
    }
    return self;
}

- (void)paserStyleWithStyle:(NSString *)styleFile
{
    //读取yaml样式文件
    
    NSError * error = nil;
    
    NSURL * url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:styleFile ofType:@""]];
    
    NSInputStream * stream = [[NSInputStream alloc] initWithURL:url];
    
    NSMutableArray * yaml = [YAMLSerialization YAMLWithStream: stream
                                                      options: kYAMLReadOptionStringScalars
                                                        error: &error];
    
    for (NSDictionary * data in yaml) {
        self.styleDict = data;
    }
    
}

-(Ivar)reflectDataFromString:(NSString *)string class:(Class)cla{
    unsigned int count = 0;
    Ivar *members = class_copyIvarList(cla, &count);
    Ivar var=nil;
    for (int i=0; i<count; i++) {
        Ivar var=members[i];
        NSString * memberName=[NSString stringWithUTF8String:ivar_getName(var)];
        if ([memberName isEqualToString:string]) {
            return var;
        }
        
    }
    return var;
}

- (objc_property_t)properties_aps:(Class)cla propertyName:(NSString *)name
{
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cla, &propertyCount);
    objc_property_t property=nil;
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        NSString * propertyName =[NSString stringWithUTF8String:property_getName(property)]; ;//获取属性名字
        
        if ([propertyName isEqualToString:name]) {
            
            return property;
        }
    }
    
    return property;
}

- (void)parseDic:(NSDictionary *)dic view:(id)view {
    if (![dic isEqual:@""] && view) {
        for (NSString *key in dic) {
            if ([dic[key] isKindOfClass:[NSDictionary class]]) {
                [self parseDic:dic[key] view:[view valueForKey:key]];
            } else {
                [self reflectDataFromOtherControl:view propertyValue:dic[key] propertyKey:key attrString:key];
                //NSLog(@"view:%@ \n key:%@ \n attribute:%@",view, key, dic[key]);
            }
        }
    }
    
}

-(void)setUIControlStyle:(id)obj{
    NSDictionary *dict=[[EZJUIStyleHelper shared].styleDict valueForKey:@"root"];
    NSDictionary *pageDict = nil;
    UIViewController *uVC=obj;
    
    
    for (NSString *valueDict in dict) {
        pageDict=[dict valueForKey:valueDict];
        if (![pageDict isEqual:@""]) {
            for (NSString *viewName in pageDict) {
                if ([pageDict[viewName] isKindOfClass:[NSDictionary class]]) {
                    [self parseDic:pageDict[viewName] view:[uVC valueForKey:viewName]];
                }else{
                    [self reflectDataFromOtherControl:uVC.view propertyValue: pageDict[viewName] propertyKey:viewName attrString:[self propertyAttributeType:viewName class:[uVC.view valueForKey:viewName]]];
                    
                }
                
                
            }
        }
    }
    
    
}



-(NSString *)propertyAttributeType:(NSString *)name class:(id)cla{
    BOOL hasProperty=NO;
    
    NSString *attrString=nil;
    
    
    NSArray *repleaceArr=[[NSArray alloc] initWithObjects:[UIView class],[CALayer class],[cla class],nil];
    
    for (id obj in repleaceArr) {
        hasProperty = class_getProperty(obj, [name UTF8String]) != NULL;
        if (hasProperty) {
            NSString *memberType=[[NSString stringWithUTF8String:property_getAttributes(class_getProperty(obj, [name UTF8String]))] substringFromIndex:2];
            memberType= [self getAttributesString:memberType];
            attrString=memberType;
        }
    }
    
    return attrString;
}

-(BOOL)propertyAttributeBool:(id)cla name:(NSString *)name{
    
    NSArray *repleaceArr=[[NSArray alloc] initWithObjects:[UIView class],[CALayer class],[cla class],nil];
    for (id obj in repleaceArr) {
        objc_property_t property = class_getProperty(obj, [name UTF8String]);
        if(property)return YES;
    }
    
    return NO;
}


-(void)reflectDataFromOtherControl:(id)control propertyValue:(id)value propertyKey:(id)key attrString:
(NSString *)string{
    BOOL ret = NO;
    
    ret=[self propertyAttributeBool:control name:key];
    if (ret) {
        if (![control isKindOfClass:[NSNull class]] && value!=nil) {
            NSString *attrString=[self propertyAttributeType:key class:control];
            [self replaceTypeData:control propertyValue:value propertyKey:key attrString:attrString];
        }
    }else{
        
        //iphone相关属性
        if ([key rangeOfString:@"_"].location != NSNotFound){
            NSArray *val = [key componentsSeparatedByString:@"_"];
            if ([val[0] isEqualToString:deviceName()]) {
                [self replaceTypeData:control propertyValue:value propertyKey:key attrString:string];
            }
        }
        
        //magin 相关属性
        if ([_marginS containsObject:key]) {
            [self replaceTypeData:control propertyValue:value propertyKey:key attrString:string];
        }
        
        //其它 相关属性
        if ([_otherS containsObject:key]) {
            [self replaceTypeData:control propertyValue:value propertyKey:key attrString:string];
        }
        
    }
}


-(void)replaceTypeData:(id)control propertyValue:(id)value propertyKey:(id)key attrString:(NSString *)string{
    
    if ([string isEqualToString:@"NSString"]) {
        [control setValue:value forKey:key];
    }else if ([string isEqualToString:@"UIFont"]){
        [control setValue:[UIFont systemFontOfSize:[value floatValue]*IPHONE_6_SCREEN_RADIO] forKey:key];
    }else if ([string isEqualToString:@"UIColor"]||[string isEqualToString:@"CGColor"]){
        [control setValue:[self colorWithKey:value] forKey:key];
    }else if ([string isEqualToString:@"CGRect"]){
        [control setValue:[NSValue valueWithCGRect:[self frameWithKey:value] ] forKey:key];
    }else if ([string isEqualToString:@"CGPoint"]){
        [control setValue:[NSValue valueWithCGPoint:[self pointWithKey:value]] forKey:key];
    }else if ([string isEqualToString:@"CGSize"]){
        [control setValue:[NSValue valueWithCGSize:[self sizeWithKey:value]] forKey:key];
    }else if ([string isEqualToString:@"UIImage"]){
        [control setImage:[self imageWithKey:value]];
    }else if ([string isEqualToString:@"NSInteger"] ){
        [control setValue:[NSNumber numberWithInteger:[value intValue]] forKey:key];
    }else if ([string isEqualToString:@"CGFloat"] ){
        [control setValue:[NSNumber numberWithInteger:[value floatValue]] forKey:key];
    }else if ([string isEqualToString:@"marginLeft"]){
        [control mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo([control superview].mas_left).with.offset([self adaptationScreenWidth:[value floatValue]]);
        }];
    }else if ([string isEqualToString:@"marginRight"]){
        [control mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo([control superview].mas_right).with.offset([self adaptationScreenWidth:[value floatValue]]);
        }];
    }else if ([string isEqualToString:@"marginTop"]){
        [control mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo([control superview].mas_top).with.offset([self adaptationScreenHeight:[value floatValue]]);
        }];
    }else if ([string isEqualToString:@"marginBottom"]){
        [control mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo([control superview].mas_bottom).with.offset([self adaptationScreenHeight:[value floatValue]]);
        }];
        
    }else if ([string isEqualToString:@"marginCenterX"]){
        if ([value isEqualToString:@"true"]) {
            [control mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo([control superview].mas_centerX);
            }];
        }
    }else if ([string isEqualToString:@"marginCenterY"]){
        if ([value isEqualToString:@"true"]) {
            [control mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo([control superview].mas_centerY);
            }];
        }
    }else if ([string isEqualToString:@"marginCenter_X"]){
        if ([value isKindOfClass:[NSString class]] && [value containsString:@"/"]) {
            NSArray *data = [value componentsSeparatedByString:@"/"];
            float scale  = [data[0] floatValue];
            float fold = [data[1] floatValue];
            float padding =kScreenWidth/scale*fold;
            [control mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo([control superview].mas_left).with.offset(padding);
            }];
        }else{
            [control mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(@([self adaptationScreenHeight:[value floatValue]]));
            }];
        }
    }else if ([string isEqualToString:@"marginCenter_Y"]){
        [control mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(@([self adaptationScreenHeight:[value floatValue]]));
        }];
        if ([value isKindOfClass:[NSString class]] && [value containsString:@"/"]) {
            NSArray *data = [value componentsSeparatedByString:@"/"];
            float scale  = [data[0] floatValue];
            float fold = [data[1] floatValue];
            float padding =kScreenWidth/scale*fold;
            [control mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo([control superview].mas_top).with.offset(padding);
            }];
        }else{
            [control mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(@([self adaptationScreenHeight:[value floatValue]]));
            }];
        }
    }else if ([string isEqualToString:@"marginWidth"]){
        [control mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@([self adaptationScreenWidth:[value floatValue]]));
        }];
    }else if ([string isEqualToString:@"marginHeight"]){
        [control mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@([self adaptationScreenHeight:[value floatValue]]));
        }];
    }else if ([string isEqualToString:@"buttonTintColor"]){
        [control setTitleColor:[self colorWithKey:value] forState:UIControlStateNormal];
    }else if ([string isEqualToString:@"buttonFont"]){
        UIButton *cont=(UIButton *)control;
        cont.titleLabel.font=[UIFont systemFontOfSize:[value floatValue]];
    }else if ([string isEqualToString:@"buttonTitle"]){
        [control setTitle:value forState:UIControlStateNormal];
    }else if ([string isEqualToString:@"buttonBackgroundImage"]){
        [control setBackgroundImage:[UIImage imageNamed:value] forState:UIControlStateNormal];
    }
}


- (UIImage *)imageWithKey:(id)key;
{
    NSString *value = key;
    UIImage *image = nil;
    if (value != nil && [value isEqualToString:@""] == NO) {
        image = [UIImage imageNamed:value];
    }
    
    return image;
}


- (UIEdgeInsets)edgeframeWithKey:(id)key;
{
    NSArray *value = [key componentsSeparatedByString:@","];
    UIEdgeInsets rect = UIEdgeInsetsMake(0, 0, 0, 0);
    NSString *stringValue=[value objectAtIndex:0];
    if (stringValue != nil && [stringValue isEqualToString:@""] == NO) {
        rect=UIEdgeInsetsMake([self adaptationScreenWidth:[[value objectAtIndex:0] floatValue]],
                              [self adaptationScreenHeight:[[value objectAtIndex:1] floatValue]],
                              [self adaptationScreenWidth:[[value objectAtIndex:2] floatValue]],
                              [self adaptationScreenHeight:[[value objectAtIndex:3] floatValue]]);
    }
    return rect;
}

- (CGRect)frameWithKey:(id)key;
{
    NSArray *value = [key componentsSeparatedByString:@","];
    CGRect rect = CGRectMake(0, 0, 0, 0);
    NSString *stringValue=[value objectAtIndex:0];
    if (stringValue != nil && [stringValue isEqualToString:@""] == NO) {
        rect=CGRectMake([self adaptationScreenWidth:[[value objectAtIndex:0] floatValue]],
                        [self adaptationScreenHeight:[[value objectAtIndex:1] floatValue]],
                        [self adaptationScreenWidth:[[value objectAtIndex:2] floatValue]],
                        [self adaptationScreenHeight:[[value objectAtIndex:3] floatValue]]);
    }
    return rect;
}

- (CGPoint)pointWithKey:(id)key;
{
    NSArray *value = [key componentsSeparatedByString:@","];
    CGPoint point = CGPointMake(0, 0);
    NSString *stringValue=[value objectAtIndex:0];
    if (stringValue != nil && [stringValue isEqualToString:@""] == NO) {
        point=CGPointMake([[value objectAtIndex:0] floatValue], [[value objectAtIndex:1] floatValue]);
    }
    
    return point;
}

- (CGSize)sizeWithKey:(id)key;
{
    NSArray *value = [key componentsSeparatedByString:@","];
    CGSize size = CGSizeMake(0, 0);
    NSString *stringValue=[value objectAtIndex:0];
    if (stringValue != nil && [stringValue isEqualToString:@""] == NO) {
        size=CGSizeMake([self adaptationScreenWidth:[[value objectAtIndex:0] floatValue]],
                        [self adaptationScreenHeight:[[value objectAtIndex:1] floatValue]]);
    }
    
    return size;
}


-(NSString *)getAttributesString:(id)str{
    
    NSArray *repleaceArr=[[NSArray alloc] initWithObjects:
                          @"{",@"|",@"}",@"=",@"^",@"\"",nil];
    NSArray *value = [str componentsSeparatedByString:@","];
    NSString *attr=nil;
    NSString *stringValue=[value objectAtIndex:0];
    NSArray *reValue = [stringValue componentsSeparatedByString:@"="];
    stringValue=[reValue objectAtIndex:0];
    if (stringValue != nil && [stringValue isEqualToString:@""] == NO) {
        attr=[value objectAtIndex:0];
    }
    for (NSString *rep in repleaceArr) {
        stringValue = [stringValue stringByReplacingOccurrencesOfString:rep withString:@""];
    }
    
    return stringValue;
}

- (UIColor *)colorWithKey:(NSString *)key
{
    NSArray *value = [key componentsSeparatedByString:@","];
    UIColor *color = nil;
    NSString *stringValue=[value objectAtIndex:0];
    if (stringValue != nil && [stringValue isEqualToString:@""] == NO) {
        color=[UIColor colorWithRed:([[value objectAtIndex:0] floatValue]/ 255.0f) green:([[value objectAtIndex:1] floatValue] / 255.0f) blue:([[value objectAtIndex:2] floatValue] / 255.0f) alpha:[[value objectAtIndex:3] floatValue]];
    }
    
    return color;
}

- (UIColor *) colorWithHexString: (id)color
{
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}

-(CGFloat)getScreenWidth:(NSString *)width{
    width=[width stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([width isEqualToString:@"all"]) {
        return ScreenWidth;
    }
    
    return [width floatValue];
}

-(CGFloat)getScreenHeight:(NSString *)height{
    height=[height stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([height isEqualToString:@"all"]) {
        return ScreenHeight;
    }
    
    return [height floatValue];
}

NSString* deviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"VerizoniPhone4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone5";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone5";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone5c";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone5c";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone5s";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone5s";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone6Plus";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone6s";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone6sPlus";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPodTouch1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPodTouch2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPodTouch3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPodTouch4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPodTouch5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad2";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad2";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad2";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad2";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPadMini";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPadMini";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPadMini";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad3";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad3";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad3";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad4";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad4";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad4";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPadAir";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPadAir";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPadAir";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPadMini2G";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPadMini2G";
    if ([platform isEqualToString:@"iPad4,6"])      return @"iPadMini2G";
    if ([platform isEqualToString:@"iPad4,7"])      return @"iPadMini3";
    if ([platform isEqualToString:@"iPad4,8"])      return @"iPadMini3";
    if ([platform isEqualToString:@"iPad4,9"])      return @"iPadMini3";
    if ([platform isEqualToString:@"iPad5,3"])      return @"iPadAir2";
    if ([platform isEqualToString:@"iPad5,4"])      return @"iPadAir2";
    if ([platform isEqualToString:@"AppleTV2,1"])   return @"AppleTV2G";
    if ([platform isEqualToString:@"AppleTV3,1"])   return @"AppleTV3";
    if ([platform isEqualToString:@"AppleTV3,2"])   return @"AppleTV3";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    
    //CLog(@"NOTE: Unknown device type: %@", deviceString);
    
    return platform;
}

-(CGFloat)adaptationScreenWidth:(CGFloat)width{
    return width*IPHONE_6_SCREEN_RADIO;
}

-(CGFloat)adaptationScreenHeight:(CGFloat)height{
    return height*IPHONE_6_SCREEN_RADIO;
}
@end
