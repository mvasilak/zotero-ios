//
//  Attachment.swift
//  Zotero
//
//  Created by Michal Rentka on 02/12/2019.
//  Copyright © 2019 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import CocoaLumberjackSwift

struct Attachment: Identifiable, Equatable {
    enum FileLocation {
        case local, localAndChangedRemotely, remote, remoteMissing
    }

    enum FileLinkType {
        case importedUrl, importedFile, embeddedImage, linkedFile
    }

    enum Kind: Equatable, Hashable {
        case file(filename: String, contentType: String, location: FileLocation, linkType: FileLinkType, compressed: Bool)
        case url(URL)
    }

    let type: Kind
    let title: String
    let key: String
    let libraryId: LibraryIdentifier
    let url: String?
    let dateAdded: Date

    var id: String { return self.key }

    var hasUrl: Bool {
        switch self.type {
        case .url: return true
        case .file: return self.url != nil
        }
    }

    var location: FileLocation? {
        switch self.type {
        case .url: return nil
        case .file(_, _, let location, _, _): return location
        }
    }

    var file: File? {
        switch type {
        case .file(let filename, let contentType, _, _, _):
            return Files.attachmentFile(in: libraryId, key: key, filename: filename, contentType: contentType)

        case .url:
            return nil
        }
    }

    init(type: Kind, title: String, url: String? = nil, dateAdded: Date = Date(), key: String, libraryId: LibraryIdentifier) {
        self.key = key
        self.title = title
        self.libraryId = libraryId
        self.type = type
        self.dateAdded = dateAdded
        self.url = url
    }

    init?(item: RItem, type: Kind) {
        guard let libraryId = item.libraryId else {
            DDLogError("Attachment: library not assigned to item (\(item.key))")
            return nil
        }

        self.libraryId = libraryId
        self.key = item.key
        self.title = item.displayTitle
        self.type = type
        self.dateAdded = item.dateAdded
        self.url = item.fields.first(where: { $0.key == FieldKeys.Item.url })?.value
    }

    func changed(location: FileLocation, condition: (FileLocation) -> Bool) -> Attachment? {
        switch self.type {
        case .file(let filename, let contentType, let oldLocation, let linkType, let compressed) where condition(oldLocation):
            return Attachment(
                type: .file(filename: filename, contentType: contentType, location: location, linkType: linkType, compressed: compressed),
                title: title,
                url: url,
                dateAdded: dateAdded,
                key: key,
                libraryId: libraryId
            )

        case .url, .file:
            return nil
        }
    }

    func changed(location: FileLocation, compressed: Bool?) -> Attachment? {
        switch type {
        case .file(let filename, let contentType, let oldLocation, let linkType, let oldCompressed):
            let compressed = compressed ?? oldCompressed
            if oldLocation == location && oldCompressed == compressed {
                return nil
            }
            return Attachment(
                type: .file(filename: filename, contentType: contentType, location: location, linkType: linkType, compressed: compressed),
                title: title,
                url: url,
                dateAdded: dateAdded,
                key: key,
                libraryId: libraryId
            )

        case .url:
            return nil
        }
    }
}

extension Attachment: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
        hasher.combine(self.libraryId)
        hasher.combine(self.title)
    }
}
