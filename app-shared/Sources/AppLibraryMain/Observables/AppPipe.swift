// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import Foundation

@MainActor
public enum AppPipe {
    public static let importer = PassthroughSubject<[URL], Never>()

    public static let settings = PassthroughSubject<Void, Never>()
}
