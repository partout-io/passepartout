// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension JSON {
    public func localizedString(forKey key: String) -> String {
        let dict = objectValue?[key]
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return dict?[code]?.stringValue ?? dict?["en"]?.stringValue ?? key
    }
}
