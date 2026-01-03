// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

// WARNING: Menu sections look good on physical device, whereas
// they erroneously inherit the List section styling on iOS Simulator
// and Previews (bug!)

struct AddModuleMenu<Label>: View where Label: View {
    let moduleTypes: [ModuleType]

    let withProviderType: Bool

    let action: (ModuleType) -> Void

    let label: () -> Label

    var body: some View {
        let providerType: ModuleType = .provider
        let nonProviderTypes = moduleTypes.filter { $0 != providerType }
        let connectionModuleTypes = nonProviderTypes.filter(\.isConnection)
        let otherModuleTypes = nonProviderTypes.filter { !$0.isConnection }
        return Menu {
            if withProviderType {
                entryView(for: providerType)
            }
            if !connectionModuleTypes.isEmpty {
                ForEach(connectionModuleTypes.sorted(), id: \.self, content: entryView)
                    .themeSection(header: Strings.Global.Nouns.connection)
            }
            if !otherModuleTypes.isEmpty {
                ForEach(otherModuleTypes.sorted(), id: \.self, content: entryView)
                    .themeSection(header: Strings.Global.Nouns.settings)
            }
        } label: {
            label()
        }
        .disabled(moduleTypes.isEmpty)
    }
}

private extension AddModuleMenu {
    func entryView(for moduleType: ModuleType) -> some View {
        Button(moduleType.localizedDescription) {
            action(moduleType)
        }
    }
}

#Preview {
    List {
        AddModuleMenu(
            moduleTypes: ModuleType.allCases,
            withProviderType: true,
            action: { _ in },
            label: {
                Text("Add module")
            }
        )
    }
}
