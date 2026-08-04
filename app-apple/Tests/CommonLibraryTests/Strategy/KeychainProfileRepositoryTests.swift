// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Foundation
import Partout
import Testing

struct KeychainProfileRepositoryTests {
    @Test
    func fetchPublishesSnapshotAndSkipsMalformedItems() async throws {
        let first = try makeProfile(name: "first")
        let second = try makeProfile(name: "second")
        let coder = makeCoder()
        let keychain = MockProfileKeychain(passwords: [
            first.id.uuidString: try coder.string(fromProfile: first),
            second.id.uuidString: try coder.string(fromProfile: second),
            "malformed": "not-a-profile"
        ])
        let sut = makeRepository(keychain: keychain, coder: coder)
        var profilesIterator = sut.profilesPublisher.makeAsyncIterator()
        var eventsIterator = sut.eventsPublisher.makeAsyncIterator()

        #expect(await profilesIterator.next()?.isEmpty == true)

        let fetched = try await sut.fetchProfiles()
        let published = try #require(await profilesIterator.next())
        let event = try #require(await eventsIterator.next())

        #expect(Set(fetched.map(\.id)) == [first.id, second.id])
        #expect(Set(published.map(\.id)) == [first.id, second.id])
        guard case .snapshot(let snapshot) = event else {
            Issue.record("Expected a snapshot event")
            return
        }
        #expect(Set(snapshot.map(\.id)) == [first.id, second.id])
    }

    @Test
    func savePersistsMetadataAndPublishesUpsert() async throws {
        let fingerprint = UniqueID()
        let profile = try makeProfile(name: "saved", fingerprint: fingerprint)
        let coder = makeCoder()
        let keychain = MockProfileKeychain()
        let sut = makeRepository(keychain: keychain, coder: coder)
        var profilesIterator = sut.profilesPublisher.makeAsyncIterator()
        var eventsIterator = sut.eventsPublisher.makeAsyncIterator()

        #expect(await profilesIterator.next()?.isEmpty == true)

        try await sut.saveProfile(profile)
        let published = try #require(await profilesIterator.next())
        let event = try #require(await eventsIterator.next())
        let setCall = try #require(keychain.setCalls.first)

        #expect(published == [profile])
        #expect(setCall.username == profile.id.uuidString)
        #expect(setCall.label == "VPN: \(profile.name)")
        #expect(setCall.comment == fingerprint.uuidString)
        #expect(try coder.profile(fromString: setCall.password) == profile)
        guard case .changes(let changes) = event,
              changes.count == 1,
              case .upsert(let upserted) = changes[0] else {
            Issue.record("Expected one upsert event")
            return
        }
        #expect(upserted == profile)
    }

    @Test
    func removePublishesOnlyConfirmedRemovals() async throws {
        let removed = try makeProfile(name: "removed")
        let retained = try makeProfile(name: "retained")
        let coder = makeCoder()
        let keychain = MockProfileKeychain(
            passwords: [
                removed.id.uuidString: try coder.string(fromProfile: removed),
                retained.id.uuidString: try coder.string(fromProfile: retained)
            ],
            failedRemovals: [retained.id.uuidString]
        )
        let sut = makeRepository(keychain: keychain, coder: coder)
        var profilesIterator = sut.profilesPublisher.makeAsyncIterator()
        var eventsIterator = sut.eventsPublisher.makeAsyncIterator()

        #expect(await profilesIterator.next()?.isEmpty == true)
        _ = try await sut.fetchProfiles()
        _ = await profilesIterator.next()
        _ = await eventsIterator.next()

        try await sut.removeProfiles(withIds: [removed.id, retained.id])
        let published = try #require(await profilesIterator.next())
        let event = try #require(await eventsIterator.next())

        #expect(published == [retained])
        #expect(!keychain.contains(username: removed.id.uuidString))
        #expect(keychain.contains(username: retained.id.uuidString))
        guard case .changes(let changes) = event,
              changes.count == 1,
              case .remove(let removedId) = changes[0] else {
            Issue.record("Expected one confirmed removal event")
            return
        }
        #expect(removedId == removed.id)
    }
}

private extension KeychainProfileRepositoryTests {
    func makeCoder() -> CodingRegistry {
        CodingRegistry(registry: Registry(withKnown: true))
    }

    func makeRepository(
        keychain: Keychain,
        coder: ProfileCoder
    ) -> KeychainProfileRepository {
        KeychainProfileRepository(
            keychain: keychain,
            coder: coder,
            label: { "VPN: \($0.name)" }
        )
    }

    func makeProfile(
        name: String,
        fingerprint: UniqueID = UniqueID()
    ) throws -> Profile {
        var builder = Profile.Builder(name: name)
        builder.attributes.fingerprint = fingerprint
        return try builder.build()
    }
}

private final class MockProfileKeychain: Keychain, @unchecked Sendable {
    struct SetCall: Sendable {
        let password: String
        let username: String
        let label: String?
        let comment: String?
    }

    private let lock = NSLock()
    private var passwords: [String: String]
    private let failedRemovals: Set<String>
    private var mutableSetCalls: [SetCall] = []

    init(
        passwords: [String: String] = [:],
        failedRemovals: Set<String> = []
    ) {
        self.passwords = passwords
        self.failedRemovals = failedRemovals
    }

    var setCalls: [SetCall] {
        lock.withLock { mutableSetCalls }
    }

    func contains(username: String) -> Bool {
        lock.withLock { passwords[username] != nil }
    }

    func set(
        password: String,
        for username: String,
        metadata: [KeychainMetadata]?
    ) throws -> Data {
        var label: String?
        var comment: String?
        metadata?.forEach {
            switch $0 {
            case .label(let value):
                label = value
            case .comment(let value):
                comment = value
            }
        }
        lock.withLock {
            passwords[username] = password
            mutableSetCalls.append(SetCall(
                password: password,
                username: username,
                label: label,
                comment: comment
            ))
        }
        return reference(for: username)
    }

    func removePassword(for username: String) -> Bool {
        lock.withLock {
            guard !failedRemovals.contains(username) else { return false }
            return passwords.removeValue(forKey: username) != nil
        }
    }

    func removePassword(forReference reference: Data) -> Bool {
        guard let username = username(from: reference) else { return false }
        return removePassword(for: username)
    }

    func password(for username: String) throws -> String {
        try lock.withLock {
            guard let password = passwords[username] else {
                throw PartoutError(.keychainItemNotFound)
            }
            return password
        }
    }

    func passwordReference(for username: String) throws -> Data {
        try lock.withLock {
            guard passwords[username] != nil else {
                throw PartoutError(.keychainItemNotFound)
            }
        }
        return reference(for: username)
    }

    func allPasswordReferences() throws -> [Data] {
        lock.withLock {
            passwords.keys.map(reference(for:))
        }
    }

    func password(forReference reference: Data) throws -> String {
        guard let username = username(from: reference) else {
            throw PartoutError(.decoding)
        }
        return try password(for: username)
    }

    private func reference(for username: String) -> Data {
        Data("reference:\(username)".utf8)
    }

    private func username(from reference: Data) -> String? {
        guard let value = String(data: reference, encoding: .utf8),
              value.hasPrefix("reference:") else {
            return nil
        }
        return String(value.dropFirst("reference:".count))
    }
}
