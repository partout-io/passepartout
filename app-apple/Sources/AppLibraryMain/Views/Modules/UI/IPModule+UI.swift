// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension IPModule.Builder: ModuleViewProviding {
    public func moduleView(with parameters: ModuleViewParameters) -> some View {
        IPView(draft: parameters.editor[self], parameters: parameters)
    }
}
