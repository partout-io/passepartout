// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(iOS) && !os(tvOS)

import CommonLibraryCore_C
import PartoutABI_C

nonisolated(unsafe)
private var partout: UnsafeMutableRawPointer? = nil

@_cdecl("psp_partout_version")
public func __psp_partout_version() -> UnsafePointer<CChar>! {
    // PARTOUT_VERSION
    partout_version()
}

@_cdecl("psp_init")
public func __psp_init(args: UnsafePointer<psp_init_args>!) {
//    args.pointee.event_cb
//    args.pointee.event_ctx
    let tmpDir = FileManager.default.miniTemporaryDirectory.filePath()
    partout = tmpDir.withCString { tmpDir in
        var partoutArgs = partout_init_args()
        partoutArgs.cache_dir = args.pointee.cache_dir ?? tmpDir
        partoutArgs.test_callback = testInit
        return partout_init(&partoutArgs)
    }
    assert(partout != nil)
}

@_cdecl("psp_deinit")
public func __psp_deinit() {
    guard let partout else { return }
    partout_deinit(partout)
}

// MARK: - Profile

// MARK: - Tunnel

// MARK: - Tunnel daemon

@_cdecl("psp_daemon_start")
public func __psp_daemon_start(
    profile: UnsafePointer<CChar>!,
    jniWrapper: UnsafeMutableRawPointer?
) -> Bool {
    var args = partout_daemon_start_args()
    args.profile = profile
    args.ctrl_impl = jniWrapper
    return partout_daemon_start(partout, &args)
}

@_cdecl("psp_daemon_stop")
public func __psp_daemon_stop() {
    partout_daemon_stop(partout)
}

// MARK: - Test

@_cdecl("psp_example_sum")
public func __psp_example_sum(a: Int, b: Int) -> Int {
    a + b
}

@_cdecl("psp_example_json")
public func __psp_example_json() -> UnsafeMutablePointer<CChar> {
    let module = try! DNSModule.Builder().build()
    let registry = Registry()
    let profile = try! Profile.Builder(name: "zio", modules: [module]).build()
    let json = try! registry.json(fromProfile: profile)
    return strdup(json)
}

private func testInit() {
    pp_log_g(.core, .error, "(Running test init callback)")
}

#endif
