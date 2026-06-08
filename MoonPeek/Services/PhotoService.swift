//
//  PhotoService.swift
//  MoonPeek
//

import Foundation
import CryptoKit
import SwiftData

// MARK: - Linode Object Storage config

private enum LinodeS3 {
    static let endpoint   = "de-fra-1.linodeobjects.com"
    static let bucket     = "chrisdevcode"
    static let prefix     = "artemis/"
    static let accessKey  = Secrets.linodeAccessKey
    static let secretKey  = Secrets.linodeSecretKey
    static let region     = "de-fra-1"

    /// Public URL for a given object key (bucket acts as path prefix on the virtual-hosted endpoint).
    /// The key is percent-encoded against `.urlPathAllowed` so spaces / unicode in filenames don't break `URL(string:)`.
    static func publicURL(for key: String) -> String {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        return "https://\(endpoint)/\(bucket)/\(encodedKey)"
    }
}

// MARK: - AWS Signature V4 helpers

private func sha256Hex(_ string: String) -> String {
    let digest = SHA256.hash(data: Data(string.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}

private func sha256Hex(_ data: Data) -> String {
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}

private func hmacSHA256(key: Data, message: String) -> Data {
    let symmetricKey = SymmetricKey(data: key)
    let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: symmetricKey)
    return Data(mac)
}

private func signingKey(secretKey: String, date: String, region: String, service: String) -> Data {
    let kDate    = hmacSHA256(key: Data(("AWS4" + secretKey).utf8), message: date)
    let kRegion  = hmacSHA256(key: kDate,    message: region)
    let kService = hmacSHA256(key: kRegion,  message: service)
    let kSigning = hmacSHA256(key: kService, message: "aws4_request")
    return kSigning
}

private func isoDate(from date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyyMMdd"
    f.timeZone   = TimeZone(abbreviation: "UTC")
    return f.string(from: date)
}

private func isoDateTime(from date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    f.timeZone   = TimeZone(abbreviation: "UTC")
    return f.string(from: date)
}

/// Build a signed URLRequest for the S3 ListObjectsV2 API.
private func signedListRequest(prefix: String, continuationToken: String? = nil) -> URLRequest {
    let now         = Date()
    let dateStamp   = isoDate(from: now)
    let dateTime    = isoDateTime(from: now)

    var queryItems  = [
        URLQueryItem(name: "list-type", value: "2"),
        URLQueryItem(name: "prefix",    value: prefix),
        URLQueryItem(name: "max-keys",  value: "1000"),
    ]
    if let token = continuationToken {
        queryItems.append(URLQueryItem(name: "continuation-token", value: token))
    }
    // Sort query items for canonical form
    queryItems.sort { $0.name < $1.name }

    var comps = URLComponents()
    comps.scheme = "https"
    comps.host   = "\(LinodeS3.endpoint)"
    comps.path   = "/\(LinodeS3.bucket)"
    comps.queryItems = queryItems
    let url = comps.url!

    let canonicalQueryString = queryItems
        .map { "\($0.name.percentEncoded)=\($0.value?.percentEncoded ?? "")" }
        .joined(separator: "&")

    let emptyBodyHash = sha256Hex(Data())
    let host          = LinodeS3.endpoint
    let canonicalHeaders = "host:\(host)\nx-amz-content-sha256:\(emptyBodyHash)\nx-amz-date:\(dateTime)\n"
    let signedHeaders    = "host;x-amz-content-sha256;x-amz-date"

    let canonicalRequest = [
        "GET",
        "/\(LinodeS3.bucket)",
        canonicalQueryString,
        canonicalHeaders,
        signedHeaders,
        emptyBodyHash,
    ].joined(separator: "\n")

    let credentialScope = "\(dateStamp)/\(LinodeS3.region)/s3/aws4_request"
    let stringToSign = [
        "AWS4-HMAC-SHA256",
        dateTime,
        credentialScope,
        sha256Hex(canonicalRequest),
    ].joined(separator: "\n")

    let sigKey   = signingKey(secretKey: LinodeS3.secretKey, date: dateStamp, region: LinodeS3.region, service: "s3")
    let sigData  = hmacSHA256(key: sigKey, message: stringToSign)
    let sigHex   = sigData.map { String(format: "%02x", $0) }.joined()

    let authHeader = "AWS4-HMAC-SHA256 Credential=\(LinodeS3.accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(sigHex)"

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(host,           forHTTPHeaderField: "Host")
    request.setValue(dateTime,       forHTTPHeaderField: "x-amz-date")
    request.setValue(emptyBodyHash,  forHTTPHeaderField: "x-amz-content-sha256")
    request.setValue(authHeader,     forHTTPHeaderField: "Authorization")
    return request
}

// MARK: - String percent-encoding for S3 canonical form

private extension String {
    var percentEncoded: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}

// MARK: - XML parsing for ListObjectsV2

private final class ListObjectsParser: NSObject, XMLParserDelegate {
    var keys: [String] = []
    var nextContinuationToken: String?
    var isTruncated = false
    private var currentElement = ""
    private var currentValue   = ""

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = name
        currentValue   = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        switch name {
        case "Key":
            let key = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip the prefix-only "folder" entry and non-image files
            if !key.hasSuffix("/"), key.isImageKey {
                keys.append(key)
            }
        case "NextContinuationToken":
            nextContinuationToken = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        case "IsTruncated":
            isTruncated = currentValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        default:
            break
        }
    }
}

