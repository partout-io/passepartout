// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension DNSModule.Builder: LegacyModuleViewProviding {
    public func moduleView(with parameters: LegacyModuleViewParameters) -> some View {
        DNSView(draft: parameters.editor[self])
    }
}
