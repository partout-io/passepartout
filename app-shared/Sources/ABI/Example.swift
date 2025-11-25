// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_DYNLIB
import CommonLibrary
#endif
import Partout

@_cdecl("example")
public func example(a: Int, b: Int) -> Int {
    a + b
}

@_cdecl("modulone")
public func modulone() -> UnsafeMutablePointer<CChar> {
    let module = try! DNSModule.Builder().build()
    let registry = Registry()
    let parser = StandardOpenVPNParser()
    let profile = try! Profile.Builder(name: "zio", modules: [module]).build()
    let json = try! registry.json(fromProfile: profile)
    return strdup(json)
}
