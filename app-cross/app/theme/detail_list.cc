// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "detail_list.h"
#include <algorithm>
#include <wx/clipbrd.h>
#include <wx/dataobj.h>
#include <wx/dcclient.h>
#include <wx/menu.h>
#include <wx/settings.h>
#include <wx/stockitem.h>

namespace Passepartout {
namespace {
enum RowFlags {
    Enabled = 1,
    Link = 2,
};
class DetailStore final : public wxDataViewListStore {
public:
    bool IsEnabledByRow(unsigned row, unsigned) const override {
        return (GetItemData(GetItem(row)) & Enabled) != 0;
    }
    bool GetAttrByRow(unsigned row, unsigned column, wxDataViewItemAttr &attributes) const override {
        if (column != 0 || !(GetItemData(GetItem(row)) & Link)) return false;
        attributes.SetColour(wxSystemSettings::GetColour(wxSYS_COLOUR_HOTLIGHT));
        return true;
    }
};
class MonospaceRenderer final : public wxDataViewCustomRenderer {
public:
    MonospaceRenderer() : wxDataViewCustomRenderer("string", wxDATAVIEW_CELL_INERT, wxALIGN_RIGHT) {}
    bool SetValue(const wxVariant &value) override {
        text_ = value.GetString();
        return true;
    }
    bool GetValue(wxVariant &value) const override {
        value = text_;
        return true;
    }
    wxSize GetSize() const override {
        wxClientDC dc(GetView());
        dc.SetFont(Font());
        return dc.GetTextExtent(text_);
    }
    bool Render(wxRect cell, wxDC *dc, int state) override {
        const wxDCFontChanger font(*dc, Font());
        RenderText(text_, 0, cell, dc, state);
        return true;
    }
#if wxUSE_ACCESSIBILITY
    wxString GetAccessibleDescription() const override {
        return text_;
    }
#endif
private:
    wxFont Font() const {
        return wxFontInfo(GetView()->GetFont().GetPointSize()).Family(wxFONTFAMILY_TELETYPE);
    }
    wxString text_;
};
}
ThemeDetailList::ThemeDetailList(wxWindow *parent, bool monospace) : ThemeList(parent, wxDV_NO_HEADER) {
    auto *store = new DetailStore;
    AssociateModel(store);
    store->DecRef();
    auto *caption = new wxDataViewTextRenderer("string", wxDATAVIEW_CELL_INERT, wxALIGN_LEFT);
    caption->EnableMarkup();
    AppendColumn(new wxDataViewColumn(wxString(), caption, 0, FromDIP(200), wxALIGN_LEFT, 0), "string");
    if (monospace) {
        AppendColumn(new wxDataViewColumn(wxString(), new MonospaceRenderer, 1, FromDIP(320), wxALIGN_RIGHT, 0), "string");
    } else {
        AppendTextColumn({}, wxDATAVIEW_CELL_INERT, FromDIP(320), wxALIGN_RIGHT, 0);
    }
    Bind(wxEVT_SIZE, [this](wxSizeEvent &event) {
        ResizeColumns();
        event.Skip();
    });
    Bind(wxEVT_DATAVIEW_ITEM_ACTIVATED, [this](wxDataViewEvent &event) {
        Activate(event.GetItem());
    });
#ifdef __WXMSW__
    // wxMSW's data-view mouse events originate in its internal client window.
    auto *surface = GetMainWindow();
    surface->Bind(wxEVT_LEFT_UP, [this, surface](wxMouseEvent &event) {
        wxDataViewItem item;
        wxDataViewColumn *column = nullptr;
        HitTest(ScreenToClient(surface->ClientToScreen(event.GetPosition())), item, column);
        if (column == GetColumn(0)) Activate(item);
        event.Skip();
    });
    surface->Bind(wxEVT_MOTION, [this, surface](wxMouseEvent &event) {
        wxDataViewItem item;
        wxDataViewColumn *column = nullptr;
        HitTest(ScreenToClient(surface->ClientToScreen(event.GetPosition())), item, column);
        surface->SetCursor(column == GetColumn(0) && IsLink(item) ? wxCURSOR_HAND : wxCURSOR_ARROW);
        event.Skip();
    });
    surface->Bind(wxEVT_LEAVE_WINDOW, [surface](wxMouseEvent &event) {
        surface->SetCursor(wxCURSOR_ARROW);
        event.Skip();
    });
#endif
    Bind(wxEVT_CHAR_HOOK, [this](wxKeyEvent &event) {
        if (event.GetKeyCode() == 'C' && event.ControlDown()) CopyValue();
        else if (event.GetKeyCode() == WXK_SPACE) Activate(GetCurrentItem());
        else event.Skip();
    });
    Bind(wxEVT_DATAVIEW_ITEM_CONTEXT_MENU, [this](wxDataViewEvent &event) {
        if (!event.GetItem().IsOk()) return;
        SetCurrentItem(event.GetItem());
        Select(event.GetItem());
        wxMenu menu;
        menu.Append(wxID_COPY, wxGetStockLabel(wxID_COPY));
        if (GetPopupMenuSelectionFromUser(menu) == wxID_COPY) CopyValue();
    });
}
void ThemeDetailList::Append(const wxString &title, const wxString &value,
    std::function<void()> action, bool enabled) {
    auto preview = value;
    preview.Replace("\r", "");
    preview.Replace("\n", ", ");
    auto caption = title;
    caption.Replace("&", "&amp;");
    caption.Replace("<", "&lt;");
    caption.Replace(">", "&gt;");
    const bool link = action && enabled;
    if (link) caption = "<u>" + caption + "</u>";
    wxVector<wxVariant> cells;
    cells.push_back(wxVariant(caption));
    cells.push_back(wxVariant(preview));
    rows_.push_back({value.empty() ? title : value, std::move(action), enabled});
    hasValues_ = hasValues_ || !value.empty();
    AppendItem(cells, (enabled ? Enabled : 0) | (link ? Link : 0));
    SetMinSize(wxSize(-1, static_cast<int>(rows_.size()) * RowHeight() + FromDIP(2)));
    ResizeColumns();
}
void ThemeDetailList::ResizeColumns() {
    const int width = GetClientSize().x;
    const int caption = hasValues_ ? std::max(FromDIP(120), width / 3) : width - FromDIP(4);
    GetColumn(0)->SetWidth(caption);
    GetColumn(1)->SetHidden(!hasValues_);
    GetColumn(1)->SetWidth(std::max(1, width - caption - FromDIP(4)));
}
bool ThemeDetailList::IsLink(const wxDataViewItem &item) const {
    if (!item.IsOk()) return false;
    const auto index = ItemToRow(item);
    if (index < 0 || static_cast<std::size_t>(index) >= rows_.size()) return false;
    const auto &row = rows_[index];
    return row.enabled && row.action;
}
void ThemeDetailList::Activate(const wxDataViewItem &item) {
    if (activating_ || !IsLink(item)) return;
    // Finish native input dispatch before navigation can remove this page.
    const auto action = rows_[ItemToRow(item)].action;
    activating_ = true;
    CallAfter([this, action] {
        activating_ = false;
        action();
    });
}
void ThemeDetailList::CopyValue() {
    const auto item = GetCurrentItem();
    if (!item.IsOk()) return;
    const auto index = ItemToRow(item);
    if (index < 0 || static_cast<std::size_t>(index) >= rows_.size()) return;
    if (!wxTheClipboard->Open()) return;
    wxTheClipboard->SetData(new wxTextDataObject(rows_[index].value));
    wxTheClipboard->Close();
}
}
