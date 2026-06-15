// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !USE_CMAKE
@_exported import CommonData
#endif
import Partout

extension CommonData {
    public static let profilesBundle: Bundle = .module
}
