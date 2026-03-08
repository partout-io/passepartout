// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_CROSS
@globalActor
public actor BusinessActor {
    public static let shared = BusinessActor()
}
#else
public typealias BusinessActor = MainActor
#endif
