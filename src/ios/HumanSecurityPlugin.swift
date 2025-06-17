import Foundation
import HUMAN

@objc(HumanSecurityPlugin)
class HumanSecurityPlugin: CDVPlugin {

    @objc(getHeaders:)
    func getHeaders(command: CDVInvokedUrlCommand) {
        guard
            let appId = self.commandDelegate?.settings["human_app_id"] as? String
        else {
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
            let appId = self.commandDelegate?.settings["human_app_id"] as? String
        else {
            print("[HumanSecurityPlugin] setUserId missing human_app_id")
            return
        }

        guard
            let userId = command.argument(at: 0) as? String
        else {
            let result = CDVPluginResult(status: .error, messageAs: "Missing userId")
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