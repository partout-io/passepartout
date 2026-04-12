// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
#if PSP_ABI
import CommonLibrary_C

@c(psp_partout_version)
public nonisolated func __psp_partout_version() -> UnsafePointer<CChar>! {
    PartoutConstants.cVersionIdentifier
}
#endif

// MARK: - Helpers

extension ABI {
    static func run(
        _ block: @escaping @Sendable @BusinessActor () async -> Void
    ) {
        Task { @Sendable @BusinessActor in
            await block()
        }
    }

    static func run(
        _ ctx: UnsafeMutableRawPointer?,
        _ block: @escaping @Sendable @BusinessActor (UnsafeMutableRawPointer?) async -> Void
    ) {
        nonisolated(unsafe) let unsafeCtx = ctx
        Task { @Sendable @BusinessActor in
            await block(unsafeCtx)
        }
    }
}

extension UnsafePointer where Pointee == CChar {
    var asJSONData: Data? {
        String(cString: self).data(using: .utf8)
    }
}

// MARK: - Event wrapping

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
    init(with decoder: JSONDecoder, data: Data?, newDeviceId: Bool) {
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
            // FIXME: #1656, C ABI, app device ID
            values.deviceId = ""
        }
        self = values
    }
}
