// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol ProviderScriptingAPI: Sendable {
    var version: String { get }

    func getResult(
        method: String,
        urlString: String,
        headers: [String: String]?,
        body: String?
    ) -> [String: Any]

    func getText(urlString: String, headers: [String: String]?) -> [String: Any]

    func getJSON(urlString: String, headers: [String: String]?) -> [String: Any]

    func jsonFromBase64(string: String) -> Any?

    func jsonToBase64(object: Any) -> String?

    func timestampFromISO(isoString: String) -> Int

    func timestampToISO(timestamp: Int) -> String

    func ipV4ToBase64(ip: String) -> String?

    func openVPNTLSWrap(strategy: String, file: String) -> [String: Any]?

    func errorResponse(message: String) -> [String: Any]

    func debug(message: String)
}

extension ProviderScriptingAPI {
    public func httpErrorResponse(status: Int, urlString: String) -> [String: Any] {
        errorResponse(message: "HTTP \(status) \(urlString)")
    }
}
