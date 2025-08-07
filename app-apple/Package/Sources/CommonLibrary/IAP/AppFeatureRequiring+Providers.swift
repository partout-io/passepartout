// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ProviderID: AppFeatureRequiring {
    public var features: Set<AppFeature> {
        self != .oeck ? [.providers] : []
    }
}
