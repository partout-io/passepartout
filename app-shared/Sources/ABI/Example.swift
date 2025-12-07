// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
import CommonLibrary
#endif
import Partout

@_cdecl("psp_example_sum")
public func _psp_example_sum(a: Int, b: Int) -> Int {
    a + b
}

@_cdecl("psp_example_json")
public func _psp_example_json() -> UnsafeMutablePointer<CChar> {
    let module = try! DNSModule.Builder().build()
    let registry = Registry()
    let parser = StandardOpenVPNParser()
    let profile = try! Profile.Builder(name: "zio", modules: [module]).build()
    let json = try! registry.json(fromProfile: profile)
    return strdup(json)
}
