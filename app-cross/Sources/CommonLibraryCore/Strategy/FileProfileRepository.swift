// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public actor FileProfileRepository: ProfileRepository {
    private struct IndexEntry: Codable, Sendable {
        let id: String
        let name: String
        let lastUpdate: Date?
        let fingerprint: String?
    }

    private struct IndexFile: Codable, Sendable {
        let version: Int
        let profiles: [IndexEntry]
    }

    private enum FileProfileRepositoryError: LocalizedError {
        case missingProfileId(String)
        case malformedIndex(Error)
        case malformedProfile(URL, Error)

        var errorDescription: String? {
            switch self {
            case .missingProfileId(let id):
                "Unable to locate stored profile \(id)"
            case .malformedIndex(let error):
                "Unable to decode profile index: \(error)"
            case .malformedProfile(let url, let error):
                "Unable to decode profile at \(url.lastPathComponent): \(error)"
            }
        }
    }

    private nonisolated let profilesSubject: CurrentValueStream<[Profile]>
    private let rootURL: URL
    private let objectsURL: URL
    private let tmpURL: URL
    private let indexURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL) throws {
        profilesSubject = CurrentValueStream([])
        rootURL = directoryURL
        objectsURL = directoryURL.appending(component: "objects", directoryHint: .isDirectory)
        tmpURL = directoryURL.appending(component: "tmp", directoryHint: .isDirectory)
        indexURL = directoryURL.appending(component: "index.json")

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: objectsURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tmpURL, withIntermediateDirectories: true)
        try Self.ensureIndex(
            indexURL: indexURL,
            objectsURL: objectsURL,
            encoder: encoder,
            decoder: decoder
        )
    }

    public nonisolated var profilesPublisher: AsyncStream<[Profile]> {
        profilesSubject.subscribe()
    }

    public func fetchProfiles() async throws -> [Profile] {
        let profiles = try loadProfiles()
        profilesSubject.send(profiles)
        return profiles
    }

    public func saveProfile(_ profile: Profile) async throws {
        let data = try encoder.encode(profile.asTaggedProfile)
        try writeAtomically(data, to: objectURL(for: profile.id))
        try persistIndex(for: try loadProfilesById())
        try publishProfiles()
    }

    public func removeProfiles(withIds profileIds: [Profile.ID]) async throws {
        guard !profileIds.isEmpty else {
            return
        }
        for profileId in profileIds {
            let url = objectURL(for: profileId)
            if FileManager.default.fileExists(atPath: url.filePath()) {
                try FileManager.default.removeItem(at: url)
            }
        }
        try persistIndex(for: try loadProfilesById())
        try publishProfiles()
    }

    public func removeAllProfiles() async throws {
        let existingFiles = try FileManager.default.contentsOfDirectory(at: objectsURL)
        for fileURL in existingFiles where fileURL.pathExtension == "json" {
            try? FileManager.default.removeItem(at: fileURL)
        }
        try persistIndex(for: [:])
        try publishProfiles()
    }
}

private extension FileProfileRepository {
    static func ensureIndex(
        indexURL: URL,
        objectsURL: URL,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) throws {
        guard FileManager.default.fileExists(atPath: indexURL.filePath()) else {
            try persistIndex(
                for: loadProfilesByIdFromObjects(objectsURL: objectsURL, decoder: decoder),
                indexURL: indexURL,
                tmpURL: objectsURL.deletingLastPathComponent().appending(component: "tmp", directoryHint: .isDirectory),
                encoder: encoder,
                sortProfiles: sortProfiles
            )
            return
        }
        do {
            _ = try loadIndex(from: indexURL, decoder: decoder)
        } catch {
            pspLog(.profiles, .error, "Rebuilding malformed profile index: \(error)")
            try persistIndex(
                for: loadProfilesByIdFromObjects(objectsURL: objectsURL, decoder: decoder),
                indexURL: indexURL,
                tmpURL: objectsURL.deletingLastPathComponent().appending(component: "tmp", directoryHint: .isDirectory),
                encoder: encoder,
                sortProfiles: sortProfiles
            )
        }
    }

    func ensureIndex() throws {
        guard FileManager.default.fileExists(atPath: indexURL.filePath()) else {
            try rebuildIndex()
            return
        }
        do {
            _ = try loadIndex()
        } catch {
            pspLog(.profiles, .error, "Rebuilding malformed profile index: \(error)")
            try rebuildIndex()
        }
    }

    func publishProfiles() throws {
        profilesSubject.send(try loadProfiles())
    }

