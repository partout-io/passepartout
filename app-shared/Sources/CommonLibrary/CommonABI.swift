// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_CROSS
import Partout
import PartoutABI_C

nonisolated(unsafe)
var ctx: UnsafeMutableRawPointer? = nil

func testInit() {
    pp_log_g(.core, .error, "(Running test init callback)")
}

@_cdecl("psp_partout_version")
public func psp_partout_version() -> UnsafePointer<CChar>! {
    // PARTOUT_VERSION
    partout_version()
}

@_cdecl("psp_init")
public func psp_init(cacheDir: UnsafePointer<CChar>!) {
    let tmpDir = FileManager.default.miniTemporaryDirectory.filePath()
    ctx = tmpDir.withCString { tmpDir in
        var args = partout_init_args()
        args.cache_dir = cacheDir ?? tmpDir
        args.test_callback = testInit
        return partout_init(&args)
    }
    assert(ctx != nil)
}

@_cdecl("psp_deinit")
public func psp_deinit() {
    guard let ctx else { return }
    partout_deinit(ctx)
}

@_cdecl("psp_daemon_start")
public func psp_daemon_start(
    profile: UnsafePointer<CChar>!,
    jniWrapper: UnsafeMutableRawPointer?
) -> Bool {
    var args = partout_daemon_start_args()
    args.profile = profile
    args.ctrl_impl = jniWrapper
    return partout_daemon_start(ctx, &args)
}

@_cdecl("psp_daemon_stop")
public func psp_daemon_stop() {
    partout_daemon_stop(ctx)
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
#endif
