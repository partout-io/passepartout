// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !USE_CMAKE
@_exported import CommonData
#endif

extension CommonData {
    public static let providersBundle: Bundle = .module
}
