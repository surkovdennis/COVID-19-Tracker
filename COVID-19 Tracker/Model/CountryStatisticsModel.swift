//
//  CountryStatisticsModel.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 23.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

struct CountryStatistics: Codable {
    let countryregion: String
    let lastupdate: String
    let location: Location
    let countrycode: CountryCode?
    let confirmed: Int
    let deaths: Int
    let recovered: Int
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct CountryCode: Codable {
    let iso2: String
    let iso3: String
}
