// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct WebDonationLink: View {
    var body: some View {
        Link(Strings.Views.Donate.title, destination: Constants.shared.websites.donate)
    }
}
