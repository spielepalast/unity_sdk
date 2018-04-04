//
//  AdjustUnityDelegate.mm
//  Adjust SDK
//
//  Created by Uglješa Erceg (@uerceg) on 5th December 2016.
//  Copyright © 2012-2018 Adjust GmbH. All rights reserved.
//

#import <objc/runtime.h>
#import "AdjustUnityDelegate.h"

static dispatch_once_t onceToken;
static AdjustUnityDelegate *defaultInstance = nil;

@implementation AdjustUnityDelegate

#pragma mark - Object lifecycle methods

- (id)init {
    self = [super init];

    if (nil == self) {
        return nil;
    }

    return self;
}

#pragma mark - Public methods

+ (id)getInstanceWithSwizzleOfAttributionCallback:(BOOL)swizzleAttributionCallback
                             eventSuccessCallback:(BOOL)swizzleEventSuccessCallback
                             eventFailureCallback:(BOOL)swizzleEventFailureCallback
                           sessionSuccessCallback:(BOOL)swizzleSessionSuccessCallback
                           sessionFailureCallback:(BOOL)swizzleSessionFailureCallback
                         deferredDeeplinkCallback:(BOOL)swizzleDeferredDeeplinkCallback
                     shouldLaunchDeferredDeeplink:(BOOL)shouldLaunchDeferredDeeplink
                         withAdjustUnitySceneName:(NSString *)adjustUnitySceneName {
    dispatch_once(&onceToken, ^{
        defaultInstance = [[AdjustUnityDelegate alloc] init];

        // Do the swizzling where and if needed.
        if (swizzleAttributionCallback) {
            [defaultInstance swizzleCallbackMethod:@selector(adjustAttributionChanged:)
                                        withMethod:@selector(adjustAttributionChangedWannabe:)];
        }

        if (swizzleEventSuccessCallback) {
            [defaultInstance swizzleCallbackMethod:@selector(adjustEventTrackingSucceeded:)
                                        withMethod:@selector(adjustEventTrackingSucceededWannabe:)];
        }

        if (swizzleEventFailureCallback) {
            [defaultInstance swizzleCallbackMethod:@selector(adjustEventTrackingFailed:)
                                        withMethod:@selector(adjustEventTrackingFailedWannabe:)];
        }

        if (swizzleSessionSuccessCallback) {
            [defaultInstance swizzleCallbackMethod:@selector(adjustSessionTrackingSucceeded:)
                                        withMethod:@selector(adjustSessionTrackingSucceededWannabe:)];
        }

        if (swizzleSessionFailureCallback) {
            [defaultInstance swizzleCallbackMethod:@selector(adjustSessionTrackingFailed:)
                                        withMethod:@selector(adjustSessionTrackingFailedWannabe:)];
        }

        if (swizzleDeferredDeeplinkCallback) {
            [defaultInstance swizzleCallbackMethod:@selector(adjustDeeplinkResponse:)
                                        withMethod:@selector(adjustDeeplinkResponseWannabe:)];
        }

        [defaultInstance setShouldLaunchDeferredDeeplink:shouldLaunchDeferredDeeplink];
        [defaultInstance setAdjustUnitySceneName:adjustUnitySceneName];
    });
    
    return defaultInstance;
}

+ (void)teardown {
    defaultInstance = nil;
    onceToken = 0;
}

#pragma mark - Private & helper methods

- (void)adjustAttributionChangedWannabe:(ADJAttribution *)attribution {
    if (attribution == nil) {
        return;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self addValueOrEmpty:attribution.trackerToken forKey:@"trackerToken" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.trackerName forKey:@"trackerName" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.network forKey:@"network" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.campaign forKey:@"campaign" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.creative forKey:@"creative" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.adgroup forKey:@"adgroup" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.clickLabel forKey:@"clickLabel" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.adid forKey:@"adid" toDictionary:dictionary];

    NSData *dataAttribution = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *stringAttribution = [[NSString alloc] initWithBytes:[dataAttribution bytes]
                                                           length:[dataAttribution length]
                                                         encoding:NSUTF8StringEncoding];
    const char* charArrayAttribution = [stringAttribution UTF8String];
    UnitySendMessage([self.adjustUnitySceneName UTF8String], "GetNativeAttribution", charArrayAttribution);
}

- (void)adjustEventTrackingSucceededWannabe:(ADJEventSuccess *)eventSuccessResponseData {
    if (nil == eventSuccessResponseData) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self addValueOrEmpty:eventSuccessResponseData.message forKey:@"message" toDictionary:dictionary];
    [self addValueOrEmpty:eventSuccessResponseData.timeStamp forKey:@"timestamp" toDictionary:dictionary];
    [self addValueOrEmpty:eventSuccessResponseData.adid forKey:@"adid" toDictionary:dictionary];
    [self addValueOrEmpty:eventSuccessResponseData.eventToken forKey:@"eventToken" toDictionary:dictionary];
    [self addValueOrEmpty:eventSuccessResponseData.jsonResponse forKey:@"jsonResponse" toDictionary:dictionary];

    NSData *dataEventSuccess = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *stringEventSuccess = [[NSString alloc] initWithBytes:[dataEventSuccess bytes]
                                                            length:[dataEventSuccess length]
                                                          encoding:NSUTF8StringEncoding];
    const char* charArrayEventSuccess = [stringEventSuccess UTF8String];
    UnitySendMessage([self.adjustUnitySceneName UTF8String], "GetNativeEventSuccess", charArrayEventSuccess);
}

