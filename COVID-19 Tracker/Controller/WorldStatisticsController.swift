//
//  WorldStatisticsController.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 23.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import UIKit

class WorldStatisticsController: UIViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var headerLogo: UIImageView!
    @IBOutlet weak var lastUpdate: UILabel!
    @IBOutlet weak var confirmedCases: UILabel!
    @IBOutlet weak var recoveredCases: UILabel!
    @IBOutlet weak var deathsCases: UILabel!
    @IBOutlet weak var countriesTable: UITableView!
    
    @IBOutlet weak var countriesTableHeight: NSLayoutConstraint!
    
    @IBAction func updateStatistics(_ sender: Any) {
        updateStatistics()
    }
    
    @IBAction func returnToWorldStatistics(unwindSegue: UIStoryboardSegue) { }
    
    private let reuseIdentifier = "statisticsCell"
    private let cellHeight: CGFloat = 45
    private let numberFormatter = NumberFormatter()
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var countriesStatistics: [CountryStatisticsTotal] = []
    private var filteredCountriesStatistics: [CountryStatisticsTotal] = []
    
    private var yOffsetToUpdate: CGFloat {
        -(view.bounds.height / 5)
    }
    
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Data updating
        NotificationCenter.default.addObserver(self, selector: #selector(updateWorldStatistics(with:)), name: .WorldStatisticsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCountriesStatistics(with:)), name: .CountriesStatisticsUpdate, object: nil)
        
        // Checking for network issues
        NotificationCenter.default.addObserver(self, selector: #selector(checkDownloadingState(with:)), name: .StatisticsDownloadingState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkLatestCountriesTotalsDownloadingState(with:)), name: .LatestCountriesTotalsDownloadingState, object: nil)
        
        updateStatistics()
        
        // Formatters
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSize = 3
        numberFormatter.groupingSeparator = " "
        
        // Search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search country"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self
        
        countriesTable.tableFooterView = UIView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showCountryStatistics":
            guard let countryStatisticsController = segue.destination as? CountryStatisticsController,
                let indexPath = countriesTable.indexPath(for: sender as! UITableViewCell) else { return }
            
            let countryStatistics: CountryStatisticsTotal
            
            if isFiltering {
                countryStatistics = filteredCountriesStatistics[indexPath.row]
            } else {
                countryStatistics = countriesStatistics[indexPath.row]
            }
            
            countryStatisticsController.countryTitle = countryStatistics.flag
                + " "
                + countryStatistics.countryregion
                + ". Total confirmed cases"
            
            countryStatisticsController.updated = lastUpdate.text ?? ""
            countryStatisticsController.confirmed = countryStatistics.confirmed
            countryStatisticsController.recovered = countryStatistics.recovered
            countryStatisticsController.deaths = countryStatistics.deaths
            countryStatisticsController.countryCode = countryStatistics.countrycode
            
        default:
            return
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredCountriesStatistics = countriesStatistics.filter { country in
            country.countryregion.lowercased().contains(searchText.lowercased())
        }
        
        countriesTable.reloadData()
    }
    
    @objc func updateWorldStatistics(with notification: Notification) {
        guard let userInfo = notification.userInfo,
            let result = userInfo["result"] as? Statistics
            else { return }
        
        let lastUpdate = StatisticsManager.shared.getLastUpdateDateString()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.lastUpdate.text = lastUpdate
            self.confirmedCases.text = self.numberFormatter.string(from: NSNumber(value: result.confirmed))
            self.recoveredCases.text = self.numberFormatter.string(from: NSNumber(value: result.recovered))
            self.deathsCases.text = self.numberFormatter.string(from: NSNumber(value: result.deaths))
        }
    }
    
    @objc func updateCountriesStatistics(with notification: Notification) {
        guard let userInfo = notification.userInfo,
            let result = userInfo["result"] as? [CountryStatisticsTotal]
            else { return }
        
        countriesStatistics = result
        countriesStatistics.sort { $0.confirmed > $1.confirmed }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.countriesTableHeight.constant = CGFloat(self.countriesStatistics.count) * self.cellHeight
            
            self.countriesTable.reloadData()
            
            self.headerLogo.isHidden = false
            self.activityIndicator.stopAnimating()
        }
    }
    
    @objc func checkDownloadingState(with notification: Notification) {
        if NetworkManager.shared.statisticsDownloadingState == .cancelled {
            downloadingCancelled()
        }
    }
    
    @objc func checkLatestCountriesTotalsDownloadingState(with notification: Notification) {
        if NetworkManager.shared.latestCountriesTotalsDownloadingState == .cancelled {
            downloadingCancelled()
        }
    }
    
    private func downloadingCancelled() {
        let lastUpdate = StatisticsManager.shared.getLastUpdateDateString()
        self.lastUpdate.text = "\u{26a0} \(lastUpdate)"
        
        headerLogo.isHidden = false
        activityIndicator.stopAnimating()
    }
    
    private func updateStatistics() {
        if NetworkManager.shared.statisticsDownloadingState != .started
            && NetworkManager.shared.latestCountriesTotalsDownloadingState != .started {
            
            StatisticsManager.shared.updateWorldStatistics(for: self)
            StatisticsManager.shared.updateCountriesStatistics(for: self)
            
            headerLogo.isHidden = true
            activityIndicator.startAnimating()
        }
    }
}

extension WorldStatisticsController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredCountriesStatistics.count
        }
        
        return countriesStatistics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? StatisticsCell else { return UITableViewCell() }
        
        let countryStatistics: CountryStatisticsTotal
        
        if isFiltering {
            countryStatistics = filteredCountriesStatistics[indexPath.row]
        } else {
            countryStatistics = countriesStatistics[indexPath.row]
        }
        
        cell.name.text = countryStatistics.flag + " " + countryStatistics.countryregion
        cell.confirmedCases.text = numberFormatter.string(from: NSNumber(value: countryStatistics.confirmed))
        cell.recoveredCases.text = numberFormatter.string(from: NSNumber(value: countryStatistics.recovered))
        cell.deathsCases.text = numberFormatter.string(from: NSNumber(value: countryStatistics.deaths))
        
        return cell
    }
}

extension WorldStatisticsController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < yOffsetToUpdate {
            updateStatistics()
        }
    }
}

extension WorldStatisticsController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}

extension WorldStatisticsController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
    }
}
