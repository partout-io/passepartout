// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension WireGuardModule.Builder: ModuleViewProviding {
    public func moduleView(with parameters: ModuleViewParameters) -> some View {
        WireGuardView(draft: parameters.editor[self], parameters: parameters)
    }
}
