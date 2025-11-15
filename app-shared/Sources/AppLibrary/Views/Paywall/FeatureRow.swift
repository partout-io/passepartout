// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct FeatureRow: View {
    public enum Flag {
        case highlighted

        case marked
    }

    private let feature: ABI.AppFeature

    private let flags: Set<Flag>

    public init(feature: ABI.AppFeature, flags: Set<Flag>) {
        self.feature = feature
        self.flags = flags
    }

    public var body: some View {
        HStack {
            ThemeImage(.marked)
                .opaque(flags.contains(.marked))
            Text(feature.localizedDescription)
                .fontWeight(flags.contains(.highlighted) ? .bold : .regular)
        }
        .foregroundStyle(flags.contains(.highlighted) ? .primary : .secondary)
    }
}
