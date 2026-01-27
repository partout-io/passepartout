// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension WireGuardModule.Builder: LegacyModuleViewProviding {
    public func moduleView(with parameters: LegacyModuleViewParameters) -> some View {
        WireGuardView(draft: parameters.editor[self])
    }
}
