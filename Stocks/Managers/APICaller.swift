//
//  APICaller.swift
//  Stocks
//
//  Created by HieuTong on 04/07/2021.
//

import Foundation

final class APICaller {
    static let shared = APICaller()
    
    private struct Constants {
        static let apiKey = "c3grd4aad3i83du7hps0"
        static let sandboxApiKey = "sandbox_c3grd4aad3i83du7hpsg"
        static let baseURL = "https://finnhub.io/api/v1/"
        static let day : TimeInterval = 3600 * 24
    }
    
    private init() {}
    
    //MARK: - Public
    
    public func search(
        query: String,
        completion: @escaping (Result<SearchResponse, Error>) -> Void
    ) {
        guard let safeQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = url(for: .search, queryParams: ["q": safeQuery]) else { return }
        request(url: url, expecting: SearchResponse.self, completion: completion)
    }
    
    //MARK: - Private

    public func news(
        for type: NewsViewController.`Type`,
        completion: @escaping (Result<[NewsStory], Error>) -> Void
    ) {
        switch type {
        case .topStories:
            let url = url(for: .topStories, queryParams: ["category" : "general"])
            request(url: url, expecting: [NewsStory].self, completion: completion)
        case .company(let symbol):
            let today = Date()
            let oneMonthBack = today.addingTimeInterval(-(Constants.day * 7))
            let url = url(for: .companyNews, queryParams: ["symbol": symbol, "from": DateFormatter.newsDateFormmatter.string(from: oneMonthBack), "to": DateFormatter.newsDateFormmatter.string(from: today)])
            request(url: url, expecting: [NewsStory].self, completion: completion)
        }
    }

    public func marketData(for symbol: String, numberOfDays: TimeInterval = 7, completion: @escaping (Result<MarketDataResponse, Error>) -> Void) {
        let today = Date().addingTimeInterval(-(Constants.day))
        let prior = today.addingTimeInterval(-(Constants.day * numberOfDays))
        let url = url(
            for: .marketData,
            queryParams: [
                "symbol": symbol,
                "resolution": "1",
                "from": "\(Int(prior.timeIntervalSince1970))",
                "to": "\(Int(today.timeIntervalSince1970))"
            ]
        )

        request(url: url, expecting: MarketDataResponse.self, completion: completion)
    }
    
    public func financialMetrics(
        symbol: String,
        completion: @escaping (Result<FinacialMetricsResponse, Error>) -> Void
    ) {
        let url = url(
            for: .financials,
            queryParams: ["symbol": symbol, "metric": "all"]
        )
        
        request(url: url, expecting: FinacialMetricsResponse.self, completion: completion)
    }
    
    private enum Endpoint: String {
        case search = "search"
        case topStories = "news"
        case companyNews = "company-news"
        case marketData = "stock/candle"
        case financials = "stock/metric"
    }
    
    private enum APIError: Error {
        case noDataReturned
        case invalidUrl
    }
    
    private func url(
        for endpoint: Endpoint,
        queryParams: [String:String] = [:]
    ) -> URL? {
        var urlString = Constants.baseURL + endpoint.rawValue
        
        var queryItems = [URLQueryItem]()
        // Add any parameters
        for (name, value) in queryParams {
            queryItems.append(.init(name: name, value: value))
        }
        // Add token
        queryItems.append(.init(name: "token", value: Constants.apiKey))
        
        // Convert query items to suffix string
        let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        urlString += "?" + queryString
        
        print("\n \(urlString) \n")
        
        return URL(string: urlString)
    }
    
    private func request<T: Codable>(
        url: URL?,
        expecting: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = url else {
            // Invalid URL
            completion(.failure(APIError.invalidUrl))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(APIError.noDataReturned))
                }
                return
            }
            do {
                let result = try JSONDecoder().decode(expecting, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
