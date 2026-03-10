//
//  PDFAnnotationsAction.swift
//  Zotero
//
//  Created by Miltiadis Vasilakis on 10/03/2026.
//  Copyright © 2026 Corporation for Digital Scholarship. All rights reserved.
//

import UIKit

import RealmSwift

enum PDFAnnotationsAction {
    case setAnnotations(
        sortedKeys: [PDFReaderAnnotationKey],
        annotationPages: IndexSet,
        snapshotKeys: [PDFReaderAnnotationKey]?,
        updatedAnnotationKeys: [PDFReaderAnnotationKey]?,
        databaseAnnotations: Results<RItem>?,
        documentAnnotations: Results<RDocumentAnnotation>?,
        documentAnnotationUniqueBaseColors: [String]
    )
    case setSelection(
        selectedAnnotationKey: PDFReaderAnnotationKey?,
        selectedAnnotationCommentActive: Bool,
        focusSidebarKey: PDFReaderAnnotationKey?,
        updatedAnnotationKeys: [PDFReaderAnnotationKey]?
    )
    case setCommentActive(Bool)
    case setSidebarEditing(enabled: Bool)
    case setSidebarEditingSelection(deletionEnabled: Bool, mergingEnabled: Bool)
    case setFilter(AnnotationsFilter?)
    case setLibrary(Library)
    case setAppearance(settings: PDFSettings, interfaceStyle: UIUserInterfaceStyle)
    case setSettings(PDFSettings)
    case send(PDFAnnotationsOutputAction)
}

enum PDFAnnotationsOutputAction {
    case setTags(key: String, tags: [Tag])
    case updateAnnotationProperties(
        key: String,
        type: AnnotationType,
        color: String,
        lineWidth: CGFloat,
        fontSize: CGFloat,
        pageLabel: String,
        updateSubsequentLabels: Bool,
        highlightText: NSAttributedString,
        higlightFont: UIFont
    )
    case removeAnnotation(PDFReaderAnnotationKey)
    case setComment(key: String, comment: NSAttributedString)
    case setCommentActive(Bool)
    case changeFilter(AnnotationsFilter?)
    case searchAnnotations(String)
    case mergeSelectedAnnotations
    case removeSelectedAnnotations
    case setSidebarEditingEnabled(Bool)
    case selectAnnotationDuringEditing(PDFReaderAnnotationKey)
    case selectAnnotation(PDFReaderAnnotationKey)
    case deselectAnnotationDuringEditing(PDFReaderAnnotationKey)
}
