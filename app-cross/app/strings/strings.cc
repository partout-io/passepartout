// SPDX-License-Identifier: GPL-3.0
#include "strings.h"
#include <wx/intl.h>
#include <map>
#include <string>

namespace Passepartout {
namespace {
struct Entry {
    const char *locale;
    const char *key;
    const char *value;
};
const Entry entries[] = {
#include "apple_strings.inc"
};
using Catalog = std::map<std::string, wxString>;
const std::map<std::string, Catalog> &Catalogs() {
    static const auto catalogs = [] {
        std::map<std::string, Catalog> result;
        for (const auto &entry : entries) {
            result[entry.locale].emplace(entry.key, wxString::FromUTF8(entry.value));
        }
        return result;
    }();
    return catalogs;
}
}

wxString Localized(const char *key, const wxString &locale) {
    auto language = locale;
    language.Replace("-", "_");
    // Apple uses a script identifier for Simplified Chinese.
    if (language == "zh_CN" || language == "zh_SG") language = "zh_Hans";
    const auto &catalogs = Catalogs();
    for (const auto &candidate : {language, language.BeforeFirst('_'), wxString("en")}) {
        const auto catalog = catalogs.find(candidate.ToStdString(wxConvUTF8));
        if (catalog == catalogs.end()) continue;
        const auto entry = catalog->second.find(key);
        if (entry != catalog->second.end()) return entry->second;
    }
    return wxString::FromUTF8(key);
}

wxString Localized(const char *key) {
    static const auto locale = [] {
        const auto *info = wxLocale::GetLanguageInfo(wxLocale::GetSystemLanguage());
        return info ? info->CanonicalName : wxString("en");
    }();
    return Localized(key, locale);
}
}
