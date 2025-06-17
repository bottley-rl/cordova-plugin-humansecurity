#import "AppDelegate+HumanSecurity.h"
#import <HUMAN/HUMAN.h>
#import <objc/runtime.h>
#import <Cordova/CDVViewController.h>

@implementation AppDelegate (HumanSecurity)

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:));
    Method swizzled = class_getInstanceMethod(self, @selector(human_application:didFinishLaunchingWithOptions:));
    method_exchangeImplementations(original, swizzled);
}

- (BOOL)human_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    @try {
        UIViewController *rootVC = self.window.rootViewController;
        if (![rootVC isKindOfClass:[CDVViewController class]]) {
            NSLog(@"[HumanSecurityPlugin] Root VC is not CDVViewController. Cannot read plugin preferences.");
            return [self human_application:application didFinishLaunchingWithOptions:launchOptions];
        }

        CDVViewController *cdvVC = (CDVViewController *)rootVC;
        NSDictionary *settings = cdvVC.settings;

        NSString *appId = settings[@"human_app_id"];
        NSString *domainsString = settings[@"human_domains"];

        if (!appId || !domainsString) {
            NSLog(@"[HumanSecurityPlugin] Missing preferences: human_app_id and/or human_domains");
            return [self human_application:application didFinishLaunchingWithOptions:launchOptions];
        }

        NSSet *domainSet = [NSSet setWithArray:[domainsString componentsSeparatedByString:@","]];

        HSPolicy *policy = [[HSPolicy alloc] init];
        [policy.hybridAppPolicy setWithWebRootDomains:domainSet forAppId:appId];
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