// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Foundation
import Partout
import Testing

struct ProfileEditorTests {
}

@MainActor
extension ProfileEditorTests {

    // MARK: CRUD

    @Test
    func givenModules_thenMatchesModules() {
        let sut = ProfileEditor(modules: [
            DNSModule.Builder(),
            IPModule.Builder()
        ])
        #expect(sut.profile.name.isEmpty)
        #expect(sut.modules[0] is DNSModule.Builder)
        #expect(sut.modules[1] is IPModule.Builder)
    }

    @Test
    func givenProfile_thenMatchesProfile() throws {
        let name = "foobar"
        let dns = try DNSModule.Builder().build()
        let ip = IPModule.Builder().build()
        let profile = try Profile.Builder(
            name: name,
            modules: [dns, ip],
            activeModulesIds: [dns.id]
        ).build()

        let sut = ProfileEditor(profile: profile)
        #expect(sut.profile.name == name)
        #expect(sut.modules[0] is DNSModule.Builder)
        #expect(sut.modules[1] is IPModule.Builder)
        #expect(sut.activeModulesIds == [dns.id])
    }

    @Test
    func givenProfileWithModules_thenExcludesModuleTypes() {
        let sut = ProfileEditor(modules: [
            DNSModule.Builder(),
            IPModule.Builder()
        ])
        let moduleTypes = sut.availableModuleTypes(forTarget: .appStore)

        #expect(!moduleTypes.contains(.dns))
        #expect(moduleTypes.contains(.httpProxy))
        #expect(!moduleTypes.contains(.ip))
        #expect(moduleTypes.contains(.onDemand))
        #expect(moduleTypes.contains(.openVPN))
        #expect(moduleTypes.contains(.wireGuard))
    }

