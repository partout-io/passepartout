// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension DNSModule.Builder: ModuleViewProviding {
    public func moduleView(with parameters: ModuleViewParameters) -> some View {
        DNSView(draft: parameters.editor[self], parameters: parameters)
    }
}
