// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
import PartoutABI_C

nonisolated(unsafe)
var ctx: UnsafeMutableRawPointer? = nil

func testInit() {
    pp_log_g(.core, .error, ">>> Partout version is \(PartoutConstants.version)")
}

@_cdecl("psp_partout_version")
public func psp_partout_version() -> UnsafePointer<CChar>! {
    // PARTOUT_VERSION
    partout_version()
}

@_cdecl("psp_init")
public func psp_init() -> Bool {
    // FIXME: ###, Maybe this is broken
    // let tmpDir = FileManager.default.miniTemporaryDirectory.filePath()
    let tmpDir = "C:\\repos\\passepartout"
    var args = partout_init_args()
    let cacheDir = strdup(tmpDir)
    args.cache_dir = cacheDir.map {
        UnsafePointer($0)
    }
    args.test_callback = testInit
    ctx = partout_init(&args)
    free(cacheDir)
    return ctx != nil
}

@_cdecl("psp_deinit")
func psp_deinit() {
    guard let ctx else { return }
    partout_deinit(ctx)
}
