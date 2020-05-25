//
//  CountryStatisticsController.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 23.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import UIKit
import Charts

class CountryStatisticsController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastUpdate: UILabel!
    @IBOutlet weak var confirmedCases: UILabel!
    @IBOutlet weak var recoveredCases: UILabel!
    @IBOutlet weak var deathsCases: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var timeseriesChart: LineChartView!
    @IBOutlet weak var countryTimeseriesTable: UITableView!
    
    @IBOutlet weak var countryTimeseriesTableHeight: NSLayoutConstraint!
    
    private let reuseIdentifier = "statisticsCell"
    private let cellHeight: CGFloat = 35
    private let numberFormatter = NumberFormatter()
    private let dateFormatter = DateFormatter()
    private let calendar = Calendar.current
    
    private var countryTimeseries: [CountryTimeseriesTotal] = []
    
    var countryTitle = ""
    var updated = ""
    var confirmed = 0
    var recovered = 0
    var deaths = 0
    var countryCode = ""
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Data updating
        NotificationCenter.default.addObserver(self, selector: #selector(updateCountryTimeseries(with:)), name: .CountryTimeseriesUpdate, object: nil)
        
        // Checking for network issues
        NotificationCenter.default.addObserver(self, selector: #selector(checkDownloadingState(with:)), name: .CountryTimeseriesDownloadingState, object: nil)
        
        StatisticsManager.shared.updateCountryTimeseries(for: self, countryCode)
        
        // Formatters
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSize = 3
        numberFormatter.groupingSeparator = " "
        
        dateFormatter.dateFormat = "dd.MM.yy"
        
        timeseriesChart.noDataText = ""
        countryTimeseriesTable.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = countryTitle
        lastUpdate.text = updated
        confirmedCases.text = numberFormatter.string(from: NSNumber(value: confirmed)) ?? ""
        recoveredCases.text = numberFormatter.string(from: NSNumber(value: recovered)) ?? ""
        deathsCases.text = numberFormatter.string(from: NSNumber(value: deaths)) ?? ""
        
        activityIndicator.startAnimating()
    }
    
    func updateChart() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            var index = self.countryTimeseries.count - 1
            if index < 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                }
                return
            }
            
            // Calculating data month by month
            var confirmedMonth = 0
            var recoveredMonth = 0
            var deathsMonth = 0
            var currentMonth = 1
            
            var confirmedLineChartEntry = [ChartDataEntry]()
            var recoveredLineChartEntry = [ChartDataEntry]()
            var deathsLineChartEntry = [ChartDataEntry]()
            
            while index >= 0 {
                let date = self.countryTimeseries[index]
                let month = self.calendar.component(.month, from: date.date)
                
                if currentMonth == month {
                    confirmedMonth += date.confirmed
                    recoveredMonth += date.recovered
                    deathsMonth += date.deaths
                } else {
                    confirmedLineChartEntry.append(ChartDataEntry(x: Double(month), y: Double(confirmedMonth)))
                    recoveredLineChartEntry.append(ChartDataEntry(x: Double(month), y: Double(recoveredMonth)))
                    deathsLineChartEntry.append(ChartDataEntry(x: Double(month), y: Double(deathsMonth)))
                    
                    confirmedMonth = 0
                    recoveredMonth = 0
                    deathsMonth = 0
                    
                    currentMonth = month
                }
                
                index -= 1
            }
            
            let confirmedLine = LineChartDataSet(entries: confirmedLineChartEntry, label: "Confirmed")
            confirmedLine.colors = [.white]
            
            let recoveredLine = LineChartDataSet(entries: recoveredLineChartEntry, label: "Recovered")
            recoveredLine.colors = [NSUIColor(red: 48/255, green: 209/255, blue: 88/255, alpha: 1)]
            
            let deathsLine = LineChartDataSet(entries: deathsLineChartEntry, label: "Deaths")
            deathsLine.colors = [NSUIColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1)]
            
            let data = LineChartData()
            data.addDataSet(confirmedLine)
            data.addDataSet(recoveredLine)
            data.addDataSet(deathsLine)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.activityIndicator.stopAnimating()
                
                self.timeseriesChart.rightAxis.drawLabelsEnabled = false
                self.timeseriesChart.data = data
            }
        }
    }
    
    @objc func updateCountryTimeseries(with notification: Notification) {
        guard let userInfo = notification.userInfo,
            let result = userInfo["result"] as? [CountryTimeseriesTotal]
            else { return }
        
        self.countryTimeseries = result
        self.updateChart()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.countryTimeseriesTable.reloadData()
            
            self.countryTimeseriesTableHeight.constant = CGFloat(self.countryTimeseries.count) * self.cellHeight
        }
    }
    
    @objc func checkDownloadingState(with notification: Notification) {
        if NetworkManager.shared.countryTimeseriesDownloadingState == .cancelled {
            let lastUpdate = StatisticsManager.shared.getLastUpdateDateString()
            self.lastUpdate.text = "\u{26a0} \(lastUpdate)"
            
            activityIndicator.stopAnimating()
        }
    }
}

extension CountryStatisticsController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countryTimeseries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? StatisticsCell else { return UITableViewCell() }
        
        let date = countryTimeseries[indexPath.row]
        let prefixConfirmed = date.confirmed <= 0 ? "" : "+"
        let prefixRecovered = date.recovered <= 0 ? "" : "+"
        let prefixDeaths = date.deaths <= 0 ? "" : "+"
        
        cell.name.text = dateFormatter.string(from: date.date)
        cell.confirmedCases.text = prefixConfirmed + (numberFormatter.string(from: NSNumber(value: date.confirmed)) ?? "")
        cell.recoveredCases.text = prefixRecovered + (numberFormatter.string(from: NSNumber(value: date.recovered)) ?? "")
        cell.deathsCases.text = prefixDeaths + (numberFormatter.string(from: NSNumber(value: date.deaths)) ?? "")
        
        return cell
    }
}
