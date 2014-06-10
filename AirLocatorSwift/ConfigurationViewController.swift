//
//  ConfigurationViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/9/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

class ConfigurationViewController : UITableViewController, CBPeripheralManagerDelegate, UIAlertViewDelegate, UITextFieldDelegate {
    @IBOutlet var enabledSwitch : UISwitch
    @IBOutlet var uuidTextField : UITextField
    @IBOutlet var majorTextField : UITextField
    @IBOutlet var minorTextField : UITextField
    @IBOutlet var powerTextField : UITextField
    
    var peripheralManager = CBPeripheralManager()
    var region : CLBeaconRegion?
    var power : Int?
    
    var enabled : Bool?
    var uuid : NSUUID?
    var major : NSNumber?
    var minor : NSNumber?
    var doneButton : UIBarButtonItem?
    var numberFormatter = NSNumberFormatter()
    
    let defaults = Defaults()
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        peripheralManager = CBPeripheralManager(delegate: self, queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    }
    
    init(style: UITableViewStyle) {
        super.init(style: UITableViewStyle.Plain)
        peripheralManager = CBPeripheralManager(delegate: self, queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("doneEditing"))
        
        if region != nil {
            uuid = region?.proximityUUID
            major = region?.major
            minor = region?.minor
        } else {
            uuid = defaults.defaultProximityUUID()
            major = NSNumber.numberWithShort(0)
            minor = NSNumber.numberWithShort(0)
        }
        
        if power == nil {
            power = defaults.defaultPower
        }
        
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        } else {
            peripheralManager.delegate = self
        }
        
        self.enabledSwitch.on = peripheralManager.isAdvertising
        enabled = enabledSwitch.on
        
        uuidTextField.text = uuid?.UUIDString
        majorTextField.text = major?.stringValue
        minorTextField.text = minor?.stringValue
        powerTextField.text = power?.bridgeToObjectiveC().stringValue
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        peripheralManager.delegate = nil
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        
    }
    
    // MARK: Text editing
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == uuidTextField {
            self.performSegueWithIdentifier("selectUUID", sender: self)
            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == majorTextField {
            major = numberFormatter.numberFromString(textField.text)
        } else if textField == minorTextField {
            minor = numberFormatter.numberFromString(textField.text)
        } else if textField == powerTextField {
            power = numberFormatter.numberFromString(textField.text).integerValue
            
            if power > 0 {
                let negativePower = power! - (power! * 2)
                power = negativePower
                textField.text = power?.bridgeToObjectiveC().stringValue
            }
        }
        
        self.navigationItem.rightBarButtonItem = nil
        
        self.updateAdvertisedRegion()
    }
    
    @IBAction func toggleEnabled(sender: UISwitch) {
        enabled = sender.on
        self.updateAdvertisedRegion()
    }
    
    @IBAction func doneEditing(sender: AnyObject?) {
        majorTextField?.resignFirstResponder()
        minorTextField?.resignFirstResponder()
        powerTextField?.resignFirstResponder()
        
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == "selectUUID" {
            var uuidSelector : UUIDViewController = segue.destinationViewController as UUIDViewController
            uuidSelector.uuid = self.uuid
        }
    }
    
    @IBAction func unwindUUIDSelector(sender: UIStoryboardSegue) {
        var uuidSelector : UUIDViewController = sender.sourceViewController as UUIDViewController
        self.uuid = uuidSelector.uuid
        self.updateAdvertisedRegion()
    }
    
    func updateAdvertisedRegion() {
        if (peripheralManager.state.toRaw() < CBPeripheralManagerState.PoweredOn.toRaw()) {
            let title = "Bluetooth must be enabled"
            let message = "To configure your device as a beacon"
            let cancelButtonTitle = "OK"
            let errorAlert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle)
            errorAlert.show()
            
            return
        }
        
        peripheralManager.stopAdvertising()
        
        if enabled {
            var majorShortValue: UInt16 = 0
            var minorShortValue: UInt16 = 0
            
            let majorInt = major?.integerValue
            let minorInt = minor?.integerValue
            
            majorShortValue = UInt16(majorInt!)
            minorShortValue = UInt16(minorInt!)
            
            var peripheralData : NSDictionary?
            region = CLBeaconRegion(proximityUUID: uuid, major: majorShortValue, minor: minorShortValue, identifier: defaults.BeaconIdentifier)
            
            peripheralData = region?.peripheralDataWithMeasuredPower(power)
            
            if peripheralData != nil {
                peripheralManager.startAdvertising(peripheralData)
            }
        }
    }
}
