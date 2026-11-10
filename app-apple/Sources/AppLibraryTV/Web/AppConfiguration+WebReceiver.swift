// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(tvOS)
import CommonLibrary

extension ABI.AppConfiguration {
    public func makeWebReceiverManager(
        htmlPath: String,
        stringsBundle: Bundle
    ) -> WebReceiverManager {
        let receiver = NIOWebReceiver(
            htmlPath: htmlPath,
            stringsBundle: stringsBundle,
            port: constants.webReceiver.port
        )
        return WebReceiverManager(webReceiver: receiver) {
            makeWebPasscodeGenerator()
        }
    }
}
#endif
