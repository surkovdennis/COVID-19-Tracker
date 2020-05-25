//
//  CountryTimeseriesTotalModel.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 24.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import Foundation

struct CountryTimeseriesTotal: Codable {
    let date: Date
    var confirmed: Int
    var recovered: Int
    var deaths: Int
}
