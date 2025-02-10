//
//  FeatureListView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/18/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import SwiftUI

enum FeatureListViewStyle {
    case list

#if !os(tvOS)
    case table
#endif
}

struct FeatureListView<Content>: View where Content: View {
    let style: FeatureListViewStyle

    var header: String?

    let features: [AppFeature]

    let content: (AppFeature) -> Content

    var body: some View {
        switch style {
        case .list:
            listView

#if !os(tvOS)
        case .table:
            tableView
#endif
        }
    }
}

private extension FeatureListView {
    var listView: some View {
        ForEach(features.sorted(), id: \.id, content: content)
            .themeSection(header: header)
    }

#if !os(tvOS)
    var tableView: some View {
        Table(features.sorted()) {
            TableColumn(header ?? "", content: content)
        }
    }
#endif
}
