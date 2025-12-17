// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_PROVIDERS
extension ProviderID: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        self != .oeck ? [.providers] : []
    }
}
#endif
