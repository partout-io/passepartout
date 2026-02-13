// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileCardView: View {
    enum Style {
        case compact

        case full
    }

    let style: Style

    let header: ABI.AppProfileHeader

    let tunnel: TunnelObservable

    var onTap: ((ABI.AppProfileHeader) -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            Spacer(minLength: .zero)

            ThemeNavigatingButton {
                onTap?(header)
            } label: {
                Text(header.name)
                    .font(.headline)
                    .themeMultiLine(true)
            }
            .uiAccessibility(.App.profileEdit)

            statusView
                .font(.subheadline)

            Spacer(minLength: .zero)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
#if os(iOS)
        .padding(.vertical, 4)
#endif
    }
}

private extension ProfileCardView {
    var statusView: some View {
        ConnectionStatusText(tunnel: tunnel, profileId: header.id)
    }
}

// MARK: - Previews

#Preview {
    Form {
        Section {
            ProfileCardView(
                style: .compact,
                header: .forPreviews,
                tunnel: .forPreviews
            )
        }
        Section {
            ProfileCardView(
                style: .full,
                header: .forPreviews,
                tunnel: .forPreviews
            )
        }
    }
    .themeForm()
    .withMockEnvironment()
}
