// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
import Partout

public final class DefaultProviderScriptingAPI {
    private let ctx: PartoutLoggerContext

    private let timeout: TimeInterval

    private let requestHijacker: (@Sendable (String, String) -> (Int, Data))?

    public convenience init(
        _ ctx: PartoutLoggerContext,
        timeout: TimeInterval
    ) {
        self.init(ctx, timeout: timeout, requestHijacker: nil)
    }

    init(
        _ ctx: PartoutLoggerContext,
        timeout: TimeInterval,
        requestHijacker: (@Sendable (_ method: String, _ urlString: String) -> (httpStatus: Int, responseData: Data))? = nil
    ) {
        self.ctx = ctx
        self.timeout = timeout
        self.requestHijacker = requestHijacker
    }
}

extension DefaultProviderScriptingAPI: ProviderScriptingAPI {
    public var version: String {
        "20250718"
    }

    public func getResult(
        method: String,
        urlString: String,
        headers: [String: String]?,
        body: String?
    ) -> [String: Any] {
        let textResult = {
            let result = sendRequest(method: method, urlString: urlString, headers: headers, body: body)
            if result.isCached {
                return result
            }
            guard let text = result.response as? Data else {
                pp_log(ctx, .providers, .error, "API.getResult: Response is not Data")
                return ProviderScriptResult.notData
            }
            guard let string = String(data: text, encoding: .utf8) else {
                pp_log(ctx, .providers, .error, "API.getResult: Response is not String")
                return ProviderScriptResult.notString
            }
            return result.with(response: string)
        }()
        return textResult.serialized()
    }

    public func getText(urlString: String, headers: [String: String]?) -> [String: Any] {
        getResult(method: "GET", urlString: urlString, headers: headers, body: nil)
    }

    public func getJSON(urlString: String, headers: [String: String]?) -> [String: Any] {
        let jsonResult = {
            let result = sendRequest(method: "GET", urlString: urlString, headers: headers, body: nil)
            if result.isCached {
                return result
            }
            guard let text = result.response as? Data else {
                pp_log(ctx, .providers, .error, "API.getJSON: Response is not Data")
                return ProviderScriptResult.notData
            }
            do {
                let object = try JSONSerialization.jsonObject(with: text)
                return result.with(response: object)
            } catch {
                pp_log(ctx, .providers, .error, "API.getJSON: Unable to parse JSON: \(error)")
                return ProviderScriptResult(error.localizedDescription)
            }
        }()
        return jsonResult.serialized()
    }

    public func jsonFromBase64(string: String) -> Any? {
        do {
            guard let data = Data(base64Encoded: string) else {
                return nil
            }
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            pp_log(ctx, .providers, .error, "API.jsonFromBase64: Unable to serialize: \(error)")
            return nil
        }
    }

    public func jsonToBase64(object: Any) -> String? {
        do {
            return try JSONSerialization.data(withJSONObject: object)
                .base64EncodedString()
        } catch {
            pp_log(ctx, .providers, .error, "API.jsonToBase64: Unable to serialize: \(error)")
            return nil
        }
    }

    public func timestampFromISO(isoString: String) -> Int {
        Int(ISO8601DateFormatter().date(from: isoString)?.timeIntervalSinceReferenceDate ?? 0)
    }

    public func timestampToISO(timestamp: Int) -> String {
        ISO8601DateFormatter().string(from: Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp)))
    }

    public func ipV4ToBase64(ip: String) -> String? {
        let bytes = ip
            .split(separator: ".")
            .compactMap {
                UInt8($0)
            }
        guard bytes.count == 4 else {
            pp_log(ctx, .providers, .error, "API.ipV4ToBase64: Not a IPv4 string")
            return nil
        }
        return Data(bytes)
            .base64EncodedString()
    }

    public func openVPNTLSWrap(strategy: String, file: String) -> [String: Any]? {
        let hex = file
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n")
            .joined()
        let key = Data(hex: hex)
        guard key.count == 256 else {
            pp_log(ctx, .providers, .error, "API.openVPNTLSWrap: Static key must be 64 bytes long")
            return nil
        }
        return [
            "strategy": strategy,
            "key": [
                "dir": 1,
                "data": key.base64EncodedString()
            ]
        ]
    }

    public func errorResponse(message: String) -> [String: Any] {
        ["error": message]
    }

    public func debug(message: String) {
        pp_log(ctx, .providers, .debug, message)
    }
}

// MARK: -

private extension DefaultProviderScriptingAPI {
    final class ResultStorage: @unchecked Sendable {
        var textData: Data?

        var lastModified: Timestamp?

        var tag: String?

        var isCached = false
    }

