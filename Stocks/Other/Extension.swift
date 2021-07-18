//
//  Extension.swift
//  Stocks
//
//  Created by HieuTong on 04/07/2021.
//

import Foundation
import UIKit


// MARK: - Notification
extension Notification.Name {
    /// Notification when  symbol gets added to watchlist
    static let didAddToWatchList = Notification.Name("didAddToWatchList")
}

//NumberFormatter
extension NumberFormatter {
    /// Formatter for percent style
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Formatter for decimal style
    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

// ImageView

extension UIImageView {
    /// Set image for remote url
    /// - Parameter url: URL to fetch form
    func setImage(with url: URL?) {
        guard let url = url else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let data = data, error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    self?.image = UIImage(data: data)
                }
            }
            task.resume()
        }
    }
}

extension String {
    /// Create string from time interval
    /// - Parameter timeInterval: Timeinterval since 1970
    /// - Returns: Fommatted string
    static func string(from timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        return DateFormatter.prettyDateFormmatter.string(from: date)
    }
    
    /// Percentage formatter string
    /// - Parameter double: Double to format
    /// - Returns: String percent format
    static func percentage(from double: Double) -> String {
        let formatter = NumberFormatter.percentFormatter
        return formatter.string(from: NSNumber(value: double)) ?? "\(double)"
    }
    
    /// Format number to string
    /// - Parameter double: Number to form
    /// - Returns: Formatted string
    static func formatted(from double: Double) -> String {
        let formatter = NumberFormatter.decimalFormatter
        return formatter.string(from: NSNumber(value: double)) ?? "\(double)"
    }

}

//MARK: - DateFormatter

extension DateFormatter {
    static let newsDateFormmatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()

    static let prettyDateFormmatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

//MARK: - Add Subview
extension UIView {
    /// Add mutiples subviews
    /// - Parameter views: Collection of subviews
    func addSubviews(_ views: UIView...) {
        views.forEach { view in
            addSubview(view)
        }
    }
}

// MARK: - Framing

extension UIView {
    /// Width of view
    var width: CGFloat {
        return frame.size.width
    }
    
    /// Height of view
    var height: CGFloat {
        return frame.size.height
    }
    
    /// Left edge of view
    var left: CGFloat {
        return frame.origin.x
    }
    
    /// Right edge of view
    var right: CGFloat {
        return left + width
    }
    
    /// Top edge of view
    var top: CGFloat {
        return frame.origin.y
    }
    
    /// Bottom edge of view
    var bottom: CGFloat {
        return top + height
    }
}

// MARK: -CandleStick Sorting

extension Array where Element == CandleStick {
    func getPercentage() -> Double {
        let latestDate = self[0].date
        guard let latestClose = self.first?.close,
              let priorClose = self.first(where: {
                !Calendar.current.isDate($0.date, inSameDayAs: latestDate)
              })?.close else {
            return 0.0
        }

        let diff = 1 - (priorClose / latestClose)
        return diff
    }
}
