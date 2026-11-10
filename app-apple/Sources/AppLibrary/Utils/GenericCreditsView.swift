// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct GenericCreditsView: View {
    private let credits: ABI.Credits

    private var licensesHeader: String?

    private var noticesHeader: String?

    private var translationsHeader: String?

    private let errorDescription: (Error) -> String

    @State
    private var contentForLicense: [String: String] = [:]

    public init(
        credits: ABI.Credits,
        licensesHeader: String? = nil,
        noticesHeader: String? = nil,
        translationsHeader: String? = nil,
        errorDescription: @escaping (Error) -> String
    ) {
        self.credits = credits
        self.licensesHeader = licensesHeader
        self.noticesHeader = noticesHeader
        self.translationsHeader = translationsHeader
        self.errorDescription = errorDescription
    }

    public var body: some View {
        Form {
            if !credits.licenses.isEmpty {
                licensesSection
            }
            if !credits.notices.isEmpty {
                noticesSection
            }
            if !credits.translations.isEmpty {
                translationsSection
            }
        }
    }
}

private extension GenericCreditsView {
    struct LicenseView: View {
        let url: URL

        let errorDescription: (Error) -> String

        @Binding
        var content: String?

        @State
        private var loadingError: String?

        var body: some View {
            ZStack {
                (content ?? loadingError).map { unwrapped in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading) {
                            let rows = unwrapped.components(separatedBy: .newlines)
                            ForEach(rows.indices, id: \.self) { index in
                                Text(rows[index])
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .monospaced()
                                    .scrollableOnTV(isText: true)
                            }
                        }
                        .padding()
                    }
                }
                if content == nil && loadingError == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .task {
                await loadURL()
            }
        }
    }
}

// MARK: -

private extension GenericCreditsView {
    var sortedLicenses: [ABI.Credits.License] {
        credits.licenses.sorted {
            $0.name.lowercased() < $1.name.lowercased()
        }
    }

    var sortedNotices: [ABI.Credits.Notice] {
        credits.notices.sorted {
            $0.name.lowercased() < $1.name.lowercased()
        }
    }

    var sortedLanguages: [String] {
        credits.translations.keys.sorted {
            ($0.localizedAsLanguageCode ?? $0) < ($1.localizedAsLanguageCode ?? $1)
        }
    }

    var licensesSection: some View {
        Section {
            ForEach(sortedLicenses, id: \.name) { license in
                NavigationLink {
                    LicenseView(
                        url: license.licenseURL,
                        errorDescription: errorDescription,
                        content: $contentForLicense[license.name]
                    )
                    .navigationTitle(license.name)
                } label: {
                    HStack {
                        Text(license.name)
                        Spacer()
                        Text(license.licenseName)
                    }
                }
            }
        } header: {
            licensesHeader.map(Text.init)
        }
    }

    var noticesSection: some View {
        Section {
            ForEach(sortedNotices, id: \.name) { notice in
                NavigationLink(notice.name, destination: noticeView(notice))
            }
        } header: {
            noticesHeader.map(Text.init)
        }
    }

    var translationsSection: some View {
        Section {
            ForEach(sortedLanguages, id: \.self) { code in
                translationLabel(code)
            }
        } header: {
            translationsHeader.map(Text.init)
        }
    }

    func noticeView(_ content: ABI.Credits.Notice) -> some View {
        VStack {
            Text(content.message)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
        }
        .navigationTitle(content.name)
    }

    func translationLabel(_ code: String) -> some View {
        HStack {
            Text(code.localizedAsLanguageCode ?? code)
            Spacer()
            credits.translations[code].map { authors in
                VStack(spacing: 4) {
                    ForEach(authors, id: \.self) {
                        Text($0)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .scrollableOnTV()
    }
}

// MARK: -

@MainActor
private extension GenericCreditsView.LicenseView {
    func loadURL() async {
        guard content == nil else {
            return
        }
        loadingError = nil
        do {
            let session = URLSession(configuration: .ephemeral)
            let (data, response) = try await session.data(from: url)
            try Task.checkCancellation()
            if let response = response as? HTTPURLResponse,
               !(200..<300).contains(response.statusCode) {
                throw URLError(.badServerResponse)
            }
            guard let string = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            withAnimation {
                content = string
            }
        } catch {
            guard !Task.isCancelled else { return }
            withAnimation {
                loadingError = errorDescription(error)
            }
        }
    }
}
