// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
#if PSP_ABI
import CommonLibrary_C

@_cdecl("psp_partout_version")
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
        enum CodingKeys: CodingKey {
            case type
            case payload
        }

        private let type: String
        private let payload: Encodable?

        init(_ event: Event) {
            let subEvent = event.subEvent
            let subtype = subEvent?.name ?? ""
            type = "\(event.type).\(subtype)"
            payload = subEvent?.payload
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            if let payload {
                try container.encode(payload, forKey: .payload)
            }
        }
    }
}

private extension ABI.Event {
    var type: String {
        switch self {
        case .config: "config"
        case .iap: "iap"
        case .profile: "profile"
        case .tunnel: "tunnel"
        case .version: "version"
        case .webReceiver: "webReceiver"
        }
    }
}

private struct SubEvent {
    let name: String
    let payload: Encodable?
}

private extension ABI.Event {
    var subEvent: SubEvent? {
//        print(">>> event: \(self)")
        let mirror = Mirror(reflecting: self)
        guard let arg = mirror.children.first else { return nil }
//        print(">>> subevent: \(arg.label), \(arg.value)")
        guard let payload = Mirror(reflecting: arg.value).children.first,
              let name = payload.label else {
            return nil
        }
//        print(">>> payload: \(payload)")
        return SubEvent(name: name, payload: payload.value as? Encodable)
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
