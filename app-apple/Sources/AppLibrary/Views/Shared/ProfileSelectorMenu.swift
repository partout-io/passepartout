// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ProfileSelectorMenu: View {
    @Environment(ProfileObservable.self)
    private var profileObservable

    private let title: String

    private let newTitle: String?

    private let excludedProfileId: Profile.ID?

    private let onSelect: (ABI.AppProfileHeader?) -> Void

    public init(
        _ title: String,
        withNewTitle newTitle: String? = nil,
        excluding excludedProfileId: Profile.ID? = nil,
        onSelect: @escaping (ABI.AppProfileHeader?) -> Void
    ) {
        self.title = title
        self.newTitle = newTitle
        self.excludedProfileId = excludedProfileId
        self.onSelect = onSelect
    }

    public var body: some View {
        headers.map { headers in
            Menu(title) {
                ForEach(headers, id: \.id) { header in
                    Button(header.name) {
                        onSelect(header)
                    }
                }
                if let newTitle {
                    Divider()
                    Button(newTitle) {
                        onSelect(nil)
                    }
                    // XXX: Header renders bad on macOS
                    .themeSection(header: Strings.Views.App.Toolbar.NewProfile.empty)
                }
            }
        }
    }
}

private extension ProfileSelectorMenu {
    var headers: [ABI.AppProfileHeader]? {
        let filtered = profileObservable
            .filteredHeaders
            .filter {
                $0.id != excludedProfileId
            }
        // If the list is empty and new profile selection is
        // not allowed, return nil
        guard !filtered.isEmpty || newTitle != nil else {
            return nil
        }
        return filtered
    }
}
