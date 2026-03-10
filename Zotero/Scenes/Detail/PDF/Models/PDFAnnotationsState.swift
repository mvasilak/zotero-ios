//
//  PDFAnnotationsState.swift
//  Zotero
//
//  Created by Miltiadis Vasilakis on 10/03/2026.
//  Copyright © 2026 Corporation for Digital Scholarship. All rights reserved.
//

import UIKit

import PSPDFKit
import RealmSwift

struct PDFAnnotationsState: ViewModelState, ReaderState {
    typealias AnnotationKey = PDFReaderAnnotationKey

    struct Changes: OptionSet {
        typealias RawValue = UInt16

        let rawValue: UInt16

        static let annotations = Changes(rawValue: 1 << 0)
        static let selection = Changes(rawValue: 1 << 1)
        static let activeComment = Changes(rawValue: 1 << 2)
        static let sidebarEditing = Changes(rawValue: 1 << 3)
        static let sidebarEditingSelection = Changes(rawValue: 1 << 4)
        static let filter = Changes(rawValue: 1 << 5)
        static let library = Changes(rawValue: 1 << 6)
        static let appearance = Changes(rawValue: 1 << 7)
    }

    let key: String
    let document: PSPDFKit.Document
    let userId: Int
    let username: String

    var library: Library
    var settings: PDFSettings
    var interfaceStyle: UIUserInterfaceStyle
    var sortedKeys: [AnnotationKey]
    var annotationPages: IndexSet
    var snapshotKeys: [AnnotationKey]?
    var updatedAnnotationKeys: [AnnotationKey]?
    var selectedAnnotationKey: AnnotationKey?
    var selectedAnnotationCommentActive: Bool
    var focusSidebarKey: AnnotationKey?
    var sidebarEditingEnabled: Bool
    var deletionEnabled: Bool
    var mergingEnabled: Bool
    var filter: AnnotationsFilter?
    var databaseAnnotations: Results<RItem>?
    var documentAnnotations: Results<RDocumentAnnotation>?
    var documentAnnotationUniqueBaseColors: [String]
    var changes: Changes
    var outgoingAction: PDFAnnotationsOutputAction?

    init(
        key: String,
        document: PSPDFKit.Document,
        userId: Int,
        username: String,
        library: Library,
        settings: PDFSettings,
        interfaceStyle: UIUserInterfaceStyle,
        sortedKeys: [AnnotationKey] = [],
        annotationPages: IndexSet = IndexSet(),
        snapshotKeys: [AnnotationKey]? = nil,
        updatedAnnotationKeys: [AnnotationKey]? = nil,
        selectedAnnotationKey: AnnotationKey? = nil,
        selectedAnnotationCommentActive: Bool = false,
        focusSidebarKey: AnnotationKey? = nil,
        sidebarEditingEnabled: Bool = false,
        deletionEnabled: Bool = false,
        mergingEnabled: Bool = false,
        filter: AnnotationsFilter? = nil,
        databaseAnnotations: Results<RItem>? = nil,
        documentAnnotations: Results<RDocumentAnnotation>? = nil,
        documentAnnotationUniqueBaseColors: [String] = [],
        changes: Changes = []
    ) {
        self.key = key
        self.document = document
        self.userId = userId
        self.username = username
        self.library = library
        self.settings = settings
        self.interfaceStyle = interfaceStyle
        self.sortedKeys = sortedKeys
        self.annotationPages = annotationPages
        self.snapshotKeys = snapshotKeys
        self.updatedAnnotationKeys = updatedAnnotationKeys
        self.selectedAnnotationKey = selectedAnnotationKey
        self.selectedAnnotationCommentActive = selectedAnnotationCommentActive
        self.focusSidebarKey = focusSidebarKey
        self.sidebarEditingEnabled = sidebarEditingEnabled
        self.deletionEnabled = deletionEnabled
        self.mergingEnabled = mergingEnabled
        self.filter = filter
        self.databaseAnnotations = databaseAnnotations
        self.documentAnnotations = documentAnnotations
        self.documentAnnotationUniqueBaseColors = documentAnnotationUniqueBaseColors
        self.changes = changes
        self.outgoingAction = nil
    }

    mutating func cleanup() {
        changes = []
        updatedAnnotationKeys = nil
        focusSidebarKey = nil
        outgoingAction = nil
    }

    var selectedReaderAnnotation: ReaderAnnotation? {
        guard let selectedAnnotationKey else { return nil }
        return annotation(for: selectedAnnotationKey)
    }

    func annotation(for key: AnnotationKey) -> PDFAnnotation? {
        switch key.type {
        case .database:
            return databaseAnnotations?.filter(.key(key.key)).first.flatMap({ PDFDatabaseAnnotation(item: $0) })

        case .document:
            return documentAnnotations?.filter(.key(key.key)).first.flatMap({ PDFDocumentAnnotation(annotation: $0, displayName: displayName, username: username) })
        }
    }
}
