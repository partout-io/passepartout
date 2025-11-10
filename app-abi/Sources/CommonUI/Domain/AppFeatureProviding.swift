// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI {
    public protocol AppFeatureProviding {
        var features: [AppFeature] { get }
    }
}
