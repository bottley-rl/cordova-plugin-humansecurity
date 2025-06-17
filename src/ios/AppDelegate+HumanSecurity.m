#import "AppDelegate+HumanSecurity.h"
#import <HUMAN/HUMAN.h>
#import <objc/runtime.h>

@implementation AppDelegate (HumanSecurity)

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:));
    Method swizzled = class_getInstanceMethod(self, @selector(human_application:didFinishLaunchingWithOptions:));
    method_exchangeImplementations(original, swizzled);
}

- (BOOL)human_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    @try {
        HSPolicy *policy = [[HSPolicy alloc] init];
        [policy.hybridAppPolicy setWithWebRootDomains:[NSSet setWithObject:@".rocketlawyer.com"] forAppId:@"PXxTfdm2W9"];
        policy.hybridAppPolicy.automaticSetup = YES;
        policy.hybridAppPolicy.supportExternalWebViews = YES;
        policy.hybridAppPolicy.allowJavaScriptEvaluation = NO;
        policy.automaticInterceptorPolicy.interceptorType = HSInterceptorTypeInterceptWithDelayedResponse;
        policy.doctorAppPolicy.enabled = YES;

        [HumanSecurity startWithAppId:@"PXxTfdm2W9" policy:policy error:nil];
        NSLog(@"[HumanSecurityPlugin] SDK started from AppDelegate+HumanSecurity");
    }
    @catch (NSException *exception) {
        NSLog(@"[HumanSecurityPlugin] SDK failed to start: %@", exception.reason);
    }

    // Call the original (swizzled) method
    return [self human_application:application didFinishLaunchingWithOptions:launchOptions];
}
@end
