// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension ModuleBuilder {
    public func serializedIgnoringErrors(withName name: String) -> SerializedModuleFile? {
        do {
            guard let mod = try build() as? SerializableModule else {
                return nil
            }
            return try SerializedModuleFile(
                name: name,
                extension: mod.preferredExtension,
                content: mod.serialized()
            )
        } catch {
            pspLog(.profiles, .debug, "Unable to serialize module \(id): \(error)")
            return nil
        }
    }
}