private extension String {
    var isImageKey: Bool {
        let lower = lowercased()
        return lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") ||
               lower.hasSuffix(".png") || lower.hasSuffix(".webp") ||
               lower.hasSuffix(".heic")
    }
}

// MARK: - Presigned GET URLs

private extension LinodeS3 {
    /// Builds a Signature V4 presigned GET URL for `key` (path including the `artemis/` prefix).
    /// The signature is embedded in the query string and remains valid for `expiresIn` seconds.
    static func presignedGetURL(for key: String, expiresIn seconds: Int = 3600) -> URL? {
        let now       = Date()
        let dateStamp = isoDate(from: now)
        let dateTime  = isoDateTime(from: now)
        let host      = LinodeS3.endpoint

        // Canonical URI: /<bucket>/<encoded-key-segments...>
        let segments = ([LinodeS3.bucket] + key.split(separator: "/").map(String.init))
            .map { $0.percentEncoded }
        let canonicalURI = "/" + segments.joined(separator: "/")

        let credentialScope = "\(dateStamp)/\(LinodeS3.region)/s3/aws4_request"
        let credential      = "\(LinodeS3.accessKey)/\(credentialScope)"

        var queryItems = [
            URLQueryItem(name: "X-Amz-Algorithm",     value: "AWS4-HMAC-SHA256"),
            URLQueryItem(name: "X-Amz-Credential",    value: credential),
            URLQueryItem(name: "X-Amz-Date",          value: dateTime),
            URLQueryItem(name: "X-Amz-Expires",       value: "\(seconds)"),
            URLQueryItem(name: "X-Amz-SignedHeaders", value: "host"),
        ]
        queryItems.sort { $0.name < $1.name }

        let canonicalQueryString = queryItems
            .map { "\($0.name.percentEncoded)=\($0.value?.percentEncoded ?? "")" }
            .joined(separator: "&")

        let canonicalHeaders = "host:\(host)\n"
        let signedHeaders    = "host"
        let payloadHash      = "UNSIGNED-PAYLOAD"

        let canonicalRequest = [
            "GET",
            canonicalURI,
            canonicalQueryString,
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")

        let stringToSign = [
            "AWS4-HMAC-SHA256",
            dateTime,
            credentialScope,
            sha256Hex(canonicalRequest),
        ].joined(separator: "\n")

        let sigKey  = signingKey(secretKey: LinodeS3.secretKey, date: dateStamp, region: LinodeS3.region, service: "s3")
        let sigData = hmacSHA256(key: sigKey, message: stringToSign)
        let sigHex  = sigData.map { String(format: "%02x", $0) }.joined()

        let finalQuery = canonicalQueryString + "&X-Amz-Signature=\(sigHex)"
        return URL(string: "https://\(host)\(canonicalURI)?\(finalQuery)")
    }
}

// MARK: - PhotoService

enum PhotoServiceError: Error {
    case invalidURL
    case xmlParseFailed
}

enum PhotoService {
    /// Returns a fetchable URL for an image. If the URL points at our Linode bucket we sign it;
    /// other hosts pass through unchanged. The unsigned `urlString` stays the stable cache key
    /// in `ImageLoader` — only the URL that hits the wire is signed.
    ///
    /// `async` so it can be safely awaited across actor boundaries (the helpers it calls
    /// inherit MainActor isolation under the project's default-isolation setting).
    static func signedURL(forPublicURL urlString: String) async -> URL? {
        let publicPrefix = "https://\(LinodeS3.endpoint)/\(LinodeS3.bucket)/"
        if urlString.hasPrefix(publicPrefix) {
            let encodedKey = String(urlString.dropFirst(publicPrefix.count))
            let rawKey = encodedKey.removingPercentEncoding ?? encodedKey
            let signed = LinodeS3.presignedGetURL(for: rawKey)
            #if DEBUG
            if signed == nil {
                print("[PhotoService] failed to sign key: \(rawKey)")
            }
            #endif
            return signed
        }
        return URL(string: urlString)
    }

