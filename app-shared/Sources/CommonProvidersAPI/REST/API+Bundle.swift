// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
extension API {
    public static func url(forVersion version: Int = 7) -> URL? {
        Bundle.module.url(forResource: "JSON/v\(version)", withExtension: nil)
    }
}
#endif
