// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension WireGuardModule.Builder: ModuleViewProviding {
    public func moduleView(with editor: ProfileEditor) -> some View {
        WireGuardView(draft: editor[self])
    }
}
