// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)
import Combine
import Foundation

@MainActor
public enum AppPipe {
    public static let importer = PassthroughSubject<[URL], Never>()

    public static let settings = PassthroughSubject<Void, Never>()
}
#endif
