import Foundation
import HUMAN
import WebKit

@objc(HumanSecurityPlugin)
class HumanSecurityPlugin: CDVPlugin {

    var appId: String?
    var domainList: Set<String> = []

    override func pluginInitialize() {
        guard
            let appId = self.commandDelegate?.settings["human_app_id"] as? String,
            let domainString = self.commandDelegate?.settings["human_domains"] as? String
        else {
            print("[HumanSecurityPlugin] Missing plugin preferences: human_app_id and/or human_domains")
            return
        }

        self.appId = appId
        self.domainList = Set(domainString.components(separatedBy: ","))

        // let policy = HSPolicy()
        // policy.hybridAppPolicy.set(webRootDomains: domainList, forAppId: appId)
        // policy.hybridAppPolicy.supportExternalWebViews = true
        // policy.hybridAppPolicy.automaticSetup = false
        // policy.automaticInterceptorPolicy.interceptorType = .none
        // policy.doctorAppPolicy.enabled = false // Enable to verify SDK

        // HSAutomaticInterceptorPolicy.urlSessionRequestTimeout = 3

        // DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        //     do {
        //         try HumanSecurity.start(appId: appId, policy: policy)
        //         print("[HumanSecurityPlugin] Human SDK initialized with appId: \(appId)")
        //     } catch {
        //         print("[HumanSecurityPlugin] SDK start failed: \(error.localizedDescription)")
        //     }
        // }
    }

    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        guard let appId = self.appId, let domainList = self.domainList else {
            let result = CDVPluginResult(status: .error, messageAs: "AppId or domainList not initialized")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        let policy = HSPolicy()
        policy.hybridAppPolicy.set(webRootDomains: domainList, forAppId: appId)
        policy.hybridAppPolicy.supportExternalWebViews = true
        policy.hybridAppPolicy.automaticSetup = true
        policy.automaticInterceptorPolicy.interceptorType = .interceptWithDelayedResponse

        HSAutomaticInterceptorPolicy.urlSessionRequestTimeout = 3

        DispatchQueue.main.async {
            do {
                try HumanSecurity.start(appId: appId, policy: policy)
                let result = CDVPluginResult(status: .ok)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc(getHeaders:)
    func getHeaders(command: CDVInvokedUrlCommand) {
        guard let appId = self.appId else {
            let result = CDVPluginResult(status: .error, messageAs: "AppId not initialized")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        let headers = HumanSecurity.BD.headersForURLRequest(forAppId: appId)
        let result = CDVPluginResult(status: .ok, messageAs: headers)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(handleResponse:)
    func handleResponse(command: CDVInvokedUrlCommand) {
        guard
            let responseString = command.argument(at: 0) as? String,
            let data = responseString.data(using: .utf8)
        else {
            let result = CDVPluginResult(status: .error, messageAs: "Invalid input")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        let placeholderUrl = URL(string: "https://placeholder.com")!
        let httpResponse = HTTPURLResponse(url: placeholderUrl, statusCode: 403, httpVersion: nil, headerFields: [:])!

        let wasHandled = HumanSecurity.BD.handleResponse(response: httpResponse, data: data) { challengeResult in
            print("[HumanSecurityPlugin] Challenge result: \(challengeResult)")
        }

        let result = CDVPluginResult(status: .ok, messageAs: wasHandled)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(setUserId:)
    func setUserId(command: CDVInvokedUrlCommand) {
        guard
            let userId = command.argument(at: 0) as? String,
            let appId = self.appId
        else {
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