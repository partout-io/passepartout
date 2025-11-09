// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension Profile {
    public var uiPreview: UI.ProfileHeader {
        UI.ProfileHeader(id: id.uuidString, name: name)
    }
}

extension ProfilePreview {
    public var uiPreview: UI.ProfileHeader {
        UI.ProfileHeader(id: id.uuidString, name: name)
    }
}
