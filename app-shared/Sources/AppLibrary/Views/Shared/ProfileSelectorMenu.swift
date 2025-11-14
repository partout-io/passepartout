// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public struct ProfileSelectorMenu: View {

    @EnvironmentObject
    private var profileManager: ProfileManager

    private let title: String

    private let newTitle: String?

    private let excludedProfileId: Profile.ID?

    private let onSelect: (ProfilePreview?) -> Void

    public init(
        _ title: String,
        withNewTitle newTitle: String? = nil,
        excluding excludedProfileId: Profile.ID? = nil,
        onSelect: @escaping (ProfilePreview?) -> Void
    ) {
        self.title = title
        self.newTitle = newTitle
        self.excludedProfileId = excludedProfileId
        self.onSelect = onSelect
    }

    public var body: some View {
        previews.map { previews in
            Menu(title) {
                ForEach(previews, id: \.id) { profile in
                    Button(profile.name) {
                        onSelect(profile)
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
    var previews: [ProfilePreview]? {
        let filtered = profileManager
            .previews
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
