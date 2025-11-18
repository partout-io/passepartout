// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Foundation
import Partout
import XCTest

final class ProfileEditorTests: XCTestCase {
}

@MainActor
extension ProfileEditorTests {

    // MARK: CRUD

    func test_givenModules_thenMatchesModules() {
        let sut = ProfileEditor(modules: [
            DNSModule.Builder(),
            IPModule.Builder()
        ])
        XCTAssertTrue(sut.profile.name.isEmpty)
        XCTAssertTrue(sut.modules[0] is DNSModule.Builder)
        XCTAssertTrue(sut.modules[1] is IPModule.Builder)
    }

    func test_givenProfile_thenMatchesProfile() throws {
        let name = "foobar"
        let dns = try DNSModule.Builder().build()
        let ip = IPModule.Builder().build()
        let profile = try Profile.Builder(
            name: name,
            modules: [dns, ip],
            activeModulesIds: [dns.id]
        ).build()

        let sut = ProfileEditor(profile: profile)
        XCTAssertEqual(sut.profile.name, name)
        XCTAssertTrue(sut.modules[0] is DNSModule.Builder)
        XCTAssertTrue(sut.modules[1] is IPModule.Builder)
        XCTAssertEqual(sut.activeModulesIds, [dns.id])
    }

    func test_givenProfileWithModules_thenExcludesModuleTypes() {
        let sut = ProfileEditor(modules: [
            DNSModule.Builder(),
            IPModule.Builder()
        ])
        let moduleTypes = sut.availableModuleTypes(forTarget: .appStore)

        XCTAssertFalse(moduleTypes.contains(.dns))
        XCTAssertTrue(moduleTypes.contains(.httpProxy))
        XCTAssertFalse(moduleTypes.contains(.ip))
        XCTAssertTrue(moduleTypes.contains(.onDemand))
        XCTAssertTrue(moduleTypes.contains(.openVPN))
        XCTAssertTrue(moduleTypes.contains(.wireGuard))
    }

