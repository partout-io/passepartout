// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
#if !PARTOUT_MONOLITH
import PartoutCore
#endif

extension JSON {
    public func localizedString(forKey key: String) -> String {
        let dict = objectValue?[key]
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return dict?[code]?.stringValue ?? dict?["en"]?.stringValue ?? key
    }
}
