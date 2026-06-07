//
//  ImageLoader.swift
//  MoonPeek
//

import UIKit

actor ImageLoader {
    static let shared = ImageLoader()

    private let memoryCache = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    private var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("MoonPeekImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func image(for urlString: String) async -> UIImage? {
        if let cached = memoryCache.object(forKey: urlString as NSString) {
            return cached
        }
        if let task = inFlight[urlString] {
            return await task.value
        }
        let task = Task<UIImage?, Never> { [urlString] in
            if let disk = self.loadFromDisk(key: urlString) {
                self.memoryCache.setObject(disk, forKey: urlString as NSString)
                return disk
            }
            guard let url = URL(string: urlString) else { return nil }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let img = UIImage(data: data) else { return nil }
                self.memoryCache.setObject(img, forKey: urlString as NSString)
                self.saveToDisk(data: data, key: urlString)
                return img
            } catch {
                return nil
            }
        }
        inFlight[urlString] = task
        let result = await task.value
        inFlight[urlString] = nil
        return result
    }

    func cachedImage(for urlString: String) -> UIImage? {
        memoryCache.object(forKey: urlString as NSString)
    }

    /// Clears in-memory and on-disk caches. Returns the bytes that were freed from disk.
    @discardableResult
    func clearCache() -> Int64 {
        memoryCache.removeAllObjects()
        let dir = cacheDirectory
        let fm = FileManager.default
        var freed: Int64 = 0
        if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    freed += Int64(size)
                }
                try? fm.removeItem(at: file)
            }
        }
        return freed
    }

    /// Computes the on-disk size of the image cache in bytes.
    func diskCacheSize() -> Int64 {
        let fm = FileManager.default
        var total: Int64 = 0
        if let files = try? fm.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    total += Int64(size)
                }
            }
        }
        return total
    }

    private func diskURL(for key: String) -> URL {
        let safe = key.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "") ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent(safe)
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let url = diskURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(data: Data, key: String) {
        try? data.write(to: diskURL(for: key), options: .atomic)
    }
}
