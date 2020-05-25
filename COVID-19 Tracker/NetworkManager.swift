//
//  NetworkManager.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 23.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import Alamofire

class NetworkManager {
    private init() { }
    static let shared = NetworkManager()
    
    private enum DownloadingKeys {
        static let statistics = "statistics"
        static let latestCountriesTotals = "latestCountriesTotals"
        static let countryTimeseries = "countryTimeseries"
    }
    
    var statisticsDownloadingState: DownloadingState = .none {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .StatisticsDownloadingState, object: nil)
            }
        }
    }
    
    var latestCountriesTotalsDownloadingState: DownloadingState = .none {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .LatestCountriesTotalsDownloadingState, object: nil)
            }
        }
    }
    
    var countryTimeseriesDownloadingState: DownloadingState = .none {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .CountryTimeseriesDownloadingState, object: nil)
            }
        }
    }
    
    func getStatistics(completionHandler: @escaping(Statistics) -> ()) {
        let key = DownloadingKeys.statistics
        let url = COVID19APIConfiguration.shared.briefURL()
        
        setDownloadingState(for: key, state: .started)
        getData(key, url, completionHandler: completionHandler)
    }
    
    func getLatestCountriesTotals(completionHandler: @escaping([CountryStatistics]) -> ()) {
        let key = DownloadingKeys.latestCountriesTotals
        let url = COVID19APIConfiguration.shared.latestURL()
        let parameters: Parameters = ["onlyCountries": true]
        
        setDownloadingState(for: key, state: .started)
        getData(key, url, parameters, completionHandler: completionHandler)
    }
    
    func getCountryTimeseries(_ countryCode: String, completionHandler: @escaping([CountryTimeseries]) -> ()) {
        let key = DownloadingKeys.countryTimeseries
        let url = COVID19APIConfiguration.shared.timeseriesURL()
        let parameters: Parameters = ["iso2": countryCode,
                                      "onlyCountries": true]
        
        setDownloadingState(for: key, state: .started)
        getData(key, url, parameters, completionHandler: completionHandler)
    }
    
    private func getData<T: Decodable>(_ key: String, _ url: String, _ parameters: Parameters = [:], completionHandler: @escaping (T) -> ()) {
        AF.request(url, method: .get, parameters: parameters)
            .responseJSON(queue: DispatchQueue.global()) { [weak self] data in
                guard let self = self else { return }
                
                do {
                    if let resultData = data.data {
                        let result = try JSONDecoder().decode(T.self, from: resultData)
                        completionHandler(result)
                        
                        self.setDownloadingState(for: key, state: .finished)
                    } else {
                        self.setDownloadingState(for: key, state: .cancelled)
                    }
                } catch {
                    self.setDownloadingState(for: key, state: .cancelled)
                }
        }
    }
    
    private func setDownloadingState(for key: String, state: DownloadingState) {
        switch key {
        case "latestCountriesTotals":
            self.latestCountriesTotalsDownloadingState = state
        case "countryTimeseries":
            self.countryTimeseriesDownloadingState = state
        default:
            self.statisticsDownloadingState = state
        }
    }
}
