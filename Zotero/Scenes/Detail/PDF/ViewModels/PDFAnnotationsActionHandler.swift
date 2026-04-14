//
//  PDFAnnotationsActionHandler.swift
//  Zotero
//
//  Created by Miltiadis Vasilakis on 10/03/2026.
//  Copyright © 2026 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

final class PDFAnnotationsActionHandler: ViewModelActionHandler {
    typealias State = PDFAnnotationsState
    typealias Action = PDFAnnotationsAction

    func process(action: PDFAnnotationsAction, in viewModel: ViewModel<PDFAnnotationsActionHandler>) {
        switch action {
        case .setAnnotations(let sortedKeys, let annotationPages, let snapshotKeys, let updatedAnnotationKeys, let databaseAnnotations, let documentAnnotations, let documentAnnotationUniqueBaseColors):
            update(viewModel: viewModel) { state in
                state.sortedKeys = sortedKeys
                state.annotationPages = annotationPages
                state.snapshotKeys = snapshotKeys
                state.updatedAnnotationKeys = updatedAnnotationKeys
                state.databaseAnnotations = databaseAnnotations
                state.documentAnnotations = documentAnnotations
                state.documentAnnotationUniqueBaseColors = documentAnnotationUniqueBaseColors
                state.changes = .annotations

                // If sidebar editing is enabled and there are no results, disable it.
                if state.sidebarEditingEnabled, (state.snapshotKeys ?? state.sortedKeys).isEmpty {
                    state.sidebarEditingEnabled = false
                    state.changes.insert(.sidebarEditing)
                }
            }

        case .setSelection(let selectedAnnotationKey, let focusSidebarKey, let updatedAnnotationKeys):
            update(viewModel: viewModel) { state in
                let selectionChanged = state.selectedAnnotationKey != selectedAnnotationKey
                state.selectedAnnotationKey = selectedAnnotationKey
                state.focusSidebarKey = focusSidebarKey
                state.updatedAnnotationKeys = updatedAnnotationKeys
                state.changes = .selection
                if selectionChanged && state.selectedAnnotationCommentActive {
                    state.selectedAnnotationCommentActive = false
                    state.changes.insert(.activeComment)
                }
            }

        case .setCommentActive(let isActive):
            update(viewModel: viewModel) { state in
                state.selectedAnnotationCommentActive = isActive
                state.changes = .activeComment
            }

        case .setSidebarEditingEnabled(let enabled):
            update(viewModel: viewModel) { state in
                state.sidebarEditingEnabled = enabled
                state.changes = .sidebarEditing
            }

        case .setSidebarEditingSelection(let deletionEnabled, let mergingEnabled):
            update(viewModel: viewModel) { state in
                state.deletionEnabled = deletionEnabled
                state.mergingEnabled = mergingEnabled
                state.changes = .sidebarEditingSelection
            }

        case .setFilter(let filter):
            update(viewModel: viewModel) { state in
                state.filter = filter
                state.changes = .filter
            }

        case .setLibrary(let library):
            update(viewModel: viewModel) { state in
                state.library = library
                state.changes = .library
            }

        case .setAppearance(let settings, let interfaceStyle):
            update(viewModel: viewModel) { state in
                state.settings = settings
                state.interfaceStyle = interfaceStyle
                state.changes = .appearance
            }

        case .setSettings(let settings):
            update(viewModel: viewModel) { state in
                state.settings = settings
            }

        case .send(let outgoingAction):
            update(viewModel: viewModel) { state in
                state.outgoingAction = outgoingAction
            }
        }
    }
}
