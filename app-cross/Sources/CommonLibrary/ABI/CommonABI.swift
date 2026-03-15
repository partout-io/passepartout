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
        struct DynamicCodingKeys: CodingKey {
            var stringValue: String
            init?(stringValue: String) { self.stringValue = stringValue }
            var intValue: Int? { nil }
            init?(intValue: Int) { nil }
        }

        private let payloadType: String?
        private let payload: Encodable?

        init(_ event: Event) {
            let subEvent = event.subEvent
            guard let subEvent else {
                payloadType = nil
                payload = nil
                return
            }
            payloadType = subEvent.type
            payload = subEvent.payload
        }

        func encode(to encoder: any Encoder) throws {
            guard let payloadType, let payload else {
                assertionFailure("Unable to encode event (missing payload)")
                return
            }

            //
            // WARNING: "eventType" MUST match 100% the codegen output
            // type (which is also the @SerialName) for the corresponding
            // sealed class in Kotlin
            //
            // E.g.: ConfigEvent.Refresh
            // payloadType = "CommonLibraryCore.ABI.ConfigEvent.Refresh"
            // eventType = "ABI_ConfigEvent_Refresh"
            //
            let eventType: String = {
                var comps = payloadType.split(separator: ".")
                let moduleName = comps.removeFirst()
                assert(moduleName == "CommonLibraryCore")
                return comps.joined(separator: "_")
            }()

            var container = encoder.container(keyedBy: DynamicCodingKeys.self)
            let eventTypeKey = DynamicCodingKeys(stringValue: "eventType")!
            try container.encode(eventType, forKey: eventTypeKey)
            try payload.encode(to: encoder)
        }
    }
}

private struct SubEvent {
    let type: String
    let payload: Encodable?
}

private extension ABI.Event {
    var subEvent: SubEvent? {
//        print(">>> event: \(self)")
        let mirror = Mirror(reflecting: self)
        guard let arg = mirror.children.first else { return nil }
//        print(">>> subevent: \(arg.label), \(arg.value)")
        guard let payload = Mirror(reflecting: arg.value).children.first?.value else {
            return nil
        }
//        print(">>> payload: \(payload)")
        let type = "\(String(reflecting: Swift.type(of: payload)))"
        return SubEvent(type: type, payload: payload as? Encodable)
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
