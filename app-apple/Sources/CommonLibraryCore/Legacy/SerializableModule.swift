// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// A module that can be serialized as a textual profile.
public protocol SerializableModule: Module {
    /// Preferred file extension for serialized output.
    var preferredExtension: String { get }
}
