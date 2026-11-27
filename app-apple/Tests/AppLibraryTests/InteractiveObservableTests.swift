// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Foundation
import Testing

@MainActor
struct InteractiveObservableTests {
    @Test(arguments: [OpenVPN.Credentials.OTPMethod.none, .append, .encode])
    func submitsEditedProfileAcrossRepeatedPresentations(method: OpenVPN.Credentials.OTPMethod) throws {
        var configuration = OpenVPN.Configuration.Builder()
        configuration.ca = OpenVPN.CryptoContainer(pem: "ca")
        configuration.remotes = [try ExtendedEndpoint("vpn.example.com", EndpointProtocol(.udp, 1194))]
        let active = try OpenVPNModule.Builder(
            configurationBuilder: configuration,
            credentials: OpenVPN.Credentials(username: "user", password: "base", otpMethod: method),
            isInteractive: true
        ).build()
        var inactive = active
        inactive.id = UUID()
        var profile = try Profile.Builder(
            name: "Interactive", modules: [inactive, active], activeModulesIds: [active.id]
        ).build()
        let observable = InteractiveObservable()
        var previousEditor: ProfileEditor?
        for input in ["123456", "654321"] {
            var submitted: Profile?
            observable.present(with: profile) { submitted = $0 }
            #expect(observable.isPresented)
            #expect(observable.moduleId == active.id)
            #expect(observable.editor !== previousEditor)
            previousEditor = observable.editor
            var module = try #require(observable.editor.module(withId: active.id) as? OpenVPNModule.Builder)
            var credentials = try #require(module.credentials?.builder())
            if method == .none {
                credentials.password = input
                credentials.otp = nil
            } else {
                credentials.otp = input
            }
            module.credentials = credentials.build()
            observable.editor.saveModule(module, activating: false)
            try observable.complete()

            profile = try #require(submitted)
            let result = try #require((profile.activeModules.first as? OpenVPNModule)?.credentials)
            #expect(!observable.isPresented)
            #expect(result.username == "user")
            #expect(result.password == (method == .none ? input : "base"))
            #expect(result.otpMethod == method)
            #expect(result.otp == (method == .none ? nil : input))
            #expect((profile.modules.first as? OpenVPNModule)?.credentials == inactive.credentials)
            #expect(profile.activeModulesIds == [active.id])
        }
    }
}
