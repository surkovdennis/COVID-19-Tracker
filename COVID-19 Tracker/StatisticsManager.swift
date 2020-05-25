//
//  StatisticsManager.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 24.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import UIKit

class StatisticsManager {
    private init() { }
    static let shared = StatisticsManager()
    
    private enum Filenames {
        static let worldStatistics = "worldStatistics.json"
        static let countriesStatistics = "countriesStatistics.json"
        static let countriesTimeseries = "countriesTimeseries.json"
    }
    
    private var documents: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func updateWorldStatistics(for vc: UIViewController) {
        DispatchQueue.global().async {
            if let result: Statistics = self.getStatistics(Filenames.worldStatistics) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .WorldStatisticsUpdate, object: vc, userInfo: ["result": result])
                }
            }
            
            NetworkManager.shared.getStatistics { [weak vc] result in
                guard let vc = vc else { return }
                self.saveLastUpdateDateString()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .WorldStatisticsUpdate, object: vc, userInfo: ["result": result])
                }
                
                // Caching
                self.saveStatistics(result, Filenames.worldStatistics)
            }
        }
    }
    
    func updateCountriesStatistics(for vc: UIViewController) {
        DispatchQueue.global().async {
            if let result: [CountryStatisticsTotal] = self.getStatistics(Filenames.countriesStatistics) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .CountriesStatisticsUpdate, object: vc, userInfo: ["result": result])
                }
            }
            
            NetworkManager.shared.getLatestCountriesTotals { [weak vc] result in
                guard let vc = vc else { return }
                
                var countriesStatistics: [CountryStatisticsTotal] = []
                
                for item in result {
                    // Configuring emoji flag for the country
                    var flag = ""
                    if let unicodeScalars = item.countrycode?.iso2.unicodeScalars {
                        for unicodeScalar in unicodeScalars {
                            guard let value = UnicodeScalar(127397 + unicodeScalar.value) else { continue }
                            
                            flag.append(String(value))
                        }
                    }
                    
                    countriesStatistics.append(CountryStatisticsTotal(flag: flag,
                                                                      countryregion: item.countryregion,
                                                                      countrycode: item.countrycode?.iso2 ?? "",
                                                                      confirmed: item.confirmed,
                                                                      deaths: item.deaths,
                                                                      recovered: item.recovered))
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .CountriesStatisticsUpdate, object: vc, userInfo: ["result": countriesStatistics])
                }
                
                // Caching
                self.saveStatistics(countriesStatistics, Filenames.countriesStatistics)
            }
        }
    }
    
    func updateCountryTimeseries(for vc: UIViewController, _ countryCode: String) {
        DispatchQueue.global().async {
            if let resultArray: [CountryTimeseriesTotal] = self.getStatistics(countryCode + Filenames.countriesTimeseries) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .CountryTimeseriesUpdate, object: vc, userInfo: ["result": resultArray])
                }
            }
            
            NetworkManager.shared.getCountryTimeseries(countryCode) { [weak vc] result in
                guard let vc = vc else { return }
                
                // Converting date string into date for further sorting
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yy"
                
                var resultArray: [CountryTimeseriesTotal] = []
                for item in result {
                    for timeseries in item.timeseries {
                        guard let date = dateFormatter.date(from: timeseries.key) else { continue }
                        
                        resultArray.append(CountryTimeseriesTotal(date: date,
                                                                  confirmed: timeseries.value.confirmed,
                                                                  recovered: timeseries.value.recovered,
                                                                  deaths: timeseries.value.deaths))
                    }
                }
                
                // Showing newest first
                resultArray.sort(by: { $0.date > $1.date })
                
                // Calculation of the increase day by day
                var current = 0
                var next = 1
                
                while next < resultArray.count {
                    resultArray[current].confirmed -= resultArray[next].confirmed
                    resultArray[current].recovered -= resultArray[next].recovered
                    resultArray[current].deaths -= resultArray[next].deaths
                    
                    current += 1
                    next += 1
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .CountryTimeseriesUpdate, object: vc, userInfo: ["result": resultArray])
                }
                
                // Caching
                self.saveStatistics(resultArray, countryCode + Filenames.countriesTimeseries)
            }
        }
    }
    
    func getLastUpdateDateString() -> String {
        let defaults = UserDefaults.standard
        guard let lastUpdate = defaults.object(forKey: "LastUpdate") as? String else { return "" }
        
        return lastUpdate
    }
    
    private func saveLastUpdateDateString() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy hh:mm"
        
        let lastUpdate = "Last update " + dateFormatter.string(from: Date())
        let defaults = UserDefaults.standard
        
        defaults.set(lastUpdate, forKey: "LastUpdate")
    }
    
    private func getStatistics<T: Codable>(_ path: String) -> T? {
        let savedURL = documents.appendingPathComponent(path)
        var data = try? Data(contentsOf: savedURL)
        if data == nil,
            let bundleURL = Bundle.main.url(forResource: path, withExtension: nil) {
            
            data = try? Data(contentsOf: bundleURL)
        }
        
        if let statisticsData = data,
            let decodedStatistics = try? JSONDecoder().decode(T.self, from: statisticsData) {
            saveStatistics(decodedStatistics, path)
            
            return decodedStatistics
        }
        
        return nil
    }
    
    private func saveStatistics<T: Codable>(_ data: T, _ path: String) {
        let url = documents.appendingPathComponent(path)
        let encoder = JSONEncoder()
        guard let encodedData = try? encoder.encode(data) else { return }
        
        try? encodedData.write(to: url)
    }
}
