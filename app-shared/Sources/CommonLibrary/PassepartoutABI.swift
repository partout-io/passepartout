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
    let tmpDir = FileManager.default.miniTemporaryDirectory.filePath()
    ctx = tmpDir.withCString { tmpDir in
        var args = partout_init_args()
        args.cache_dir = tmpDir
        args.test_callback = testInit
        return partout_init(&args)
    }
    assert(ctx != nil)
    return true
}

@_cdecl("psp_deinit")
func psp_deinit() {
    guard let ctx else { return }
    partout_deinit(ctx)
}
