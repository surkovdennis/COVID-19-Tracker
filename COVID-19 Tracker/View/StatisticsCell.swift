//
//  StatisticsCell.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 23.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import UIKit

class StatisticsCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var confirmedCases: UILabel!
    @IBOutlet weak var recoveredCases: UILabel!
    @IBOutlet weak var deathsCases: UILabel!
    
    override func prepareForReuse() {
        name.text = nil
        confirmedCases.text = nil
        recoveredCases.text = nil
        deathsCases.text = nil
    }
}
