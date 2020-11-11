//
//  AnnotationsViewController.swift
//  Zotero
//
//  Created by Michal Rentka on 24/04/2020.
//  Copyright © 2020 Corporation for Digital Scholarship. All rights reserved.
//

#if PDFENABLED

import UIKit

import CocoaLumberjackSwift
import PSPDFKit
import PSPDFKitUI
import RxSwift

typealias AnnotationsViewControllerAction = (AnnotationView.Action, Annotation, UIButton) -> Void

class AnnotationsViewController: UIViewController {
    private static let cellId = "AnnotationCell"
    private let viewModel: ViewModel<PDFReaderActionHandler>
    private let disposeBag: DisposeBag

    private weak var tableView: UITableView!
    private var searchController: UISearchController!
    var performAction: AnnotationsViewControllerAction?

    // MARK: - Lifecycle

    init(viewModel: ViewModel<PDFReaderActionHandler>) {
        self.viewModel = viewModel
        self.disposeBag = DisposeBag()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.definesPresentationContext = true
        self.view.backgroundColor = .systemGray6
        self.setupTableView()
        self.setupSearchController()

        self.viewModel.stateObservable
                      .observeOn(MainScheduler.instance)
                      .subscribe(onNext: { [weak self] state in
                          self?.update(state: state)
                      })
                      .disposed(by: self.disposeBag)

        self.viewModel.process(action: .startObservingAnnotationChanges)
    }

    deinit {
        DDLogInfo("AnnotationsViewController deinitialized")
    }

    // MARK: - Actions

    private func update(state: PDFReaderState) {
        self.reloadIfNeeded(from: state) {
            if let keys = state.loadedPreviewImageAnnotationKeys {
                self.updatePreviewsIfVisible(for: keys)
            }

            if let indexPath = state.focusSidebarIndexPath {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            }
        }
    }

    /// Updates `UIImage` of `SquareAnnotation` preview if the cell is currently on screen.
    /// - parameter keys: Set of keys to update.
    private func updatePreviewsIfVisible(for keys: Set<String>) {
        let cells = self.tableView.visibleCells.compactMap({ $0 as? AnnotationCell }).filter({ keys.contains($0.key) })

        for cell in cells {
            let image = self.viewModel.state.previewCache.object(forKey: (cell.key as NSString))
            cell.updatePreview(image: image)
        }
    }

    /// Reloads tableView if needed, based on new state. Calls completion either when reloading finished or when there was no reload.
    /// - parameter state: Current state.
    /// - parameter completion: Called after reload was performed or even if there was no reload.
    private func reloadIfNeeded(from state: PDFReaderState, completion: @escaping () -> Void) {
        guard state.changes.contains(.annotations) || state.changes.contains(.darkMode) else {
            completion()
            return
        }

        if state.changes.contains(.darkMode) ||
           (state.insertedAnnotationIndexPaths == nil &&
            state.removedAnnotationIndexPaths == nil &&
            state.updatedAnnotationIndexPaths == nil) {
            self.tableView.reloadData()
            completion()
            return
        }

        self.tableView.performBatchUpdates {
            if let indexPaths = state.insertedAnnotationIndexPaths {
                self.tableView.insertRows(at: indexPaths, with: .automatic)
            }
            if let indexPaths = state.removedAnnotationIndexPaths {
                self.tableView.deleteRows(at: indexPaths, with: .automatic)
            }
            if let indexPaths = state.updatedAnnotationIndexPaths {
                self.tableView.reloadRows(at: indexPaths, with: .none)
            }
        } completion: { _ in
            completion()
        }
    }

    // MARK: - Setups

    private func setupTableView() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemGray6

        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundView = backgroundView
        tableView.register(AnnotationCell.self, forCellReuseIdentifier: AnnotationsViewController.cellId)

        self.view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])

        self.tableView = tableView
    }

    private func setupSearchController() {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.searchBarStyle = .minimal
        controller.searchBar.placeholder = L10n.Pdf.AnnotationsSidebar.searchTitle
        controller.searchBar.barTintColor = .systemGray6
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false

        var frame = controller.searchBar.frame
        frame.size.height = 52
        controller.searchBar.frame = frame

        self.tableView.tableHeaderView = controller.searchBar
        self.searchController = controller

        controller.searchBar.rx.text.observeOn(MainScheduler.instance)
                                    .debounce(.milliseconds(150), scheduler: MainScheduler.instance)
                                    .subscribe(onNext: { [weak self] text in
                                        self?.viewModel.process(action: .searchAnnotations(text ?? ""))
                                    })
                                    .disposed(by: self.disposeBag)
    }
}

extension AnnotationsViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Int(self.viewModel.state.document.pageCount)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.state.annotations[section]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let keys = indexPaths.compactMap({ self.viewModel.state.annotations[$0.section]?[$0.row] }).map({ $0.key })
        let isDark = self.traitCollection.userInterfaceStyle == .dark
        self.viewModel.process(action: .requestPreviews(keys: keys, notify: false, isDark: isDark))
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AnnotationsViewController.cellId, for: indexPath)
        cell.contentView.backgroundColor = self.view.backgroundColor

        if let annotation = self.viewModel.state.annotations[indexPath.section]?[indexPath.row],
           let cell = cell as? AnnotationCell {
            let comment = self.viewModel.state.comments[annotation.key]
            let selected = annotation.key == self.viewModel.state.selectedAnnotation?.key
            let preview: UIImage?

            if annotation.type != .image {
                preview = nil
            } else {
                preview = self.viewModel.state.previewCache.object(forKey: (annotation.key as NSString))

                if preview == nil {
                    let isDark = self.traitCollection.userInterfaceStyle == .dark
                    self.viewModel.process(action: .requestPreviews(keys: [annotation.key], notify: true, isDark: isDark))
                }
            }

            cell.setup(with: annotation, attributedComment: comment, preview: preview,
                       selected: selected, availableWidth: PDFReaderLayout.sidebarWidth,
                       hasWritePermission: self.viewModel.state.library.metadataEditable)
            cell.performAction = { [weak self] action, sender in
                self?.performAction?(action, annotation, sender)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let annotation = self.viewModel.state.annotations[indexPath.section]?[indexPath.row] {
            self.viewModel.process(action: .selectAnnotation(annotation))
        }
    }
}

#endif
