// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension HTTPProxyModule.Builder: LegacyModuleViewProviding {
    public func moduleView(with parameters: LegacyModuleViewParameters) -> some View {
        HTTPProxyView(draft: parameters.editor[self])
    }
}