    func sendRequest(
        method: String,
        urlString: String,
        headers: [String: String]?,
        body: String?
    ) -> ProviderScriptResult {
        pp_log(ctx, .providers, .info, "API.sendRequest: \(method) \(urlString)")

        // hijack requests (for testing)
        if let requestHijacker {
            let pair = requestHijacker(method, urlString)
            let fakeResponseStatus = pair.0
            let fakeResponseData = pair.1

            pp_log(ctx, .providers, .info, "API.sendRequest: Success (mapped)")
            return ProviderScriptResult(
                fakeResponseData,
                status: fakeResponseStatus,
                lastModified: nil,
                tag: nil
            )
        }

        guard let url = URL(string: urlString) else {
            return ProviderScriptResult.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        if let body {
            request.httpBody = Data(base64Encoded: body)
        }
        if let headers = request.allHTTPHeaderFields {
            let redactedHeaders = headers.map {
                if $0.key.lowercased() == "authorization" {
                    return ($0.key, "<redacted>")
                } else {
                    return ($0.key, $0.value)
                }
            }
            pp_log(ctx, .providers, .info, "API.sendRequest: Headers: \(redactedHeaders)")
        }

        // use external caching (e.g. Core Data)
        let cfg: URLSessionConfiguration = .ephemeral
        cfg.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: cfg)

        final class StatusHolder: @unchecked Sendable {
            var status: Int?
        }

        let semaphore = DispatchSemaphore(value: 0)
        let storage = ResultStorage()
        let statusHolder = StatusHolder()
        let ctx = self.ctx // to avoid capturing self
        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                pp_log(ctx, .providers, .error, "API.sendRequest: Unable to execute: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                let lastModifiedHeader = httpResponse.value(forHTTPHeaderField: "last-modified")
                let tag = httpResponse.value(forHTTPHeaderField: "etag")

                pp_log(ctx, .providers, .debug, "API.sendRequest: Response: \(httpResponse)")
                pp_log(ctx, .providers, .info, "API.sendRequest: HTTP \(httpResponse.statusCode)")
                if let lastModifiedHeader {
                    pp_log(ctx, .providers, .info, "API.sendRequest: Last-Modified: \(lastModifiedHeader)")
                    storage.lastModified = lastModifiedHeader.fromRFC1123()
                }
                if let tag {
                    pp_log(ctx, .providers, .info, "API.sendRequest: ETag: \(tag)")
                    storage.tag = tag
                }
                statusHolder.status = httpResponse.statusCode
                storage.isCached = httpResponse.statusCode == 304
            }
            storage.textData = data
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        if storage.isCached {
            pp_log(ctx, .providers, .info, "API.sendRequest: Success (cached)")

            // nil response but no error = result.isCached
            return ProviderScriptResult(
                nil,
                status: statusHolder.status,
                lastModified: storage.lastModified,
                tag: storage.tag
            )
        }
        guard let textData = storage.textData else {
            pp_log(ctx, .providers, .error, "API.sendRequest: Empty response")
            return ProviderScriptResult.notData
        }
        pp_log(ctx, .providers, .info, "API.sendRequest: Success")
        return ProviderScriptResult(
            textData,
            status: statusHolder.status,
            lastModified: storage.lastModified,
            tag: storage.tag
        )
    }
}

// MARK: -

struct ProviderScriptResult {
    private(set) var response: Any?

    let error: String?

    // extra

    let status: Int?

    let lastModified: Timestamp?

    let tag: String?

    var isCached: Bool {
        response == nil && error == nil
    }

    init(_ response: Any?, status: Int?, lastModified: Timestamp?, tag: String?) {
        self.response = response
        error = nil

        self.status = status
        self.lastModified = lastModified
        self.tag = tag
    }

    init(_ error: String) {
        response = nil
        self.error = error

        status = nil
        lastModified = nil
        tag = nil
    }

    func with(response: Any) -> Self {
        var copy = self
        copy.response = response
        return copy
    }

    func serialized() -> [String: Any] {
        var map: [String: Any] = [:]
        if let response {
            map["response"] = response
            if let status {
                map["status"] = status
            }

            // follow ProviderCache
            var cache: [String: Any] = [:]
            cache["lastUpdate"] = lastModified ?? Timestamp.now()
            if let tag {
                cache["tag"] = tag
            }
            map["cache"] = cache

            map["isCached"] = isCached
        }
        if let error {
            map["error"] = error
        }
        return map
    }
}

extension ProviderScriptResult: @unchecked Sendable {
    private static let apiPrefix = "API"

    static let invalidURL = Self("\(apiPrefix).invalidURL")

    static let notData = Self("\(apiPrefix).notData")

    static let notString = Self("\(apiPrefix).notString")

    var isAPIError: Bool {
        error?.hasPrefix(Self.apiPrefix) == true
    }
}
#endif
