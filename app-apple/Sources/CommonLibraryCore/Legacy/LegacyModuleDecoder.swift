// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@available(*, deprecated, message: "Superseded. Used by LegacyProfileEncoderV2")
public protocol LegacyModuleDecoder {
    func decodedModule(from decoder: Decoder, ofType moduleType: ModuleType) throws -> Module
}
