// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore
import Partout

extension ConfigFileApplier {
    public static func defaultConfigPath() -> String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/passepartout.json")
            .path
    }

    @BusinessActor
    public func startWatching() {
        stopWatching()
        guard configExists else { return }
        let fd = open(filePath, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename],
            queue: .global(qos: .background)
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task { @BusinessActor [weak self] in
                guard let self else { return }
                do {
                    try await loadAndApply()
                } catch {
                    pspLog(.core, .error, "File config: reload error: \(error)")
                    didChange.send(.error(error))
                }
            }
        }
        let watcher = FileWatcher(source: source, fd: fd)
        fileWatcherStorage = watcher
        watcher.resume()
        pspLog(.core, .info, "File config: watching \(filePath)")
    }

    @BusinessActor
    public func stopWatching() {
        (fileWatcherStorage as? FileWatcher)?.cancel()
        fileWatcherStorage = nil
    }
}

// MARK: - FileWatcher

final class FileWatcher: @unchecked Sendable {
    private let source: DispatchSourceFileSystemObject
    private let fd: Int32

    init(source: DispatchSourceFileSystemObject, fd: Int32) {
        self.source = source
        self.fd = fd
    }

    deinit { cancel() }

    func resume() {
        source.resume()
    }

    func cancel() {
        source.cancel()
        close(fd)
    }
}
