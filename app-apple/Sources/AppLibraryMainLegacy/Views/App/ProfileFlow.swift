// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

struct ProfileFlow {
    let onEditProfile: (ABI.ProfilePreview) -> Void
    let onDeleteProfile: (ABI.ProfilePreview) -> Void
    let connectionFlow: ConnectionFlow?
}
