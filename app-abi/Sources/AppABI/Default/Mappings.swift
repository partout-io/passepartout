// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension Profile {
    var uiPreview: ProfileHeaderUI {
        ProfileHeaderUI(id: id.uuidString, name: name)
    }
}

extension ProfilePreview {
    var uiPreview: ProfileHeaderUI {
        ProfileHeaderUI(id: id.uuidString, name: name)
    }
}
