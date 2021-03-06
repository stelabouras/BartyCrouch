//
//  Created by Cihat Gündüz on 14.02.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//

import Foundation

/// Searchs for `.strings` files given a base internationalized Storyboard.
public class StringsFilesSearch {
    // MARK: - Stored Type Properties
    public static let shared = StringsFilesSearch()

    fileprivate static let blacklistedStringFileNames: Set<String> = ["InfoPlist.strings"]

    // MARK: - Instance Methods
    public func findAllIBFiles(within baseDirectoryPath: String, withLocale locale: String = "Base") -> [String] {
        // swiftlint:disable:next force_try
        let ibFileRegex = try! NSRegularExpression(pattern: "^(.*\\/)?\(locale).lproj.*\\.(storyboard|xib)\\z", options: .caseInsensitive)
        return self.findAllFilePaths(inDirectoryPath: baseDirectoryPath, matching: ibFileRegex)
    }

    public func findAllStringsFiles(within baseDirectoryPath: String, withLocale locale: String) -> [String] {
        // swiftlint:disable:next force_try
        let stringsFileRegex = try! NSRegularExpression(pattern: "^(.*\\/)?\(locale).lproj.*\\.strings\\z", options: .caseInsensitive)
        return self.findAllFilePaths(inDirectoryPath: baseDirectoryPath, matching: stringsFileRegex)
    }

    public func findAllStringsFiles(within baseDirectoryPath: String, withFileName fileName: String) -> [String] {
        // swiftlint:disable:next force_try
        let stringsFileRegex = try! NSRegularExpression(pattern: ".*\\.lproj/\(fileName)\\.strings\\z", options: .caseInsensitive)
        return self.findAllFilePaths(inDirectoryPath: baseDirectoryPath, matching: stringsFileRegex)
    }

    public func findAllStringsFiles(within baseDirectoryPath: String) -> [String] {
        // swiftlint:disable:next force_try
        let stringsFileRegex = try! NSRegularExpression(pattern: ".*\\.lproj/.+\\.strings\\z", options: .caseInsensitive)
        return self.findAllFilePaths(inDirectoryPath: baseDirectoryPath, matching: stringsFileRegex)
    }

    public func findAllLocalesForStringsFile(sourceFilePath: String) -> [String] {
        var pathComponents = sourceFilePath.components(separatedBy: "/")
        let storyboardName: String = {
            var fileNameComponents = pathComponents.last!.components(separatedBy: ".")
            fileNameComponents.removeLast()
            return fileNameComponents.joined(separator: ".")
        }()

        pathComponents.removeLast() // Remove last path component from folder/base.lproj/some.storyboard
        pathComponents.removeLast() // Remove last path component from folder/base.lproj

        let folderWithLanguageSubfoldersPath = pathComponents.joined(separator: "/")

        do {
            let filesInDirectory = try FileManager.default.contentsOfDirectory(atPath: folderWithLanguageSubfoldersPath)
            let languageDirPaths = filesInDirectory.filter { $0.range(of: ".lproj") != nil && $0 != "Base.lproj" }
            return languageDirPaths.map { [folderWithLanguageSubfoldersPath, $0, "\(storyboardName).strings"].joined(separator: "/") }
        } catch {
            return []
        }
    }

    func findAllFilePaths(inDirectoryPath baseDirectoryPath: String, matching regularExpression: NSRegularExpression) -> [String] {
        let baseDirectoryURL = URL(fileURLWithPath: baseDirectoryPath)
        guard let enumerator = FileManager.default.enumerator(at: baseDirectoryURL, includingPropertiesForKeys: nil) else { return [] }

        var filePaths = [String]()
        let dirsToIgnore = Set([".git", "Carthage", "Pods", "build", "docs"])
        let baseDirectoryAbsolutePath = baseDirectoryURL.path

        for case let url as URL in enumerator {
            if dirsToIgnore.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            let absolutePath = url.path
            let searchRange = NSRange(location: baseDirectoryAbsolutePath.count, length: absolutePath.count - baseDirectoryAbsolutePath.count)
            if regularExpression.firstMatch(in: absolutePath, options: [], range: searchRange) != nil {
                filePaths.append(absolutePath)
            }
        }

        return filePaths
    }
}
