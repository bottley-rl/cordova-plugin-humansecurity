import Foundation
import HUMAN
import WebKit

@objc(HumanSecurityPlugin) class HumanSecurityPlugin: CDVPlugin {

    override func pluginInitialize() {
        let appId: String = "xTfdm2W9"
        let domains: Set<String> = Set([".rocketlawyer.com"])

        let policy = HSPolicy()
        policy.hybridAppPolicy.set(webRootDomains: domains, forAppId: appId)
        policy.hybridAppPolicy.supportExternalWebViews = true
        policy.hybridAppPolicy.automaticSetup = true
        policy.automaticInterceptorPolicy.interceptorType = .interceptWithDelayedResponse

        do {
            try HumanSecurity.start(appId: appId, policy: policy)
            print("Human SDK initialized early via pluginInitialize")
        } catch {
            print("Human SDK failed to initialize: \(error.localizedDescription)")
        }
    }

    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        guard let appId = command.argument(at: 0) as? String,
              let domainArray = command.argument(at: 1) as? [String] else {
            let result = CDVPluginResult(status: .error, messageAs: "Missing appId or domains")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        let domains = Set(domainArray)

        DispatchQueue.main.async {
            let policy = HSPolicy()

            policy.hybridAppPolicy.set(webRootDomains: domains, forAppId: appId)
            policy.hybridAppPolicy.supportExternalWebViews = true
            policy.hybridAppPolicy.automaticSetup = true

            policy.automaticInterceptorPolicy.interceptorType = .interceptWithDelayedResponse

            do {
                try HumanSecurity.start(appId: appId, policy: policy)
                print("[HumanSecurityPlugin] SDK started with appId: \(appId) and domains: \(domains)")
                let result = CDVPluginResult(status: .ok)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                print("[HumanSecurityPlugin] SDK start failed: \(error.localizedDescription)")
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc(setUserId:)
    func setUserId(command: CDVInvokedUrlCommand) {
        guard let userId = command.argument(at: 0) as? String,
              let appId = command.argument(at: 1) as? String else {
            let result = CDVPluginResult(status: .error, messageAs: "Missing userId or appId")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        do {
            try HumanSecurity.AD.setUserId(userId: userId, forAppId: appId)
            print("[HumanSecurityPlugin] Set user ID: \(userId) for appId: \(appId)")
            let result = CDVPluginResult(status: .ok)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        } catch {
            print("[HumanSecurityPlugin] setUserId failed: \(error.localizedDescription)")
            let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }
}
