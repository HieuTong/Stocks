//
//  PersistenceManager.swift
//  Stocks
//
//  Created by HieuTong on 04/07/2021.
//

import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let userDefaults: UserDefaults = .standard
    
    private struct Constants {
        
    }
    
    private init() {}
    
    //MARK: - Public
    public var watchlist: [String] {
        return []
    }
    
    public func addToWatchlist() {
        
    }
    
    public func removeToWatchlist() {
        
    }
    
    //MARK: - Private
    private var hasOnboarded: Bool {
        return false
    }
}
