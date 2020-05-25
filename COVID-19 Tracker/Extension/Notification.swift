//
//  Notification.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 24.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let WorldStatisticsUpdate = Notification.Name("WorldStatisticsUpdate")
    static let CountriesStatisticsUpdate = Notification.Name("CountriesStatisticsUpdate")
    static let CountryTimeseriesUpdate = Notification.Name("CountryTimeseriesUpdate")
    
    static let StatisticsDownloadingState = Notification.Name("StatisticsDownloadingState")
    static let LatestCountriesTotalsDownloadingState = Notification.Name("LatestCountriesTotalsDownloadingState")
    static let CountryTimeseriesDownloadingState = Notification.Name("CountryTimeseriesDownloadingState")
}
