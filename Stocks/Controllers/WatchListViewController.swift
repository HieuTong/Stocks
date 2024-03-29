//
//  ViewController.swift
//  Stocks
//
//  Created by HieuTong on 04/07/2021.
//

import FloatingPanel
import UIKit

class WatchListViewController: UIViewController {
    private var searchTimer: Timer?

    ///Model
    private var watchListMap: [String: [CandleStick]] = [:]

    ///ViewModels
    private var viewModels: [WatchListTableViewCell.ViewModel] = []

    static var maxChangeWidth: CGFloat = 0

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self, forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    
    private var observer: NSObjectProtocol?
    
    // MARK: - Private
    private func setUpObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: .didAddToWatchList,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.viewModels.removeAll()
                self?.fetchWatchlistData()
            })
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        setupSearchController()
        setupTableView()
        fetchWatchlistData()
        setupFloatingPanel()
        setupTitleView()
        setUpObserver()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    // MARK: - Private

    private func fetchWatchlistData() {
        let symbols = PersistenceManager.shared.watchlist
        
        createPlaceholderViewModels()
        
        let group = DispatchGroup()

        for symbol in symbols where watchListMap[symbol] == nil {
            group.enter()
            APICaller.shared.marketData(for: symbol) { [weak self] result in
                defer {
                    group.leave()
                }

                switch result {
                case .success(let data):
                    let candleSticks = data.candleSticks
                    self?.watchListMap[symbol] = candleSticks
                case .failure(let error):
                    print(error)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.createViewModels()
            self?.tableView.reloadData()
        }
    }
    
    private func createPlaceholderViewModels() {
        let symbols = PersistenceManager.shared.watchlist
        symbols.forEach { item in
            viewModels.append(
                .init(symbol: item,
                      companyName: UserDefaults.standard.string(forKey: item) ?? "Company",
                      price: "0.00",
                      changeColor: .systemGreen,
                      changePercentage: "0.00",
                      chartViewModel: .init(data: [], showLegend: false, showAxisBool: false, fillColor: .clear))
            )
        }
        
        self.viewModels = viewModels.sorted(by: { $0.symbol < $1.symbol })
        tableView.reloadData()
    }

    private func createViewModels() {
        var viewModels = [WatchListTableViewCell.ViewModel]()
        for (symbol, candleSticks) in watchListMap {
            let changePercentage = candleSticks.getPercentage()
            viewModels.append(.init(
                                symbol: symbol,
                                companyName: UserDefaults.standard.string(forKey: symbol) ?? "Company",
                                price: getLatestClosingPrice(data: candleSticks),
                                changeColor: changePercentage < 0 ? .systemRed : .systemGreen,
                                changePercentage: .percentage(from: changePercentage),
                                chartViewModel: .init(
                                    data: candleSticks.reversed().map{ $0.close },
                                    showLegend: false,
                                    showAxisBool: false,
                                    fillColor: changePercentage < 0 ? .systemRed : .systemGreen)
                                )
            )
        }

        print("\n\n \(viewModels) \n")

        self.viewModels = viewModels.sorted(by: { $0.symbol < $1.symbol })
    }

    private func getLatestClosingPrice(data: [CandleStick]) -> String {
        guard let closingPrice = data.first?.close else {
            return ""
        }

        return .formatted(from: closingPrice)
    }
    
    private func setupSearchController() {
        let resultVC = SearchResultsViewController()
        resultVC.delegate = self
        let searchVC = UISearchController(searchResultsController: resultVC)
        searchVC.searchResultsUpdater = self
        navigationItem.searchController = searchVC
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupFloatingPanel() {
        let vc = NewsViewController(type: .topStories)
        let panel = FloatingPanelController(delegate: self)
        panel.surfaceView.backgroundColor = .secondarySystemBackground
        panel.set(contentViewController: vc)
        panel.addPanel(toParent: self)
        panel.track(scrollView: vc.tableView)
    }
    
    private func setupTitleView() {
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: navigationController?.navigationBar.height ?? 100))
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: titleView.width - 20, height: titleView.height))
        label.text = "Stocks"
        label.font = .systemFont(ofSize: 32, weight: .medium)
        titleView.addSubview(label)
        
        navigationItem.titleView = titleView
    }
}

extension WatchListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              let resultsVC = searchController.searchResultsController as? SearchResultsViewController,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Reset timer
        searchTimer?.invalidate()
        
        // Kick off new timer
        // Optimize to reduce number of searches for when user stops typing
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in
            // Call API to search
            APICaller.shared.search(query: query) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        resultsVC.update(with: response.result)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        resultsVC.update(with: [])
                    }
                    print(error)
                }
            }
        })
    }
}

extension WatchListViewController: SearchResultsViewControllerDelegate {
    func searchResultsViewControllerDidSelect(searchResult: SearchResult) {
        
        HapticsManager.shared.vibrateForSelection()
        
        // Present stock details for given selection
        navigationItem.searchController?.searchBar.resignFirstResponder()
        let vc = StockDetailsViewController(
            symbol: searchResult.symbol,
            companyName: searchResult.description,
            candleStickData: []
        )
        let navVC = UINavigationController(rootViewController: vc)
        vc.title = searchResult.description
        DispatchQueue.main.async { [weak self] in
            self?.present(navVC, animated: true)
        }
    }
}

extension WatchListViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        navigationItem.titleView?.isHidden = fpc.state == .full
    }
}

extension WatchListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        HapticsManager.shared.vibrateForSelection()
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WatchListTableViewCell.identifier, for: indexPath) as? WatchListTableViewCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        cell.configure(indexPath: indexPath, with: viewModels[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return WatchListTableViewCell.preferredHeight
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.beginUpdates()
                // Update persistence
                PersistenceManager.shared.removeFromWatchlist(symbol: self?.viewModels[indexPath.row].symbol ?? "") { [weak self] in
                    // Update viewModels
                    self?.viewModels.remove(at: indexPath.row)

                    //Delete row
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                self?.tableView.endUpdates()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Open the detail for selection
        let model = viewModels[indexPath.row]
        let vc = StockDetailsViewController(symbol: model.symbol, companyName: model.companyName, candleStickData: watchListMap[model.symbol] ?? [])
        vc.title = model.companyName
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
}

extension WatchListViewController: WatchListTableViewCellDelegate {
    func didUpdateMaxWidth(indexPath: IndexPath) {
        tableView.reloadData()
    }
}
