//
//  StockChartView.swift
//  Stocks
//
//  Created by HieuTong on 11/07/2021.
//

import UIKit

class StockChartView: UIView {

    struct ViewModel {
        let data: [Double]
        let showLegend: Bool
        let showAxisBool: Bool
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    /// Reset the chart view
    public func reset() {

    }

    func configure(view model: ViewModel) {
        
    }

}
