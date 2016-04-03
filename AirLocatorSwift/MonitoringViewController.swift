//
//  MonitoringViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class MonitoringViewController : UITableViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    @IBOutlet var enabledSwitch: UISwitch!
    @IBOutlet var uuidTextField: UITextField!
    @IBOutlet var majorTextField: UITextField!
    @IBOutlet var minorTextField: UITextField!
    @IBOutlet var notifyOnEntrySwitch: UISwitch!
    @IBOutlet var notifyOnExitSwitch: UISwitch!
    @IBOutlet var notifyOnDisplaySwitch: UISwitch!
    
    var enabled: Bool?
    var uuid: NSUUID?
    var major: NSNumber?
    var minor: NSNumber?
    var notifyOnEntry: Bool?
    var notifyOnExit: Bool?
    var notifyOnDisplay: Bool?
    
    var doneButton: UIBarButtonItem?
    var numberFormatter = NSNumberFormatter()
    var locationManager = CLLocationManager()
    
    let defaults = Defaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        
        let region = CLBeaconRegion(proximityUUID: NSUUID(), identifier: defaults.BeaconIdentifier)
        if locationManager.monitoredRegions.contains(region) {
            enabled = true
            uuid = region.proximityUUID
            major = region.major
            majorTextField.text = major?.stringValue
            minor = region.minor
            minorTextField.text = minor?.stringValue
            notifyOnEntry = region.notifyOnEntry
            notifyOnExit = region.notifyOnExit
            notifyOnDisplay = region.notifyEntryStateOnDisplay
        } else {
            enabled = false
            uuid = defaults.defaultProximityUUID()
            notifyOnEntry = true
            notifyOnExit = true
            notifyOnDisplay = false
        }
        
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(MonitoringViewController.doneEditing(_:)))
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        uuidTextField.text = uuid?.UUIDString
        enabledSwitch.on = enabled!
        notifyOnEntrySwitch.on = notifyOnEntry!
        notifyOnExitSwitch.on = notifyOnExit!
        notifyOnDisplaySwitch.on = notifyOnDisplay!
    }
    
    // MARK: Toggling state
    
    @IBAction func toggleEnabled(sender: UISwitch) {
        enabled = sender.on
        updateMonitoredRegion()
    }
    
    @IBAction func toggleNotifyOnEntry(sender: UISwitch) {
        notifyOnEntry = sender.on
        updateMonitoredRegion()
    }
    
    @IBAction func toggleNotifyOnExit(sender: UISwitch) {
        notifyOnExit = sender.on
        updateMonitoredRegion()
    }
    
    @IBAction func toggleNotifyOnDisplay(sender: UISwitch) {
        notifyOnDisplay = sender.on
        updateMonitoredRegion()
    }
    
    // MARK: Text editing
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == uuidTextField {
            performSegueWithIdentifier("selectUUID", sender: self)
            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        navigationItem.rightBarButtonItem = doneButton
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let text = textField.text {
            if textField == majorTextField {
                major = numberFormatter.numberFromString(text)
            } else if textField == minorTextField {
                minor = numberFormatter.numberFromString(text)
            }
        }
        
        navigationItem.rightBarButtonItem = nil
        updateMonitoredRegion()
    }
    
    // MARK: Managing editing
    
    @IBAction func doneEditing(sender: AnyObject) {
        majorTextField.resignFirstResponder()
        minorTextField.resignFirstResponder()
        
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "selectUUID" {
            let uuidSelector = segue.destinationViewController as! UUIDViewController
            uuidSelector.uuid = uuid
        }
    }
    
    @IBAction func unwindUUIDSelector(sender: UIStoryboardSegue) {
        let uuidSelector = sender.sourceViewController as! UUIDViewController
        
        uuid = uuidSelector.uuid
        updateMonitoredRegion()
    }
    
    func updateMonitoredRegion() {
        var region:CLBeaconRegion? = CLBeaconRegion(proximityUUID: NSUUID(), identifier: defaults.BeaconIdentifier)
        if let region = region {
            locationManager.stopMonitoringForRegion(region)
        }
        
        if (enabled != nil) {
            var majorShortValue: UInt16 = 0
            var minorShortValue: UInt16 = 0
            
            let majorInt = major?.shortValue
            let minorInt = minor?.shortValue
            
            majorShortValue = UInt16(majorInt!)
            minorShortValue = UInt16(minorInt!)
            
            if uuid != nil && major != nil && minor != nil {
                region = CLBeaconRegion(proximityUUID: uuid!, major: majorShortValue, minor: minorShortValue, identifier: defaults.BeaconIdentifier)
            } else if uuid != nil && major != nil {
                region = CLBeaconRegion(proximityUUID: uuid!, major: majorShortValue, identifier: defaults.BeaconIdentifier)
            } else if uuid != nil {
                region = CLBeaconRegion(proximityUUID: uuid!, identifier: defaults.BeaconIdentifier)
            }
            
            if let region = region {
                region.notifyOnEntry = notifyOnEntry!
                region.notifyOnExit = notifyOnExit!
                region.notifyEntryStateOnDisplay = notifyOnDisplay!
                
                locationManager.startMonitoringForRegion(region)
            }
            
        } else {
            region = CLBeaconRegion(proximityUUID: NSUUID(), identifier: defaults.BeaconIdentifier)
            if let region = region {
                locationManager.stopMonitoringForRegion(region)
            }
        }
    }
    
}
 