    static func fetchPhotos() async throws -> [Photo] {
        var allKeys: [String] = []
        var continuationToken: String? = nil

        // The bucket is publicly listable, so we skip signing the LIST call.
        // Only object GETs need Signature V4 (handled in `signedURL(forPublicURL:)`).
        repeat {
            var comps = URLComponents()
            comps.scheme = "https"
            comps.host   = LinodeS3.endpoint
            comps.path   = "/\(LinodeS3.bucket)"
            var query: [URLQueryItem] = [
                URLQueryItem(name: "list-type", value: "2"),
                URLQueryItem(name: "prefix",    value: LinodeS3.prefix),
                URLQueryItem(name: "max-keys",  value: "1000"),
            ]
            if let token = continuationToken {
                query.append(URLQueryItem(name: "continuation-token", value: token))
            }
            comps.queryItems = query
            guard let url = comps.url else { throw PhotoServiceError.invalidURL }

            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                #if DEBUG
                print("[PhotoService] LIST HTTP \(http.statusCode) for \(url.absoluteString)")
                #endif
                throw PhotoServiceError.xmlParseFailed
            }

            let xmlParser = XMLParser(data: data)
            let delegate  = ListObjectsParser()
            xmlParser.delegate = delegate
            guard xmlParser.parse() else { throw PhotoServiceError.xmlParseFailed }

            allKeys.append(contentsOf: delegate.keys)
            continuationToken = delegate.isTruncated ? delegate.nextContinuationToken : nil
        } while continuationToken != nil

        #if DEBUG
        print("[PhotoService] LIST returned \(allKeys.count) image keys; first: \(allKeys.first ?? "<none>")")
        #endif

        return allKeys.enumerated().map { index, key in
            let fileName  = URL(fileURLWithPath: key).deletingPathExtension().lastPathComponent
            let title     = fileName
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            return Photo(
                remoteID:  key,
                remoteURL: LinodeS3.publicURL(for: key),
                title:     title.isEmpty ? "Photo \(index + 1)" : title,
                caption:   "",
                mission:   "Artemis"
            )
        }
    }
}

// MARK: - PhotoCatalog

@MainActor
enum PhotoCatalog {
    /// Throws on failure so callers can surface a real error to the UI rather than
    /// papering over it with sample placeholders.
    static func refresh(modelContext: ModelContext) async throws {
        let fresh    = try await PhotoService.fetchPhotos()
        let existing = try modelContext.fetch(FetchDescriptor<Photo>())
        let existingIDs = Set(existing.map { $0.remoteID })
        var inserted = 0
        for photo in fresh where !existingIDs.contains(photo.remoteID) {
            modelContext.insert(photo)
            inserted += 1
        }
        try modelContext.save()
        #if DEBUG
        print("[PhotoCatalog] refresh: fetched \(fresh.count), inserted \(inserted)")
        #endif
    }

    /// Removes any leftover NASA sample seeds that earlier builds may have inserted
    /// while the Linode connection wasn't yet working.
    static func purgeLegacySamples(modelContext: ModelContext) {
        do {
            let all = try modelContext.fetch(FetchDescriptor<Photo>())
            var removed = 0
            for photo in all where photo.remoteID.hasPrefix("sample-") {
                modelContext.delete(photo)
                removed += 1
            }
            if removed > 0 {
                try modelContext.save()
                #if DEBUG
                print("[PhotoCatalog] purged \(removed) legacy sample photos")
                #endif
            }
        } catch {
            #if DEBUG
            print("[PhotoCatalog] purgeLegacySamples failed: \(error.localizedDescription)")
            #endif
        }
    }
}
