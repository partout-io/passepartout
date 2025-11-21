// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_DYNLIB
import CommonLibrary
#endif

@_cdecl("example")
public func example(a: Int, b: Int) -> Int {
    a + b
}
