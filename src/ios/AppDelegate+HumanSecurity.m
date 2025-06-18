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
        
        NSString *appId = [[NSUserDefaults standardUserDefaults] stringForKey:@"human_app_id"];
        NSString *domainsString = [[NSUserDefaults standardUserDefaults] stringForKey:@"human_domains"];

        if (!appId || !domainsString) {
            NSLog(@"[HumanSecurityPlugin] AppId or domains missing in UserDefaults — fallback values will be used");
            appId = @"PXxTfdm2W9";
            domainsString = @".rocketlawyer.com";
        }

        NSSet *domains = [NSSet setWithArray:[domainsString componentsSeparatedByString:@","]];

        HSPolicy *policy = [[HSPolicy alloc] init];
        [policy.hybridAppPolicy setWithWebRootDomains:domains forAppId:appId];
        policy.hybridAppPolicy.automaticSetup = YES;
        policy.hybridAppPolicy.supportExternalWebViews = YES;
        policy.hybridAppPolicy.allowJavaScriptEvaluation = NO;

        policy.automaticInterceptorPolicy.interceptorType = HSAutomaticInterceptorTypeInterceptWithDelayedResponse;
        HSAutomaticInterceptorPolicy.urlSessionRequestTimeout = 3;

        policy.doctorAppPolicy.enabled = YES;

        NSError *error = nil;
        [HumanSecurity startWithAppId:appId policy:policy error:&error];

        if (error) {
            NSLog(@"[HumanSecurityPlugin] SDK failed to start: %@", error.localizedDescription);
        } else {
            NSLog(@"[HumanSecurityPlugin] SDK started with appId: %@", appId);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"[HumanSecurityPlugin] Exception during SDK init: %@", exception.reason);
    }

    return [self human_application:application didFinishLaunchingWithOptions:launchOptions];
}

@end