    func rebuildIndex() throws {
        try persistIndex(for: loadProfilesByIdFromObjects())
    }

    func loadProfiles() throws -> [Profile] {
        let profilesById = try loadProfilesById()
        return try orderedIds().compactMap {
            guard let profile = profilesById[$0] else {
                throw FileProfileRepositoryError.missingProfileId($0)
            }
            return profile
        }
    }

    func loadProfilesById() throws -> [String: Profile] {
        let knownIds = Set(try orderedIds())
        let objects = try loadProfilesByIdFromObjects()
        let unknownIds = Set(objects.keys).subtracting(knownIds)
        guard !unknownIds.isEmpty else {
            return objects
        }
        pspLog(.profiles, .error, "Profile index missing \(unknownIds.count) entries, rebuilding")
        try persistIndex(for: objects)
        return objects
    }

    func loadProfilesByIdFromObjects() throws -> [String: Profile] {
        try Self.loadProfilesByIdFromObjects(objectsURL: objectsURL, decoder: decoder)
    }

    func orderedIds() throws -> [String] {
        try loadIndex().profiles.map(\.id)
    }

    private func loadIndex() throws -> IndexFile {
        try Self.loadIndex(from: indexURL, decoder: decoder)
    }

    func persistIndex(for profilesById: [String: Profile]) throws {
        try Self.persistIndex(
            for: profilesById,
            indexURL: indexURL,
            tmpURL: tmpURL,
            encoder: encoder,
            sortProfiles: sortProfiles
        )
    }

    func sortProfiles(lhs: Profile, rhs: Profile) -> Bool {
        Self.sortProfiles(lhs: lhs, rhs: rhs)
    }

    static func sortProfiles(lhs: Profile, rhs: Profile) -> Bool {
        let leftName = lhs.name.lowercased()
        let rightName = rhs.name.lowercased()
        if leftName != rightName {
            return leftName < rightName
        }
        let leftLastUpdate = lhs.attributes.lastUpdate ?? .distantPast
        let rightLastUpdate = rhs.attributes.lastUpdate ?? .distantPast
        if leftLastUpdate != rightLastUpdate {
            return leftLastUpdate > rightLastUpdate
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    func objectURL(for id: Profile.ID) -> URL {
        objectsURL.appending(component: "\(id.uuidString).json")
    }

    func writeAtomically(_ data: Data, to destinationURL: URL) throws {
        let tempURL = tmpURL.appending(component: "\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: .atomic)
        if FileManager.default.fileExists(atPath: destinationURL.filePath()) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
    }

    static func loadProfilesByIdFromObjects(
        objectsURL: URL,
        decoder: JSONDecoder
    ) throws -> [String: Profile] {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: objectsURL)
        var profilesById: [String: Profile] = [:]
        for fileURL in fileURLs where fileURL.pathExtension == "json" {
            let data = try Data(contentsOf: fileURL)
            do {
                let tagged = try decoder.decode(TaggedProfile.self, from: data)
                let profile = try tagged.asProfile()
                profilesById[profile.id.uuidString] = profile
            } catch {
                throw FileProfileRepositoryError.malformedProfile(fileURL, error)
            }
        }
        return profilesById
    }

    private static func loadIndex(from indexURL: URL, decoder: JSONDecoder) throws -> IndexFile {
        do {
            let data = try Data(contentsOf: indexURL)
            return try decoder.decode(IndexFile.self, from: data)
        } catch let error as FileProfileRepositoryError {
            throw error
        } catch {
            throw FileProfileRepositoryError.malformedIndex(error)
        }
    }

    static func persistIndex(
        for profilesById: [String: Profile],
        indexURL: URL,
        tmpURL: URL,
        encoder: JSONEncoder,
        sortProfiles: (Profile, Profile) -> Bool
    ) throws {
        let profiles = profilesById.values.sorted(by: sortProfiles)
        let index = IndexFile(
            version: 1,
            profiles: profiles.map {
                IndexEntry(
                    id: $0.id.uuidString,
                    name: $0.name,
                    lastUpdate: $0.attributes.lastUpdate,
                    fingerprint: $0.attributes.fingerprint?.uuidString
                )
            }
        )
        let data = try encoder.encode(index)
        try writeAtomically(data, to: indexURL, tmpURL: tmpURL)
    }

    static func writeAtomically(_ data: Data, to destinationURL: URL, tmpURL: URL) throws {
        let tempURL = tmpURL.appending(component: "\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: .atomic)
        if FileManager.default.fileExists(atPath: destinationURL.filePath()) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
    }
}
