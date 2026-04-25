// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ProfileSelectorMenu: View {
    @Environment(ProfileObservable.self)
    private var profileObservable

    private let title: String

    private let image: Theme.ImageName

    private let newTitle: String?

    private let excludedProfileId: Profile.ID?

    private let onSelect: (ABI.AppProfileHeader?) -> Void

    public init(
        _ title: String,
        image: Theme.ImageName,
        withNewTitle newTitle: String? = nil,
        excluding excludedProfileId: Profile.ID? = nil,
        onSelect: @escaping (ABI.AppProfileHeader?) -> Void
    ) {
        self.title = title
        self.image = image
        self.newTitle = newTitle
        self.excludedProfileId = excludedProfileId
        self.onSelect = onSelect
    }

    public var body: some View {
        headers.map { headers in
            Menu {
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
            } label: {
                ThemeImageLabel(title, image)
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
