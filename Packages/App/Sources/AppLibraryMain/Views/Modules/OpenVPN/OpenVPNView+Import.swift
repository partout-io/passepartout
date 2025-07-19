//
//  OpenVPNView+Import.swift
//  Passepartout
//
//  Created by Davide De Rosa on 12/8/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import CommonUtils
import SwiftUI

extension OpenVPNView {
    struct ImportModifier: ViewModifier {

        @ObservedObject
        var draft: ModuleDraft<OpenVPNModule.Builder>

        let impl: OpenVPNModule.Implementation?

        @Binding
        var isImporting: Bool

        @ObservedObject
        var errorHandler: ErrorHandler

        @State
        private var importURL: URL?

        @State
        private var importPassphrase: String?

        @State
        private var requiresPassphrase = false

        func body(content: Content) -> some View {
            content
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.item],
                    onCompletion: importConfiguration
                )
                .alert(
                    draft.module.moduleType.localizedDescription,
                    isPresented: $requiresPassphrase,
                    presenting: importURL,
                    actions: { url in
                        SecureField(
                            Strings.Placeholders.secret,
                            text: $importPassphrase ?? ""
                        )
                        Button(Strings.Alerts.Import.Passphrase.ok) {
                            importConfiguration(from: .success(url))
                        }
                        Button(Strings.Global.Actions.cancel, role: .cancel) {
                            isImporting = false
                        }
                    },
                    message: {
                        Text(Strings.Alerts.Import.Passphrase.message($0.lastPathComponent))
                    }
                )
        }
    }
}

private extension OpenVPNView.ImportModifier {
    func importConfiguration(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else {
                throw AppError.permissionDenied
            }
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            importURL = url

            guard let impl else {
                fatalError("Requires OpenVPNModule implementation")
            }
            let parsed: Module
            do {
                parsed = try impl.importer.module(fromURL: url, object: importPassphrase)
            } catch let error as PartoutError {
                pp_log_g(.app, .error, "Unable to parse URL: \(error)")

                switch error.code {
                case .OpenVPN.passphraseRequired:
                    Task {
                        // XXX: re-present same alert after artificial delay
                        try? await Task.sleep(for: .milliseconds(500))
                        importPassphrase = nil
                        requiresPassphrase = true
                    }
                    return

                case .unknownImportedModule:
                    throw PartoutError(.parsing)

                default:
                    throw error
                }
            }
            guard let module = parsed as? OpenVPNModule else {
                throw PartoutError(.parsing)
            }
            draft.module.configurationBuilder = module.configuration?.builder()
            draft.module.credentials = module.credentials
        } catch {
            pp_log_g(.app, .error, "Unable to import OpenVPN configuration: \(error)")
            errorHandler.handle(error, title: draft.module.moduleType.localizedDescription)
        }
    }
}
