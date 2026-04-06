// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ModuleShareGroup: View {
    @Environment(IAPObservable.self)
    private var iapObservable

    private let file: SerializedModuleFile

    @Binding
    private var isExporting: Bool

    @Binding
    private var exportedDocument: SerializedModuleFile?

    @Binding
    private var paywallReason: PaywallReason?

    public init(
        file: SerializedModuleFile,
        isExporting: Binding<Bool>,
        exportedDocument: Binding<SerializedModuleFile?>,
        paywallReason: Binding<PaywallReason?>
    ) {
        self.file = file
        _isExporting = isExporting
        _exportedDocument = exportedDocument
        _paywallReason = paywallReason
    }

    public var body: some View {
        Button(Strings.Global.Actions.export, action: export)
        if isEligible {
            ModuleShareButton(file: file)
        }
    }
}

private extension ModuleShareGroup {
    var isEligible: Bool {
        iapObservable.isEligible(for: .sharing)
    }

    func export() {
        guard isEligible else {
            paywallReason = .init(nil, requiredFeatures: [.sharing], action: .purchase)
            return
        }
        exportedDocument = file
        isExporting = true
    }
}
