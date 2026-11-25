// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/dataview.h>
#include <wx/graphics.h>
#include <wx/settings.h>
#include <memory>

namespace Passepartout {
class ThemeSwitchRenderer final : public wxDataViewCustomRenderer {
public:
    ThemeSwitchRenderer(const wxString &on_label, const wxString &off_label)
        : wxDataViewCustomRenderer("bool", wxDATAVIEW_CELL_ACTIVATABLE, wxALIGN_CENTER),
          on_label_(on_label), off_label_(off_label) {}

    bool SetValue(const wxVariant &value) override {
        is_on_ = value.GetBool();
        return true;
    }

    bool GetValue(wxVariant &value) const override {
        value = is_on_;
        return true;
    }

    wxSize GetSize() const override {
        return GetView()->FromDIP(wxSize(40, 24));
    }

    bool Render(wxRect cell, wxDC *dc, int) override {
        const auto size = GetView()->FromDIP(wxSize(36, 18));
        const auto track = wxRect(size).CentreIn(cell);
        const auto inset = GetView()->FromDIP(3);
        const auto diameter = track.height - 2 * inset;
        const auto knob_x = is_on_ ? track.GetRight() - inset - diameter + 1 : track.x + inset;
        const wxRect knob(knob_x, track.y + inset, diameter, diameter);
        const auto outline = wxSystemSettings::GetColour(GetEnabled() ? wxSYS_COLOUR_WINDOWTEXT : wxSYS_COLOUR_GRAYTEXT);
        const auto fill = wxSystemSettings::GetColour(is_on_ && GetEnabled() ? wxSYS_COLOUR_HIGHLIGHT : wxSYS_COLOUR_WINDOW);
        const auto thumb = is_on_ && GetEnabled() ? wxSystemSettings::GetColour(wxSYS_COLOUR_HIGHLIGHTTEXT) : outline;
        const wxPen border(outline, GetView()->FromDIP(1));
        std::unique_ptr<wxGraphicsContext> graphics(wxGraphicsContext::CreateFromUnknownDC(*dc));
        if (graphics) {
            graphics->SetPen(border);
            graphics->SetBrush(wxBrush(fill));
            graphics->DrawRoundedRectangle(track.x, track.y, track.width, track.height, track.height / 2.0);
            graphics->SetPen(*wxTRANSPARENT_PEN);
            graphics->SetBrush(wxBrush(thumb));
            graphics->DrawEllipse(knob.x, knob.y, knob.width, knob.height);
        } else {
            wxDCPenChanger pen(*dc, border);
            wxDCBrushChanger brush(*dc, wxBrush(fill));
            dc->DrawRoundedRectangle(track, track.height / 2.0);
            dc->SetPen(*wxTRANSPARENT_PEN);
            dc->SetBrush(wxBrush(thumb));
            dc->DrawEllipse(knob);
        }
        return true;
    }

    bool ActivateCell(const wxRect &, wxDataViewModel *model, const wxDataViewItem &item,
                      unsigned column, const wxMouseEvent *) override {
        if (!model->IsEnabled(item, column)) return false;
        wxVariant value;
        model->GetValue(value, item, column);
        return model->ChangeValue(wxVariant(!value.GetBool()), item, column);
    }

#if wxUSE_ACCESSIBILITY
    wxString GetAccessibleDescription() const override {
        return is_on_ ? on_label_ : off_label_;
    }
#endif
private:
    wxString on_label_;
    wxString off_label_;
    bool is_on_ = false;
};
}
