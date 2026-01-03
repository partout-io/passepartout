// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreImage.CIFilterBuiltins
import Foundation

extension String {
    public func qrImage() -> CGImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(utf8)
        filter.setValue(data, forKey: "inputMessage")
        guard let outputImage = filter.outputImage else {
            return nil
        }
        return context.createCGImage(outputImage, from: outputImage.extent)
    }
}
