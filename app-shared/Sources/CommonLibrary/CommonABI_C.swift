// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(iOS) && !os(tvOS)

#if !USE_CMAKE
import PartoutABI_C
#endif

@_cdecl("psp_partout_version")
public nonisolated func __psp_partout_version() -> UnsafePointer<CChar>! {
    // PARTOUT_VERSION
    partout_version()
}

@_cdecl("psp_example_sum")
public nonisolated func __psp_example_sum(a: Int, b: Int) -> Int {
    a + b
}

@_cdecl("psp_example_json")
public nonisolated func __psp_example_json() -> UnsafeMutablePointer<CChar> {
    let module = try! DNSModule.Builder().build()
    let registry = Registry()
    let profile = try! Profile.Builder(name: "zio", modules: [module]).build()
    let json = try! registry.json(fromProfile: profile)
    return strdup(json)
}

#endif
