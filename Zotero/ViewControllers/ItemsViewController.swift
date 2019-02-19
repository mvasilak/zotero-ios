//
//  ItemsViewController.swift
//  Zotero
//
//  Created by Michal Rentka on 04/02/2019.
//  Copyright © 2019 Corporation for Digital Scholarship. All rights reserved.
//

import UIKit

import RxSwift
import RealmSwift

class ItemsViewController: UIViewController {
    // Outlets
    @IBOutlet private weak var tableView: UITableView!
    // Constants
    private let store: ItemsStore
    private let disposeBag: DisposeBag

    // MARK: - Lifecycle

    init(store: ItemsStore) {
        self.store = store
        self.disposeBag = DisposeBag()
        super.init(nibName: "ItemsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationItem.title = self.store.state.value.title
        }
        self.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        self.navigationItem.leftItemsSupplementBackButton = true
        self.setupTableView()

        self.store.state.asObservable()
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] state in
                            self?.tableView.reloadData()
                        })
                        .disposed(by: self.disposeBag)

        self.store.handle(action: .load)
    }

    // MARK: - Actions

    private func showItem(at index: Int) {
        guard let items = self.store.state.value.items, index < items.count else { return }
        let store = ItemDetailStore(initialState: ItemDetailState(item: items[index]), dbStorage: self.store.dbStorage,
                                    itemFieldsController: self.store.itemFieldsController)
        let controller = ItemDetailViewController(store: store)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Setups

    private func setupTableView() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
}

extension ItemsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.store.state.value.items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if let items = self.store.state.value.items, indexPath.row < items.count {
            let item = items[indexPath.row]
            cell.textLabel?.text = item.title
        }

        return cell
    }
}

extension ItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.showItem(at: indexPath.row)
    }
}
