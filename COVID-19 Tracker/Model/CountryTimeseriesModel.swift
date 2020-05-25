//
//  CountryTimeseriesModel.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 23.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import Foundation

struct CountryTimeseries: Decodable {
    let countryregion: String
    let lastupdate: String
    let location: Location
    let countrycode: CountryCode?
    let timeseries: [String: Statistics]
}
