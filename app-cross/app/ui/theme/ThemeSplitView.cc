// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ThemeSplitView.h"
#include "Theme.h"
#include <algorithm>

namespace Passepartout {
ThemeSplitView::ThemeSplitView(wxWindow *parent)
    : wxSplitterWindow(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxSP_LIVE_UPDATE),
      sidebar_(new wxPanel(this)), detail_(new wxPanel(this)) {
    Theme::Apply(this);
    Theme::Apply(sidebar_);
    Theme::Apply(detail_);
    SetMinimumPaneSize(GetCharWidth() * 16);
    SetSashGravity(0.0);
    Bind(wxEVT_SPLITTER_DOUBLECLICKED, [](wxSplitterEvent &) {
        // Keep both navigation and content visible.
    });
}

int ThemeSplitView::InitializePanes() {
    const int width = std::max(GetCharWidth() * 28, sidebar_->GetBestSize().x);
    SplitVertically(sidebar_, detail_, width);
    return width;
}
}
