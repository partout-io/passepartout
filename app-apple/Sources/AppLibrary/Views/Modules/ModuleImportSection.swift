// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ModuleImportSection: View {

    @Binding
    private var isImporting: Bool

    public init(isImporting: Binding<Bool>) {
        _isImporting = isImporting
    }

    public var body: some View {
        Section {
            Button(Strings.Modules.General.Rows.importFromFile.forMenu) {
                isImporting = true
            }
        }
    }
}
