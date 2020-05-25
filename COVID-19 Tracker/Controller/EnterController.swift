//
//  EnterController.swift
//  COVID-19 Tracker
//
//  Created by Denis Surkov on 22.05.2020.
//  Copyright © 2020 Denis Surkov Labs. All rights reserved.
//

import UIKit

class EnterController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIView.animateKeyframes(withDuration: 4, delay: 0, options: .calculationModeLinear, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                self.titleLabel.alpha = 1
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.3, animations: {
                self.titleLabel.alpha = 0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.2, animations: {
                self.logoImage.transform = CGAffineTransform(scaleX: 100, y: 100)
            })
        }) { _ in
            self.performSegue(withIdentifier: "showStatistics", sender: nil)
        }
    }
}