    @Test
    func givenModules_thenReturnsModuleById() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        #expect(sut.modules[0].id == dns.id)
        #expect(sut.modules[1].id == ip.id)
        #expect(sut.module(withId: dns.id) is DNSModule.Builder)
        #expect(sut.module(withId: ip.id) is IPModule.Builder)
        #expect(sut.module(withId: UUID()) == nil)
    }

    @Test
    func givenModules_whenMove_thenMovesModules() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        sut.moveModules(from: IndexSet(integer: 0), to: 2)
        #expect(sut.modules[0].id == ip.id)
        #expect(sut.modules[1].id == dns.id)
    }

    @Test
    func givenModules_whenRemove_thenRemovesModules() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        sut.removeModules(at: IndexSet(integer: 0))
        #expect(sut.modules.count == 1)
        #expect(sut.modules[0].id == ip.id)
        #expect(Set(sut.removedModules.keys) == [dns.id])

        sut.removeModule(withId: dns.id)
        sut.removeModule(withId: ip.id)
        #expect(sut.modules.isEmpty)
        #expect(Set(sut.removedModules.keys) == [dns.id, ip.id])
    }

    @Test
    func givenModules_whenSaveNew_thenAppendsNew() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        sut.saveModule(ip, activating: false)
        #expect(sut.modules[1] is IPModule.Builder)
        #expect(sut.activeModulesIds == [dns.id, ip.id])
    }

    @Test
    func givenModules_whenSaveExisting_thenReplacesExisting() throws {
        var dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        dns.protocolType = .tls
        sut.saveModule(dns, activating: false)
        #expect(sut.activeModulesIds == [dns.id, ip.id])

        let newDNS = try #require(sut.modules[0] as? DNSModule.Builder)
        #expect(newDNS.protocolType == dns.protocolType)
    }

    @Test
    func givenModules_whenSaveActivating_thenActivates() {
        let dns = DNSModule.Builder()
        let sut = ProfileEditor(modules: [])

        sut.saveModule(dns, activating: true)
        #expect(sut.activeModulesIds == [dns.id])
    }

    // MARK: - Active modules

    @Test
    func givenModules_whenToggle_thenToggles() throws {
        let dns = DNSModule.Builder()
        let proxy = HTTPProxyModule.Builder()
        let sut = ProfileEditor(modules: [dns, proxy])

        #expect(sut.activeModulesIds == [dns.id, proxy.id])
        sut.toggleModule(withId: dns.id)
        #expect(sut.activeModulesIds == [proxy.id])
        sut.toggleModule(withId: dns.id)
        #expect(sut.activeModulesIds == [dns.id, proxy.id])
        sut.toggleModule(withId: dns.id)
        sut.toggleModule(withId: proxy.id)
        #expect(sut.activeModulesIds.isEmpty)
    }

    @Test
    func givenModules_whenMultipleConnections_thenFailsToBuild() throws {
        let ovpn = OpenVPNModule.Builder()
        let wg = WireGuardModule.Builder(configurationBuilder: .default)
        let sut = ProfileEditor(modules: [ovpn, wg])

        #expect(sut.activeModulesIds == [ovpn.id, wg.id])
        sut.toggleModule(withId: wg.id)
        #expect(sut.activeModulesIds == [ovpn.id])
        do {
            _ = try sut.buildAndUpdate()
            #expect(Bool(false))
        } catch {}
    }

    @Test
    func givenModulesWithoutConnection_whenActiveIP_thenFailsToBuild() throws {
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [ip])

        #expect(sut.activeModulesIds == [ip.id])
        do {
            _ = try sut.buildAndUpdate()
            #expect(Bool(false))
        } catch {}
    }

    // MARK: Building

    @Test
    func givenProfile_whenBuild_thenSucceeds() throws {
        var wg = WireGuardModule.Builder(configurationBuilder: .default)
        wg.configurationBuilder?.peers = [.init(publicKey: "")]
        let sut = ProfileEditor(modules: [wg])
        sut.profile.name = "hello"

        let profile = try sut.buildAndUpdate()
        let wgModule = try wg.build()
        #expect(profile.name == "hello")
        #expect(profile.modules.first is WireGuardModule)
        #expect(profile.modules.first as? WireGuardModule == wgModule)
        #expect(profile.activeModulesIds == [wg.id])
    }

    @Test
    func givenProfile_whenBuildWithEmptyName_thenFails() async throws {
        let sut = ProfileEditor(modules: [])
        do {
            _ = try sut.buildAndUpdate()
            #expect(Bool(false))
        } catch {}
    }

    @Test
    func givenProfile_whenBuildWithMalformedModule_thenFails() async throws {
        let dns = DNSModule.Builder(protocolType: .https) // missing URL
        let sut = ProfileEditor(modules: [dns])
        do {
            _ = try sut.buildAndUpdate()
            #expect(Bool(false))
        } catch {}
    }

    // MARK: Saving

    @Test
    func givenProfileManager_whenSave_thenSavesProfileToManager() async throws {
        let name = "foobar"
        let dns = try DNSModule.Builder().build()
        let ip = IPModule.Builder().build()
        let profile = try Profile.Builder(
            name: name,
            modules: [dns, ip],
            activeModulesIds: [dns.id]
        ).build()

        let sut = ProfileEditor(profile: profile)
        let manager = ProfileManager(profiles: [])

        let exp = Expectation()
        let profileEvents = manager.didChange.subscribe()
        Task {
            for await event in profileEvents {
                switch event {
                case .save(let savedProfile, _):
                    do {
                        let lhs = try savedProfile.withoutUserInfo()
                        let rhs = try profile.withoutUserInfo()
                        #expect(lhs == rhs)
                    } catch {
                        throw error
                    }
                    await exp.fulfill()
                default:
                    break
                }
            }
        }

        let builtProfile = try sut.buildAndUpdate()
        try await manager.save(builtProfile)
        try await exp.fulfillment(timeout: 500)
    }
}

private extension WireGuard.Configuration.Builder {
    static var `default`: WireGuard.Configuration.Builder {
        WireGuard.Configuration.Builder(privateKey: "")
    }
}
