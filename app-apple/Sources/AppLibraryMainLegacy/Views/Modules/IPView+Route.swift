// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension IPView {
    struct RouteView: View {

        @Environment(Theme.self)
        private var theme

        let family: Address.Family

        let onSubmit: (Route?) -> Void

        @State
        private var destinationString = ""

        @State
        private var gatewayString = ""

        @State
        private var isDefault = false

        var body: some View {
            Form {
                Section {
                    Toggle(Strings.Global.Nouns.default, isOn: $isDefault.animation(theme.animation(for: .modules)))
                }
                if !isDefault {
                    Section {
                        ThemeTextField(
                            Strings.Global.Nouns.destination,
                            text: $destinationString,
                            placeholder: Strings.Unlocalized.Placeholders.ipDestination(forFamily: family),
                            inputType: .ipAddress
                        )
                        ThemeTextField(
                            Strings.Global.Nouns.gateway,
                            text: $gatewayString,
                            placeholder: Strings.Unlocalized.Placeholders.ipAddress(forFamily: family),
                            inputType: .ipAddress
                        )
                    }
                }
            }
            .themeForm()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Global.Actions.cancel, role: .cancel) {
                        onSubmit(nil)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Global.Nouns.ok, action: parseAndSubmit)
                }
            }
            .themeNavigationDetail()
        }
    }
}

private extension IPView.RouteView {
    func parseAndSubmit() {
        let route: Route
        if isDefault {
            route = Route(defaultWithGateway: nil)
        } else {
            guard let destination = Subnet(rawValue: destinationString) else {
                return
            }
            let gateway = Address(rawValue: gatewayString)
            guard destination.address.family == family else {
                return
            }
            if let gateway {
                guard gateway.family == family else {
                    return
                }
            }
            route = Route(destination, gateway)
        }
        onSubmit(route)
    }
}

#Preview {
    struct Preview: View {

        @State
        private var route: Route?

        @State
        private var isPresented = false

        var body: some View {
            List {
                Button("Add route") {
                    isPresented = true
                }
                .themeModal(isPresented: $isPresented) {
                    NavigationStack {
                        IPView.RouteView(family: .v4) {
                            route = $0
                            isPresented = false
                        }
                        .navigationTitle("Add route")
                    }
                }
                route.map { route in
                    VStack {
                        route.destination.map {
                            ThemeRow("Destination", value: $0.rawValue)
                        }
                        route.gateway.map {
                            ThemeRow("Gateway", value: $0.rawValue)
                        }
                    }
                }
            }
        }
    }

    return Preview()
        .withMockEnvironment()
}
