// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ProviderID: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        self != .oeck ? [.providers] : []
    }
}
