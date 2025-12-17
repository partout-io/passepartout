// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension MultipartForm {
    public struct Builder {
        public var fields: [String: Field]

        public init() {
            fields = [:]
        }

        public func build() -> MultipartForm {
            MultipartForm(fields: fields)
        }
    }
}

public struct MultipartForm: Sendable {
    public struct Field: Sendable {
        public let value: String

        public let filename: String?

        public init(_ value: String, filename: String? = nil) {
            self.value = value
            self.filename = filename
        }
    }

    public let fields: [String: Field]
}

// MARK: - Web

extension MultipartForm {
    public init?(body: String) {
        guard let boundaryLine = body.components(separatedBy: "\r\n").first,
              boundaryLine.starts(with: "--") else {
            return nil
        }

        let boundary = boundaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = body.components(separatedBy: boundary)
            .dropFirst()
            .dropLast()

        var fields: [String: Field] = [:]
        for part in parts {
            let trimmedPart = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let headerRange = trimmedPart.range(of: "\r\n\r\n") else {
                continue
            }
            let headerText = String(trimmedPart[..<headerRange.lowerBound])
            let bodyText = trimmedPart[headerRange.upperBound...]

            let headers = headerText.components(separatedBy: "\r\n")
            var name: String?
            var filename: String?

            for header in headers where header.lowercased().starts(with: "content-disposition:") {
                let components = header.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
                for comp in components {
                    if comp.starts(with: "name=") {
                        name = comp.replacingOccurrences(of: "name=", with: "")
                            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    } else if comp.starts(with: "filename=") {
                        filename = comp.replacingOccurrences(of: "filename=", with: "")
                            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    }
                }
            }
            guard let name else {
                continue
            }
            guard let value = String(bodyText.utf8) else {
                continue
            }
            fields[name] = Field(value, filename: filename)
        }
        self.fields = fields
    }

    public func toWebData() -> (boundary: String, body: Data) {
        let boundary = newBoundary()
        var body = Data()
        fields.forEach {
            let filenameDisposition = $0.value.filename.map {
                "; filename=\"\($0)\""
            }
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\($0.key)\"\(filenameDisposition ?? "")\r\n")
            if filenameDisposition != nil {
                body.append("Content-Type: application/octet-stream\r\n")
            }
            body.append("\r\n")
            body.append("\($0.value.value)\r\n")
        }
        body.append("--\(boundary)--\r\n")
        return (boundary, body)
    }
}

private extension MultipartForm {
    func newBoundary() -> String {
        let charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let suffix = (0..<30).map { _ in
            charset.randomElement()!
        }
        return "MultipartForm-\(String(suffix))"
    }
}

private extension Data {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }
        append(data)
    }
}
