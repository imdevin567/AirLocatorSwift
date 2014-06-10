//
//  CalibrationEndViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/9/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit

class CalibrationEndViewController : UIViewController {
    @IBOutlet var measuredPowerLabel : UILabel
    
    var measuredPower : Int?
    
    func doneButtonTapped(sender: AnyObject?) {
        self.navigationController.popToRootViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("doneButtonTapped"))
        self.navigationItem.rightBarButtonItem = doneButton
        measuredPowerLabel.text = "\(self.measuredPower)"
    }
    
    func setMeasuredPower(measuredPower: Int) {
        self.measuredPower = measuredPower
        self.measuredPowerLabel.text = "\(measuredPower)"
    }
}
