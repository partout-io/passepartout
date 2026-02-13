// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

struct ProfileFlow {
    let onEditProfile: (ABI.AppProfileHeader) -> Void
    let onDeleteProfile: (ABI.AppProfileHeader) -> Void
    let connectionFlow: ConnectionFlow?
}
