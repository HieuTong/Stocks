//
//  WatchListTableViewCell.swift
//  Stocks
//
//  Created by HieuTong on 11/07/2021.
//

import UIKit

protocol WatchListTableViewCellDelegate: AnyObject {
    func didUpdateMaxWidth(indexPath: IndexPath)
}

class WatchListTableViewCell: UITableViewCell {
    static let identifier = "WatchListTableViewCell"

    static let preferredHeight: CGFloat = 60

    weak var delegate: WatchListTableViewCellDelegate?

    private var indexPath: IndexPath?

    struct ViewModel {
        let symbol: String
        let companyName: String
        let price: String //formatted
        let changeColor: UIColor // red or green
        let changePercentage: String // formatted
        let chartViewModel: StockChartView.ViewModel
    }

    // Symbol label
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    // Company label
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        return label
    }()

    // Price label
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .right
        return label
    }()
    // Change in price label
    private let changeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 6
        return label
    }()

    // Minichart view
    private let miniChartView: StockChartView = {
        let chart = StockChartView()
        chart.isUserInteractionEnabled = false
        chart.clipsToBounds = true
        return chart
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.clipsToBounds = true
        addSubviews(symbolLabel, nameLabel, miniChartView, priceLabel, changeLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        symbolLabel.sizeToFit()
        nameLabel.sizeToFit()
        priceLabel.sizeToFit()
        changeLabel.sizeToFit()

        let yStart: CGFloat = (contentView.height - symbolLabel.height - nameLabel.height) / 2
        symbolLabel.frame = CGRect(x: separatorInset.left, y: yStart, width: symbolLabel.width, height: symbolLabel.height)

        nameLabel.frame = CGRect(x: separatorInset.left, y: symbolLabel.bottom, width: nameLabel.width, height: nameLabel.height)

        let currentWidth = max(max(priceLabel.width, changeLabel.width), WatchListViewController.maxChangeWidth)
        if currentWidth > WatchListViewController.maxChangeWidth {
            WatchListViewController.maxChangeWidth = currentWidth
            if let indexPath = self.indexPath {
                delegate?.didUpdateMaxWidth(indexPath: indexPath)
            }
        }
        priceLabel.frame = CGRect(x: contentView.width - 10 - currentWidth, y: symbolLabel.top, width: currentWidth, height: priceLabel.height)

        changeLabel.frame = CGRect(x: contentView.width - 10 - currentWidth, y: priceLabel.bottom, width: currentWidth, height: changeLabel.height)

        miniChartView.frame = CGRect(x: priceLabel.left - (contentView.width / 3) - 5, y: 6, width: contentView.width / 3, height: contentView.height - 12)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        symbolLabel.text = nil
        nameLabel.text = nil
        priceLabel.text = nil
        changeLabel.text = nil
        miniChartView.reset()
    }

    public func configure(indexPath: IndexPath, with viewModel: ViewModel) {
        self.indexPath = indexPath
        symbolLabel.text = viewModel.symbol
        nameLabel.text = viewModel.companyName
        priceLabel.text = viewModel.price
        changeLabel.text = viewModel.changePercentage
        changeLabel.backgroundColor = viewModel.changeColor
        miniChartView.configure(with: viewModel.chartViewModel)
    }
}
