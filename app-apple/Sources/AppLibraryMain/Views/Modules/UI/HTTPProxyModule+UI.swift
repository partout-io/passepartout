// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension HTTPProxyModule.Builder: ModuleViewProviding {
    public func moduleView(with editor: ProfileEditor) -> some View {
        HTTPProxyView(draft: editor[self])
    }
}
