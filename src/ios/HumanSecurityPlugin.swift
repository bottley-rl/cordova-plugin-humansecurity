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

            if let wkWebView = findWKWebView(in: self.webView?.superview) {
                HumanSecurity.setupWebView(
                    webView: wkWebView, navigationDelegate: wkWebView.navigationDelegate)
                print("Human SDK Manually called setupWebView")
            }
        } catch {
            print("Human SDK failed to initialize: \(error.localizedDescription)")
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
        guard let appId = command.argument(at: 0) as? String else {
            let result = CDVPluginResult(status: .error, messageAs: "Missing appId")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        let headers = HumanSecurity.BD.headersForURLRequest(forAppId: appId)
        let result = CDVPluginResult(status: .ok, messageAs: headers)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(handleResponse:)
    func handleResponse(command: CDVInvokedUrlCommand) {
        guard let responseString = command.argument(at: 0) as? String,
            let data = responseString.data(using: .utf8),
            let httpResponse = HTTPURLResponse(
                url: URL(string: "https://www.google.com")!,  // Not used - just a placeholder
                statusCode: 403,
                httpVersion: nil,
                headerFields: [:]
            )
        else {
            let result = CDVPluginResult(status: .error, messageAs: "Invalid input")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        let wasHandled = HumanSecurity.BD.handleResponse(response: httpResponse, data: data) {
            result in
            print("[HumanSecurity] Challenge result: \(result)")
        }

        let result = CDVPluginResult(status: .ok, messageAs: wasHandled)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(setUserId:)
    func setUserId(command: CDVInvokedUrlCommand) {
        guard let userId = command.argument(at: 0) as? String,
            let appId = command.argument(at: 1) as? String
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
