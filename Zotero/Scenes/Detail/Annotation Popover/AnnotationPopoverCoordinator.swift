//
//  AnnotationPopoverCoordinator.swift
//  Zotero
//
//  Created by Michal Rentka on 20.11.2020.
//  Copyright © 2020 Corporation for Digital Scholarship. All rights reserved.
//

import UIKit

import RxSwift

protocol AnnotationPopoverAnnotationCoordinatorDelegate: class {
    func showEdit(annotation: Annotation, saveAction: @escaping AnnotationEditSaveAction, deleteAction: @escaping AnnotationEditDeleteAction)
    func showTagPicker(libraryId: LibraryIdentifier, selected: Set<String>, picked: @escaping ([Tag]) -> Void)
}

protocol AnnotationEditCoordinatorDelegate: class {
    func dismiss()
    func back()
}

class AnnotationPopoverCoordinator: NSObject, Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator]

    unowned let navigationController: UINavigationController
    private unowned let viewModel: ViewModel<PDFReaderActionHandler>
    private unowned let controllers: Controllers
    private let disposeBag: DisposeBag

    init(navigationController: UINavigationController, controllers: Controllers, viewModel: ViewModel<PDFReaderActionHandler>) {
        self.navigationController = navigationController
        self.controllers = controllers
        self.viewModel = viewModel
        self.childCoordinators = []
        self.disposeBag = DisposeBag()

        super.init()

        navigationController.delegate = self
    }

    func start(animated: Bool) {
        let controller = AnnotationViewController(viewModel: self.viewModel, attributedStringConverter: self.controllers.htmlAttributedStringConverter)
        controller.coordinatorDelegate = self
        self.navigationController.setViewControllers([controller], animated: animated)
    }
}

extension AnnotationPopoverCoordinator: AnnotationPopoverAnnotationCoordinatorDelegate {
    func showEdit(annotation: Annotation, saveAction: @escaping AnnotationEditSaveAction, deleteAction: @escaping AnnotationEditDeleteAction) {
        let state = AnnotationEditState(annotation: annotation)
        let handler = AnnotationEditActionHandler()
        let viewModel = ViewModel(initialState: state, handler: handler)
        let controller = AnnotationEditViewController(viewModel: viewModel, saveAction: saveAction, deleteAction: deleteAction)
        controller.coordinatorDelegate = self
        controller.preferredContentSize = AnnotationPopoverLayout.editPreferredSize
        self.navigationController.pushViewController(controller, animated: true)
    }

    func showTagPicker(libraryId: LibraryIdentifier, selected: Set<String>, picked: @escaping ([Tag]) -> Void) {
        guard let dbStorage = self.controllers.userControllers?.dbStorage else { return }

        let state = TagPickerState(libraryId: libraryId, selectedTags: selected)
        let handler = TagPickerActionHandler(dbStorage: dbStorage)
        let viewModel = ViewModel(initialState: state, handler: handler)
        let tagController = TagPickerViewController(viewModel: viewModel, saveAction: picked)
        tagController.preferredContentSize = AnnotationPopoverLayout.tagPickerPreferredSize
        self.navigationController.pushViewController(tagController, animated: true)
    }
}

extension AnnotationPopoverCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let navbarHidden = viewController is AnnotationViewController
        navigationController.setNavigationBarHidden(navbarHidden, animated: animated)
        navigationController.preferredContentSize = viewController.preferredContentSize
    }
}

extension AnnotationPopoverCoordinator: AnnotationEditCoordinatorDelegate {
    func back() {
        self.navigationController.popViewController(animated: true)
    }

    func dismiss() {
        self.navigationController.dismiss(animated: true, completion: nil)
    }
}