    func test_givenModules_thenReturnsModuleById() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        XCTAssertEqual(sut.modules[0].id, dns.id)
        XCTAssertEqual(sut.modules[1].id, ip.id)
        XCTAssertTrue(sut.module(withId: dns.id) is DNSModule.Builder)
        XCTAssertTrue(sut.module(withId: ip.id) is IPModule.Builder)
        XCTAssertNil(sut.module(withId: UUID()))
    }

    func test_givenModules_whenMove_thenMovesModules() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        sut.moveModules(from: IndexSet(integer: 0), to: 2)
        XCTAssertEqual(sut.modules[0].id, ip.id)
        XCTAssertEqual(sut.modules[1].id, dns.id)
    }

    func test_givenModules_whenRemove_thenRemovesModules() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        sut.removeModules(at: IndexSet(integer: 0))
        XCTAssertEqual(sut.modules.count, 1)
        XCTAssertEqual(sut.modules[0].id, ip.id)
        XCTAssertEqual(Set(sut.removedModules.keys), [dns.id])

        sut.removeModule(withId: dns.id)
        sut.removeModule(withId: ip.id)
        XCTAssertTrue(sut.modules.isEmpty)
        XCTAssertEqual(Set(sut.removedModules.keys), [dns.id, ip.id])
    }

    func test_givenModules_whenSaveNew_thenAppendsNew() {
        let dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        sut.saveModule(ip, activating: false)
        XCTAssertTrue(sut.modules[1] is IPModule.Builder)
        XCTAssertEqual(sut.activeModulesIds, [dns.id, ip.id])
    }

    func test_givenModules_whenSaveExisting_thenReplacesExisting() throws {
        var dns = DNSModule.Builder()
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [dns, ip])

        dns.protocolType = .tls
        sut.saveModule(dns, activating: false)
        XCTAssertEqual(sut.activeModulesIds, [dns.id, ip.id])

        let newDNS = try XCTUnwrap(sut.modules[0] as? DNSModule.Builder)
        XCTAssertEqual(newDNS.protocolType, dns.protocolType)
    }

    func test_givenModules_whenSaveActivating_thenActivates() {
        let dns = DNSModule.Builder()
        let sut = ProfileEditor(modules: [])

        sut.saveModule(dns, activating: true)
        XCTAssertEqual(sut.activeModulesIds, [dns.id])
    }

    // MARK: - Active modules

    func test_givenModules_whenToggle_thenToggles() throws {
        let dns = DNSModule.Builder()
        let proxy = HTTPProxyModule.Builder()
        let sut = ProfileEditor(modules: [dns, proxy])

        XCTAssertEqual(sut.activeModulesIds, [dns.id, proxy.id])
        sut.toggleModule(withId: dns.id)
        XCTAssertEqual(sut.activeModulesIds, [proxy.id])
        sut.toggleModule(withId: dns.id)
        XCTAssertEqual(sut.activeModulesIds, [dns.id, proxy.id])
        sut.toggleModule(withId: dns.id)
        sut.toggleModule(withId: proxy.id)
        XCTAssertEqual(sut.activeModulesIds, [])
    }

    func test_givenModules_whenMultipleConnections_thenFailsToBuild() throws {
        let ovpn = OpenVPNModule.Builder()
        let wg = WireGuardModule.Builder(configurationBuilder: .default)
        let sut = ProfileEditor(modules: [ovpn, wg])

        XCTAssertEqual(sut.activeModulesIds, [ovpn.id, wg.id])
        sut.toggleModule(withId: wg.id)
        XCTAssertEqual(sut.activeModulesIds, [ovpn.id])
        XCTAssertThrowsError(try sut.buildAndUpdate())
    }

    func test_givenModulesWithoutConnection_whenActiveIP_thenFailsToBuild() throws {
        let ip = IPModule.Builder()
        let sut = ProfileEditor(modules: [ip])

        XCTAssertEqual(sut.activeModulesIds, [ip.id])
        XCTAssertThrowsError(try sut.buildAndUpdate())
    }

    // MARK: Building

    func test_givenProfile_whenBuild_thenSucceeds() throws {
        var wg = WireGuardModule.Builder(configurationBuilder: .default)
        wg.configurationBuilder?.peers = [.init(publicKey: "")]
        let sut = ProfileEditor(modules: [wg])
        sut.profile.name = "hello"

        let profile = try sut.buildAndUpdate()
        XCTAssertEqual(profile.name, "hello")
        XCTAssertTrue(profile.modules.first is WireGuardModule)
        XCTAssertEqual(profile.modules.first as? WireGuardModule, try wg.build())
        XCTAssertEqual(profile.activeModulesIds, [wg.id])
    }

    func test_givenProfile_whenBuildWithEmptyName_thenFails() async throws {
        let sut = ProfileEditor(modules: [])
        XCTAssertThrowsError(try sut.buildAndUpdate())
    }

    func test_givenProfile_whenBuildWithMalformedModule_thenFails() async throws {
        let dns = DNSModule.Builder(protocolType: .https) // missing URL
        let sut = ProfileEditor(modules: [dns])
        XCTAssertThrowsError(try sut.buildAndUpdate())
    }

    // MARK: Saving

    func test_givenProfileManager_whenSave_thenSavesProfileToManager() async throws {
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

        let exp = expectation(description: "Save")
        let profileEvents = manager.didChange.subscribe()
        Task {
            for await event in profileEvents {
                switch event {
                case .save(let savedProfile, _):
                    do {
                        let lhs = try savedProfile.withoutUserInfo()
                        let rhs = try profile.withoutUserInfo()
                        XCTAssertEqual(lhs, rhs)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    exp.fulfill()
                default:
                    break
                }
            }
        }

        _ = try await sut.save(
            to: manager,
            buildingWith: Registry(),
            verifyingWith: nil,
            preferencesManager: PreferencesManager()
        )
        await fulfillment(of: [exp])
    }
}

private extension WireGuard.Configuration.Builder {
    static var `default`: WireGuard.Configuration.Builder {
        WireGuard.Configuration.Builder(privateKey: "")
    }
}
