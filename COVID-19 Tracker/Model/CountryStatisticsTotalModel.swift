//
//  CountryStatisticsTotalModel.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 24.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import Foundation

struct CountryStatisticsTotal: Codable {
    let flag: String
    let countryregion: String
    let countrycode: String
    let confirmed: Int
    let deaths: Int
    let recovered: Int
}
