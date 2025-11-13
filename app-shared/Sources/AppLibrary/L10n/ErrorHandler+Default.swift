// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension ErrorHandler {
    public static func `default`() -> ErrorHandler {
        ErrorHandler(
            defaultTitle: Strings.Unlocalized.appName,
            dismissTitle: Strings.Global.Nouns.ok,
            errorDescription: {
                AppError($0).localizedDescription
            },
            beforeAlert: {
                pp_log_g(.App.core, .error, "Error handler being presented: \($0)")
            }
        )
    }
}
