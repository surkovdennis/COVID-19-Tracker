//
//  COVID-19-APIConfiguration.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 23.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import Foundation

class COVID19APIConfiguration {
    private init() {
        if let path = Bundle.main.path(forResource: "COVID-19-API-Info", ofType: "plist") {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            
            if let venPList = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: Any] {
                plist = venPList
            }
        }
    }
    
    static let shared = COVID19APIConfiguration()
    
    var plist = [String: Any]()
    
    private func plistString(_ key: String) -> String {
        guard let value = plist[key] as? String else { return "" }
        return value
    }
    
    func briefURL() -> String {
        return plistString("brief_url")
    }
    
    func latestURL() -> String {
        return plistString("latest_url")
    }
    
    func timeseriesURL() -> String {
        return plistString("timeseries_url")
    }
}
