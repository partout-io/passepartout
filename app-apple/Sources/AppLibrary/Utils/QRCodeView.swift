// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct QRCodeView: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        if let cgImage = text.qrImage() {
            Image(decorative: cgImage, scale: 1.0)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
    }
}