- (void)adjustEventTrackingFailedWannabe:(ADJEventFailure *)eventFailureResponseData {
    if (nil == eventFailureResponseData) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self addValueOrEmpty:eventFailureResponseData.message forKey:@"message" toDictionary:dictionary];
    [self addValueOrEmpty:eventFailureResponseData.timeStamp forKey:@"timestamp" toDictionary:dictionary];
    [self addValueOrEmpty:eventFailureResponseData.adid forKey:@"adid" toDictionary:dictionary];
    [self addValueOrEmpty:eventFailureResponseData.eventToken forKey:@"eventToken" toDictionary:dictionary];
    [self addValueOrEmpty:eventFailureResponseData.jsonResponse forKey:@"jsonResponse" toDictionary:dictionary];
    [dictionary setObject:(eventFailureResponseData.willRetry ? @"true" : @"false") forKey:@"willRetry"];

    NSData *dataEventFailure = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *stringEventFailure = [[NSString alloc] initWithBytes:[dataEventFailure bytes]
                                                            length:[dataEventFailure length]
                                                          encoding:NSUTF8StringEncoding];
    const char* charArrayEventFailure = [stringEventFailure UTF8String];
    UnitySendMessage([self.adjustUnitySceneName UTF8String], "GetNativeEventFailure", charArrayEventFailure);
}

- (void)adjustSessionTrackingSucceededWannabe:(ADJSessionSuccess *)sessionSuccessResponseData {
    if (nil == sessionSuccessResponseData) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self addValueOrEmpty:sessionSuccessResponseData.message forKey:@"message" toDictionary:dictionary];
    [self addValueOrEmpty:sessionSuccessResponseData.timeStamp forKey:@"timestamp" toDictionary:dictionary];
    [self addValueOrEmpty:sessionSuccessResponseData.adid forKey:@"adid" toDictionary:dictionary];
    [self addValueOrEmpty:sessionSuccessResponseData.jsonResponse forKey:@"jsonResponse" toDictionary:dictionary];

    NSData *dataSessionSuccess = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *stringSessionSuccess = [[NSString alloc] initWithBytes:[dataSessionSuccess bytes]
                                                              length:[dataSessionSuccess length]
                                                            encoding:NSUTF8StringEncoding];
    const char* charArraySessionSuccess = [stringSessionSuccess UTF8String];
    UnitySendMessage([self.adjustUnitySceneName UTF8String], "GetNativeSessionSuccess", charArraySessionSuccess);
}

- (void)adjustSessionTrackingFailedWannabe:(ADJSessionFailure *)sessionFailureResponseData {
    if (nil == sessionFailureResponseData) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self addValueOrEmpty:sessionFailureResponseData.message forKey:@"message" toDictionary:dictionary];
    [self addValueOrEmpty:sessionFailureResponseData.timeStamp forKey:@"timestamp" toDictionary:dictionary];
    [self addValueOrEmpty:sessionFailureResponseData.adid forKey:@"adid" toDictionary:dictionary];
    [self addValueOrEmpty:sessionFailureResponseData.jsonResponse forKey:@"jsonResponse" toDictionary:dictionary];
    [dictionary setObject:(sessionFailureResponseData.willRetry ? @"true" : @"false") forKey:@"willRetry"];

    NSData *dataSessionFailure = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *stringSessionFailure = [[NSString alloc] initWithBytes:[dataSessionFailure bytes]
                                                              length:[dataSessionFailure length]
                                                            encoding:NSUTF8StringEncoding];
    const char* charArraySessionFailure = [stringSessionFailure UTF8String];
    UnitySendMessage([self.adjustUnitySceneName UTF8String], "GetNativeSessionFailure", charArraySessionFailure);
}

- (BOOL)adjustDeeplinkResponseWannabe:(NSURL *)deeplink {
    NSString *stringDeeplink = [deeplink absoluteString];
    const char* charDeeplink = [stringDeeplink UTF8String];
    UnitySendMessage([self.adjustUnitySceneName UTF8String], "GetNativeDeferredDeeplink", charDeeplink);
    return _shouldLaunchDeferredDeeplink;
}

- (void)swizzleCallbackMethod:(SEL)originalSelector
                   withMethod:(SEL)swizzledSelector {
    Class className = [self class];
    Method originalMethod = class_getInstanceMethod(className, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(className, swizzledSelector);

    BOOL didAddMethod = class_addMethod(className,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(className,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)addValueOrEmpty:(NSObject *)value
                 forKey:(NSString *)key
           toDictionary:(NSMutableDictionary *)dictionary {
    if (nil != value) {
        [dictionary setObject:[NSString stringWithFormat:@"%@", value] forKey:key];
    } else {
        [dictionary setObject:@"" forKey:key];
    }
}

@end
