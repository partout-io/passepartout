// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

extension OpenVPNView {
    struct RemotesView: View {

        @Binding
        var configuration: OpenVPN.Configuration.Builder

        @ObservedObject
        var excludedEndpoints: ObservableList<ExtendedEndpoint>

        let isEditable: Bool

        @State
        private var editMode: EditMode = .inactive

        var body: some View {
            RemotesInnerView(
                configuration: $configuration,
                excludedEndpoints: excludedEndpoints,
                isEditable: isEditable
            )
            .environment(\.editMode, $editMode)
        }
    }
}

// MARK: - Inner view

private extension OpenVPNView {
    struct RemotesInnerView: View {

        @EnvironmentObject
        private var theme: Theme

        @Environment(\.editMode)
        private var editMode: Binding<EditMode>?

        @Binding
        var configuration: OpenVPN.Configuration.Builder

        @ObservedObject
        var excludedEndpoints: ObservableList<ExtendedEndpoint>

        let isEditable: Bool

        var body: some View {
            Form {
                if isEditable {
                    editableSection
                } else {
                    nonEditableSection
                }
            }
            .themeForm()
            .navigationTitle(Strings.Modules.Openvpn.remotes)
            .toolbar {
#if os(iOS)
                if isEditable {
                    EditButton()
                }
#endif
            }
        }
    }
}

private extension OpenVPNView.RemotesInnerView {
#if os(iOS)
    @ViewBuilder
    var editableSection: some View {
        if editMode?.wrappedValue == .active {
            editableListSection
        } else {
            nonEditableSection
        }
    }

    func editableLabel(isEditing: Bool, remote: Binding<EditableRemote>) -> some View {
        EditableRemoteRow(remote: remote)
    }
#else
    var editableSection: some View {
        editableListSection
    }

    @ViewBuilder
    func editableLabel(isEditing: Bool, remote: Binding<EditableRemote>) -> some View {
        if isEditing {
            EditableRemoteRow(remote: remote)
        } else if let remote = remote.wrappedValue.asEndpoint {
            SelectableRemoteButton(
                remote: remote,
                all: Set(allRemotes),
                excludedEndpoints: excludedEndpoints
            )
        } else {
            HStack {
                ThemeImage(.warning)
                Text(remote.wrappedValue.description)
            }
        }
    }
#endif

    var editableListSection: some View {
        theme.listSection(
            nil,
            addTitle: Strings.Global.Actions.add,
            originalItems: editableRemotesBinding,
            canEmpty: false,
            itemLabel: editableLabel
        )
        .labelsHidden()
    }

    var nonEditableSection: some View {
        Section {
            ForEach(allRemotes, id: \.rawValue) { remote in
                SelectableRemoteButton(
                    remote: remote,
                    all: Set(allRemotes),
                    excludedEndpoints: excludedEndpoints
                )
            }
        }
    }
}

private extension OpenVPNView.RemotesInnerView {
    var allRemotes: [ExtendedEndpoint] {
        configuration.remotes ?? []
    }

    var editableRemotesBinding: Binding<[EditableRemote]> {
        Binding {
            guard let remotes = configuration.remotes else {
                return []
            }
            return remotes.map {
                EditableRemote(
                    endpoint: "\($0.address):\($0.proto.port)",
                    socketType: $0.proto.socketType
                )
            }
        } set: {
            configuration.remotes = $0.compactMap(\.asEndpoint)
        }
    }
}

// MARK: - Subviews

private struct EditableRemoteRow: View {
    static let socketTypes: [IPSocketType] = [
        .udp,
        .udp4,
        .udp6,
        .tcp,
        .tcp4,
        .tcp6
    ]

    @Binding
    var remote: EditableRemote

    var body: some View {
        HStack {
            ThemeTextField(
                "",
                text: $remote.endpoint,
                placeholder: Strings.Unlocalized.OpenVPN.Placeholders.endpoint
            )
            Spacer()
            Picker("", selection: $remote.socketType) {
                ForEach(Self.socketTypes, id: \.self) {
                    Text($0.rawValue)
                }
            }
        }
    }
}

private struct SelectableRemoteButton: View {
    let remote: ExtendedEndpoint

    let all: Set<ExtendedEndpoint>

    @ObservedObject
    var excludedEndpoints: ObservableList<ExtendedEndpoint>

    var body: some View {
        Button {
            if excludedEndpoints.contains(remote) {
                excludedEndpoints.remove(remote)
            } else {
                if remaining.count > 1 {
                    excludedEndpoints.add(remote)
                }
            }
        } label: {
            HStack {
                EndpointCardView(endpoint: remote)
                Spacer()
                ThemeImage(.marked)
                    .opaque(!excludedEndpoints.contains(remote))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var remaining: Set<ExtendedEndpoint> {
        all.filter {
            !excludedEndpoints.contains($0)
        }
    }
}

// MARK: - View models

private struct EditableRemote: Equatable, EditableValue {
    static let emptyValue = EditableRemote(endpoint: "", socketType: .udp)

    var isEmptyValue: Bool {
        self == Self.emptyValue
    }

    var endpoint: String

    var socketType: IPSocketType

    var description: String {
        endpoint
    }
}

extension EditableRemote {
    init(endpoint: ExtendedEndpoint) {
        self.init(
            endpoint: "\(endpoint.address):\(endpoint.proto.port)",
            socketType: endpoint.proto.socketType
        )
    }

    var asEndpoint: ExtendedEndpoint? {
        var components = endpoint.split(separator: ":")
        guard components.count >= 2, let port = components.last else {
            return nil
        }
        components.removeLast()
        let address = components.joined(separator: ":")
        let rawValue = "\(address):\(socketType.rawValue):\(port)"
        return ExtendedEndpoint(rawValue: rawValue)
    }
}

// MARK: - Previews

private struct Preview: View {
    let isEditable: Bool

    @State
    private var builder: OpenVPN.Configuration.Builder = .forPreviews

    @State
    private var list: Set<ExtendedEndpoint> = []

    var body: some View {
        OpenVPNView.RemotesView(
            configuration: $builder,
            excludedEndpoints: ObservableList<ExtendedEndpoint>(
                contains: { list.contains($0) },
                add: { list.insert($0) },
                remove: { list.remove($0) }
            ),
            isEditable: isEditable
        )
    }
}

#Preview("Non-Editable") {
    Preview(isEditable: false)
        .withMockEnvironment()
}

#Preview("Editable") {
    Preview(isEditable: true)
        .withMockEnvironment()
        .themeNavigationStack()
}
