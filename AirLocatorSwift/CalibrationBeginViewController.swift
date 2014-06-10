//
//  CalibrationBeginViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/10/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class CalibrationBeginViewController : UITableViewController, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    var rangedRegions = Array<CLBeaconRegion>()
    var beacons = Dictionary<String, AnyObject[]>()
    var defaults = Defaults()
    
    var immediates = CLBeacon[]()
    var unknowns = CLBeacon[]()
    var fars = CLBeacon[]()
    var nears = CLBeacon[]()
    
    var calculator : CalibrationCalculator?
    var inProgress : Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        inProgress = false
        
        for (uuid) in defaults.supportedProximityUUIDs {
            let region = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.UUIDString)
            rangedRegions += region
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.startRangingAllRegions()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.calculator?.cancelCalibration()
        self.stopRangingAllRegions()
    }
    
    // MARK: Ranging beacons
    
    func startRangingAllRegions() {
        for (region) in rangedRegions {
            locationManager.startRangingBeaconsInRegion(region)
        }
    }
    
    func stopRangingAllRegions() {
        for (region) in rangedRegions {
            locationManager.stopRangingBeaconsInRegion(region)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: AnyObject[]!, inRegion region: CLBeaconRegion!) {
        self.beacons.removeAll(keepCapacity: false)

        for (indBeacon : AnyObject) in beacons {
            switch indBeacon.proximity.toRaw() {
                case CLProximity.Immediate.toRaw():
                    immediates += indBeacon as CLBeacon
                case CLProximity.Unknown.toRaw():
                    unknowns += indBeacon as CLBeacon
                case CLProximity.Far.toRaw():
                    fars += indBeacon as CLBeacon
                case CLProximity.Near.toRaw():
                    nears += indBeacon as CLBeacon
                default:
                    println() // do nothing
            }
        }
        
        self.beacons["Immediate"] = immediates
        self.beacons["Unknown"] = unknowns
        self.beacons["Far"] = fars
        self.beacons["Near"] = nears
        
        tableView.reloadData()
    }
    
    func updateProgressViewWithProgress(percentComplete: Float) {
        if !inProgress {
            return
        }
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        var progressCell = self.tableView.cellForRowAtIndexPath(indexPath) as ProgressTableViewCell
        progressCell.progressView.setProgress(percentComplete, animated: true)
    }
    
    // MARK: Table view data source/delegate
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        let i = inProgress ? beacons.count + 1 : beacons.count
        return i
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        var adjustedSection = section
        
        if inProgress {
            if adjustedSection == 0 {
                return 1
            } else {
                adjustedSection--
            }
        }
        
        let sectionValues = Array(beacons.values)
        return sectionValues[adjustedSection].count
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        var adjustedSection = section
        
        if inProgress {
            if adjustedSection == 0 {
                return nil
            } else {
                adjustedSection--
            }
        }
        
        let sectionKeys = Array(beacons.keys)
        let sectionKey = sectionKeys[adjustedSection]
        
        return sectionKey
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let beaconCellIdentifier = "BeaconCell"
        let progressCellIdentifier = "ProgressCell"
        var section = indexPath.section
        let identifier = inProgress && section == 0 ? progressCellIdentifier : beaconCellIdentifier
        let cell : AnyObject! = tableView.dequeueReusableCellWithIdentifier(identifier)
        
        if identifier == progressCellIdentifier {
            return cell as UITableViewCell
        } else if inProgress {
            section--
        }
        
        let sectionKey = Array(beacons.keys)[section]
        let beacon : AnyObject? = beacons[sectionKey]?[indexPath.row]
        
        if var cellLabel = cell.textLabel {
            cellLabel.text = beacon?.proximityUUID?.UUIDString
        }
        
        if var cellDetailLabel = cell.detailTextLabel {
            cellDetailLabel.text = "Major: \(beacon?.major), Minor: \(beacon?.minor), Acc: \(beacon?.accuracy)"
        }
        
        return cell as UITableViewCell
    }
    
    override func tableView(tableView: UITableView!, didDeselectRowAtIndexPath indexPath: NSIndexPath!) {
        let sectionKey = Array(beacons.keys)[indexPath.section]
        var beacon : AnyObject? = self.beacons[sectionKey]?[indexPath.section]

        if !inProgress {
            var region : CLBeaconRegion?
            
            var majorShortValue: UInt16 = 0
            var minorShortValue: UInt16 = 0
            
            let majorInt = beacon?.major?.integerValue
            let minorInt = beacon?.minor?.integerValue
            
            majorShortValue = UInt16(majorInt!)
            minorShortValue = UInt16(minorInt!)
            
            if beacon?.proximityUUID != nil && beacon?.major != nil && beacon?.minor != nil {
                region = CLBeaconRegion(proximityUUID: beacon?.proximityUUID, major: majorShortValue, minor: minorShortValue, identifier: defaults.BeaconIdentifier)
            } else if beacon?.proximityUUID != nil && beacon?.major != nil {
                region = CLBeaconRegion(proximityUUID: beacon?.proximityUUID, major: majorShortValue, identifier: defaults.BeaconIdentifier)
            } else if beacon?.proximityUUID {
                region = CLBeaconRegion(proximityUUID: beacon?.proximityUUID, identifier: defaults.BeaconIdentifier)
            }
            
            if region != nil {
                self.stopRangingAllRegions()
                
                calculator = CalibrationCalculator(region: region!) { measuredPower, error in
                    if error != nil {
                        if self.view.window {
                            let title = "Unable to calibrate device"
                            let cancelTitle = "OK"
                            let alert = UIAlertView(title: title, message: error.userInfo.description, delegate: nil, cancelButtonTitle: cancelTitle)
                            alert.show()
                            
                            self.startRangingAllRegions()
                        }
                    } else {
                        var endViewController = self.storyboard.instantiateViewControllerWithIdentifier("EndViewController") as CalibrationEndViewController
                        endViewController.measuredPower = measuredPower
                        self.navigationController.pushViewController(endViewController, animated: true)
                    }
                    
                    self.inProgress = false
                    self.calculator = nil
                    
                    tableView.reloadData()
                }
                
                calculator?.performCalibrationWithProgressHandler { [weak self] percentComplete in
                    if let weakSelf = self {
                        weakSelf.updateProgressViewWithProgress(percentComplete)
                    }
                }
                
                inProgress = true
                tableView.beginUpdates()
                tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                
                let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                tableView.endUpdates()
                self.updateProgressViewWithProgress(0.0)
            }
        }
    }
    
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if inProgress && indexPath.section == 0 {
            return 66.0
        }
        
        return 44.0
    }
}
