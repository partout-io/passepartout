// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct IPView: View, ModuleDraftEditing {

    @ObservedObject
    var draft: ModuleDraft<IPModule.Builder>

    @State
    private var subnets: [Address.Family: String] = [:]

    @State
    private var routePresentation: RoutePresentation?

    init(draft: ModuleDraft<IPModule.Builder>, parameters: ModuleViewParameters) {
        self.draft = draft
    }

    var body: some View {
        Group {
            ipSections(for: $draft.module.ipv4 ?? IPSettings(subnet: nil), family: .v4)
            ipSections(for: $draft.module.ipv6 ?? IPSettings(subnet: nil), family: .v6)
            interfaceSection
        }
        .moduleView(draft: draft)
        .themeModal(item: $routePresentation, content: routeModal)
        .onLoad(perform: loadSubnets)
        .onChange(of: subnets, perform: saveSubnets)
    }
}

private extension IPView {
    enum RoutePresentation: Identifiable {
        case included(Address.Family)

        case excluded(Address.Family)

        var id: String {
            switch self {
            case .included(let family):
                return "included.\(family)"

            case .excluded(let family):
                return "excluded.\(family)"
            }
        }

        var family: Address.Family {
            switch self {
            case .included(let family):
                return family

            case .excluded(let family):
                return family
            }
        }

        var localizedTitle: String {
            switch self {
            case .included:
                return Strings.Modules.Ip.Routes.include

            case .excluded:
                return Strings.Modules.Ip.Routes.exclude
            }
        }
    }

    @ViewBuilder
    func ipSections(for ip: Binding<IPSettings>, family: Address.Family) -> some View {
        ThemeTextField(
            Strings.Global.Nouns.address,
            text: $subnets[family] ?? "",
            placeholder: Strings.Unlocalized.Placeholders.ipDestination(forFamily: family),
            inputType: .ipAddress
        )
        .themeContainerWithSingleEntry(
            header: family.localizedDescription,
            footer: Strings.Modules.Ip.Address.footer
        )

        Group {
            ForEach(Array(ip.wrappedValue.includedRoutes.enumerated()), id: \.offset) { item in
                row(forRoute: item.element) {
                    ip.wrappedValue.removeIncluded(at: IndexSet(integer: item.offset))
                }
            }
            .onDelete {
                ip.wrappedValue.removeIncluded(at: $0)
            }
            ThemeTrailingContent {
                Button(Strings.Modules.Ip.Routes.include) {
                    routePresentation = .included(family)
                }
            }
        }
        .themeSection()

        Group {
            ForEach(Array(ip.wrappedValue.excludedRoutes.enumerated()), id: \.offset) { item in
                row(forRoute: item.element) {
                    ip.wrappedValue.removeExcluded(at: IndexSet(integer: item.offset))
                }
            }
            .onDelete {
                ip.wrappedValue.removeExcluded(at: $0)
            }
            ThemeTrailingContent {
                Button(Strings.Modules.Ip.Routes.exclude) {
                    routePresentation = .excluded(family)
                }
            }
        }
        .themeSection()
    }

    func row(forRoute route: Route, removeAction: @escaping () -> Void) -> some View {
        ThemeRemovableItemRow(isEditing: true) {
            ThemeCopiableText(value: route.localizedDescription) {
                Text($0)
            }
        } removeAction: {
            removeAction()
        }
    }

    var interfaceSection: some View {
        Group {
            ThemeTextField(
                Strings.Unlocalized.mtu,
                text: Binding {
                    draft.module.mtu?.description ?? ""
                } set: {
                    draft.module.mtu = Int($0)
                },
                placeholder: Strings.Unlocalized.Placeholders.mtu,
                inputType: .number
            )
        }
        .themeSection(header: Strings.Global.Nouns.interface)
    }
}

private extension IPView {
    func routeModal(item: RoutePresentation) -> some View {
        NavigationStack {
            RouteView(family: item.family) { route in
                defer {
                    routePresentation = nil
                }
                guard let route else {
                    return
                }
                switch item {
                case .included(let family):
                    switch family {
                    case .v4:
                        if draft.module.ipv4 == nil {
                            draft.module.ipv4 = IPSettings(subnet: nil)
                        }
                        draft.module.ipv4?.include(route)

                    case .v6:
                        if draft.module.ipv6 == nil {
                            draft.module.ipv6 = IPSettings(subnet: nil)
                        }
                        draft.module.ipv6?.include(route)
                    }

                case .excluded(let family):
                    switch family {
                    case .v4:
                        if draft.module.ipv4 == nil {
                            draft.module.ipv4 = IPSettings(subnet: nil)
                        }
                        draft.module.ipv4?.exclude(route)

                    case .v6:
                        if draft.module.ipv6 == nil {
                            draft.module.ipv6 = IPSettings(subnet: nil)
                        }
                        draft.module.ipv6?.exclude(route)
                    }
                }
            }
            .navigationTitle(item.localizedTitle)
        }
    }
}

private extension IPView {
    func loadSubnets() {
        if let v4 = draft.module.ipv4?.subnets.first?.rawValue {
            subnets[.v4] = v4
        }
        if let v6 = draft.module.ipv6?.subnets.first?.rawValue {
            subnets[.v6] = v6
        }
    }

    func saveSubnets(_ newSubnets: [Address.Family: String]) {
        newSubnets.forEach { pair in
            let subnet = Subnet(rawValue: pair.value)
            switch pair.key {
            case .v4:
                draft.module.ipv4 = draft.module.ipv4?.with(subnet: subnet) ?? IPSettings(subnet: subnet)
            case .v6:
                draft.module.ipv6 = draft.module.ipv6?.with(subnet: subnet) ?? IPSettings(subnet: subnet)
            }
        }
    }
}

#Preview {
    var module = IPModule.Builder()
    module.ipv4 = IPSettings(subnet: .init(rawValue: "10.20.30.40/16"))
        .including(routes: [
            .init(defaultWithGateway: .ip("1.2.3.4", .v4)),
            .init(.init(rawValue: "5.5.0.0/16"), .init(rawValue: "5.5.5.5"))
        ])
    module.ipv6 = IPSettings(subnet: nil)
        .including(routes: [
            .init(defaultWithGateway: .ip("fe80::1032:2a6b:fec:f49e", .v6)),
            .init(.init(rawValue: "fe80:1032:2a6b:fec::/24"), .init(rawValue: "fe80:1032:2a6b:fec::1"))
        ])
    return module.preview()
}
