// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(JavaScriptCore)
import JavaScriptCore
import Partout

extension AppleJavaScriptEngine: ProviderScriptingEngine {
    @objc
    protocol ObjCProviderAPIProtocol: JSExport {
        func getResult(_ method: JSValue, _ url: JSValue, _ headers: JSValue, _ body: JSValue) -> Any?
        func getText(_ urlString: String, _ headers: [String: String]?) -> [String: Any]
        func getJSON(_ urlString: String, _ headers: [String: String]?) -> [String: Any]
        func jsonFromBase64(_ string: String) -> Any?
        func jsonToBase64(_ object: Any) -> String?
        func timestampFromISO(_ isoString: String) -> Int
        func timestampToISO(_ timestamp: Int) -> String
        func ipV4ToBase64(_ ip: String) -> String?
        func openVPNTLSWrap(_ strategy: String, _ file: String) -> [String: Any]?
        func errorResponse(_ message: String) -> [String: Any]
        func httpErrorResponse(_ status: Int, _ urlString: String) -> [String: Any]
        func debug(_ message: String)
        func version() -> String
    }

    //
    // implementing JSExport alone IS NOT ENOUGH for this to work as a JS object:
    //
    // - the class MUST implement a protocol that implements JSExport
    // - the methods must follow the block convention, i.e. args MUST be unnamed ("_")
    //
    final class ObjCProviderAPI: NSObject, ObjCProviderAPIProtocol {
        private let vm: ProviderScriptingAPI

        init(vm: ProviderScriptingAPI) {
            self.vm = vm
        }

        func getResult(_ method: JSValue, _ url: JSValue, _ headers: JSValue, _ body: JSValue) -> Any? {
            guard let method = method.toString() else {
                assertionFailure("Missing method")
                return nil
            }
            guard let urlString = url.toString() else {
                assertionFailure("Missing URL")
                return nil
            }
            let headers = !headers.isUndefined ? (headers.toObject() as? [String: String]) : nil
            let body = !body.isUndefined ? body.toString() : nil
            return vm.getResult(method: method, urlString: urlString, headers: headers, body: body)
        }

        func getText(_ urlString: String, _ headers: [String: String]?) -> [String: Any] {
            vm.getText(urlString: urlString, headers: headers)
        }

        func getJSON(_ urlString: String, _ headers: [String: String]?) -> [String: Any] {
            vm.getJSON(urlString: urlString, headers: headers)
        }

        func jsonFromBase64(_ string: String) -> Any? {
            vm.jsonFromBase64(string: string)
        }

        func jsonToBase64(_ object: Any) -> String? {
            vm.jsonToBase64(object: object)
        }

        func timestampFromISO(_ isoString: String) -> Int {
            vm.timestampFromISO(isoString: isoString)
        }

        func timestampToISO(_ timestamp: Int) -> String {
            vm.timestampToISO(timestamp: timestamp)
        }

        func ipV4ToBase64(_ ip: String) -> String? {
            vm.ipV4ToBase64(ip: ip)
        }

        func openVPNTLSWrap(_ strategy: String, _ file: String) -> [String: Any]? {
            vm.openVPNTLSWrap(strategy: strategy, file: file)
        }

        func errorResponse(_ message: String) -> [String: Any] {
            vm.errorResponse(message: message)
        }

        func httpErrorResponse(_ status: Int, _ urlString: String) -> [String: Any] {
            vm.httpErrorResponse(status: status, urlString: urlString)
        }

        func debug(_ message: String) {
            vm.debug(message: message)
        }

        func version() -> String {
            vm.version
        }
    }

    public func inject(from vm: ProviderScriptingAPI) {
        let api = ObjCProviderAPI(vm: vm)
        inject("api", object: api)
    }
}
#endif
