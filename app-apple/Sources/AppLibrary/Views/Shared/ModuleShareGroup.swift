// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ModuleShareGroup: View {
    private let file: SerializedModuleFile

    @Binding
    private var isExporting: Bool

    @Binding
    private var exportedDocument: SerializedModuleFile?

    public init(
        file: SerializedModuleFile,
        isExporting: Binding<Bool>,
        exportedDocument: Binding<SerializedModuleFile?>
    ) {
        self.file = file
        _isExporting = isExporting
        _exportedDocument = exportedDocument
    }

    public var body: some View {
        Button(Strings.Global.Actions.export) {
            exportedDocument = file
            isExporting = true
        }
        ModuleShareButton(file: file)
    }
}
