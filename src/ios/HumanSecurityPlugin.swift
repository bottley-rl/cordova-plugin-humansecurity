import Foundation
import HUMAN

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

        startHumanSDK()
    }

    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        guard let appId = self.appId else {
            let result = CDVPluginResult(status: .error, messageAs: "AppId not initialized")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        if domainList.isEmpty {
            let result = CDVPluginResult(status: .error, messageAs: "Domain list is empty")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        startHumanSDK()

        let result = CDVPluginResult(status: .ok)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

   func startHumanSDK() {
        guard let appId = self.appId else {
            print("[HumanSecurityPlugin] Cannot start SDK – appId is nil")
            return
        }

        if domainList.isEmpty {
            print("[HumanSecurityPlugin] Cannot start SDK – domain list is empty")
            return
        }

        let policy = HSPolicy()
        policy.hybridAppPolicy.set(webRootDomains: domainList, forAppId: appId)
        policy.hybridAppPolicy.supportExternalWebViews = true
        policy.hybridAppPolicy.automaticSetup = false
        policy.hybridAppPolicy.allowJavaScriptEvaluation = false

        policy.doctorAppPolicy.enabled = true
        policy.automaticInterceptorPolicy.interceptorType = .interceptWithDelayedResponse

        HSAutomaticInterceptorPolicy.urlSessionRequestTimeout = 10

        DispatchQueue.main.async {
            do {
                try HumanSecurity.start(appId: appId, policy: policy)
                print("[HumanSecurityPlugin] Human SDK initialized with appId: \(appId)")

                if let wkWebView = self.findWKWebView(in: self.webView?.superview) {
                    HumanSecurity.setupWebView(webView: wkWebView, navigationDelegate: wkWebView.navigationDelegate)
                    print("[HumanSecurityPlugin] setupWebView called")
                } else {
                    print("[HumanSecurityPlugin] Failed to find WKWebView")
                }
            } catch {
                print("[HumanSecurityPlugin] Failed to Start: \(error.localizedDescription)")
            }
        }
    }

    func findWKWebView(in view: UIView?) -> WKWebView? {
        if let wk = view as? WKWebView {
            return wk
        }
        for subview in view?.subviews ?? [] {
            if let wk = findWKWebView(in: subview) {
                return wk
            }
        }
        return nil
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