// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

@c(psp_partout_version)
public nonisolated func __psp_partout_version() -> UnsafePointer<CChar>! {
    PartoutConstants.cVersionIdentifier
}

@c(psp_log)
public nonisolated func __psp_log(message: UnsafePointer<CChar>?) {
    guard let message else { return }
    pspLog(.abi, .debug, String(cString: message))
}

// MARK: - Helpers

enum ABIError: Error {
    case wrapping(reason: Error? = nil)
}

extension ABI {
    typealias RunCallback = @Sendable (_ code: Int32, _ json: String?) -> Void

    static func run(
        _ block: @escaping @Sendable @BusinessActor () async -> Void
    ) {
        Task { @Sendable @BusinessActor in
            await block()
        }
    }

    static func run(
        _ completion: psp_completion,
        _ block: @escaping @Sendable @BusinessActor (RunCallback?) async -> Void
    ) {
        nonisolated(unsafe) let completion = completion
        Task { @Sendable @BusinessActor in
            let runCallback: RunCallback?
            if let cb = completion.callback {
                runCallback = { code, json in
                    cb(completion.ctx, code, json)
                }
            } else {
                runCallback = nil
            }
            await block(runCallback)
        }
    }

    static func encodeWrapper<T>(_ wrapper: T) throws -> String where T: Encodable {
        let data: Data
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            data = try encoder.encode(wrapper)
        } catch {
            throw ABIError.wrapping(reason: error)
        }
        guard let json = String(data: data, encoding: .utf8) else {
            throw ABIError.wrapping()
        }
        // Dispatch JSON event to cross-platform apps
        return json
    }
}

extension UnsafePointer where Pointee == CChar {
    var asJSONData: Data? {
        String(cString: self).data(using: .utf8)
    }
}

// MARK: - Wrapping

extension ABI {
    struct EventWrapper: Encodable {
        private let payload: Encodable

        init?(_ event: Event) {
            guard let payload = event.payload else { return nil }
            self.payload = payload
        }

        func encode(to encoder: any Encoder) throws {
            try payload.encode(to: encoder)
        }
    }
}

private extension ABI.Event {
    // Return the first (and only) associated value of the enum
    var payload: Encodable? {
        let mirror = Mirror(reflecting: self)
        guard let arg = mirror.children.first else { return nil }
        let children = Mirror(reflecting: arg.value).children
        assert(children.count == 1)
        guard let payload = children.first?.value else { return nil }
        return payload as? Encodable
    }
}

extension ABI.AppPreferenceValues {
    init(with decoder: JSONDecoder, data: Data?, newDeviceId: Bool, deviceIdLength: Int) {
        var values = ABI.AppPreferenceValues()
        if let data {
            do {
                values = try decoder.decode(Self.self, from: data)
            } catch {
                pspLog(.core, .error, "Unable to decode preferences: \(error)")
            }
        } else {
            pspLog(.core, .info, "No preferences provided")
        }
        if newDeviceId && values.deviceId == nil {
            values.deviceId = String.random(count: deviceIdLength)
        }
        self = values
    }
}

#endif
