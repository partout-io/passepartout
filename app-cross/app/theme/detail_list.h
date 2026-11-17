// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "list.h"
#include <functional>
#include <vector>

namespace Passepartout {
class ThemeDetailList final : public ThemeList {
public:
    explicit ThemeDetailList(wxWindow *parent);
    void Append(const wxString &title, const wxString &value,
                std::function<void()> action = {}, bool enabled = true, bool monospace = false);
private:
    struct Row {
        wxString value;
        std::function<void()> action;
        bool enabled;
    };
    bool IsLink(const wxDataViewItem &item) const;
    void Activate(const wxDataViewItem &item);
    void CopyValue();
    void ResizeColumns();
    std::vector<Row> rows_;
    bool hasValues_ = false;
    bool activating_ = false;
};
}
