//
//  SearchResultsViewController.swift
//  Stocks
//
//  Created by HieuTong on 04/07/2021.
//

import UIKit

protocol SearchResultsViewControllerDelegate: AnyObject {
    func searchResultsViewControllerDidSelect(searchResult: SearchResult)
}

class SearchResultsViewController: UIViewController {
    
    weak var delegate: SearchResultsViewControllerDelegate?
    
    private var results = [SearchResult]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        // Register a cell
        table.register(SearchResultTableViewCell.self, forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        table.isHidden = true
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func update(with results: [SearchResult]) {
        self.results = results
        tableView.isHidden = false
        tableView.reloadData()
    }
}

extension SearchResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        HapticsManager.shared.vibrateForSelection()

        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath)
        let model = results[indexPath.row]
        
        cell.textLabel?.text = model.symbol
        cell.detailTextLabel?.text = model.description
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = results[indexPath.row]
        delegate?.searchResultsViewControllerDidSelect(searchResult: model)
    }
}
