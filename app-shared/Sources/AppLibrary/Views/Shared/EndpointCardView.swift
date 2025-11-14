// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public struct EndpointCardView: View {
    private let endpoint: ExtendedEndpoint

    public init(endpoint: ExtendedEndpoint) {
        self.endpoint = endpoint
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(endpoint.address.rawValue)
                .font(.headline)

            Text("\(endpoint.proto.socketType.rawValue):\(endpoint.proto.port.description)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
