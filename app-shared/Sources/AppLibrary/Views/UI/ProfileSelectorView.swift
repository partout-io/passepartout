// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ProfileSelectorView: View {

    @EnvironmentObject
    private var profileManager: ProfileManager

    private let title: String

    private let excludedProfileId: Profile.ID?

    private let onSelect: (ProfilePreview) -> Void

    public init(
        _ title: String,
        excluding excludedProfileId: Profile.ID? = nil,
        onSelect: @escaping (ProfilePreview) -> Void
    ) {
        self.title = title
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
            }
        }
    }
}

private extension ProfileSelectorView {
    var previews: [ProfilePreview]? {
        profileManager
            .previews
            .filter {
                $0.id != excludedProfileId
            }
            .nilIfEmpty
    }
}
