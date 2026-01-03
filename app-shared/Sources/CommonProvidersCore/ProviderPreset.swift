// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct ProviderPreset: Hashable, Codable, Sendable {
    public let providerId: ProviderID

    public let presetId: String

    public let description: String

    public let moduleType: ModuleType

    public let templateData: Data

    public init(
        providerId: ProviderID,
        presetId: String,
        description: String,
        moduleType: ModuleType,
        templateData: Data
    ) {
        self.providerId = providerId
        self.presetId = presetId
        self.description = description
        self.moduleType = moduleType
        self.templateData = templateData
    }
}

extension ProviderPreset {
    public var id: String {
        [providerId.rawValue, presetId].joined(separator: ".")
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.providerId == rhs.providerId && lhs.presetId == rhs.presetId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(providerId)
        hasher.combine(presetId)
    }
}

extension ProviderPreset {
    public func template<Template>(ofType type: Template.Type) throws -> Template where Template: Decodable {
        try JSONDecoder().decode(type, from: templateData)
    }
}
