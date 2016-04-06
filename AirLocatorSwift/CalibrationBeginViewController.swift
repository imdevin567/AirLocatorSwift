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
    var rangedRegions = [CLBeaconRegion]()
    var beacons = [String :[CLBeacon]]()
    var defaults = Defaults()
    
    var immediates = [CLBeacon]()
    var unknowns = [CLBeacon]()
    var fars = [CLBeacon]()
    var nears = [CLBeacon]()
    
    var calculator : CalibrationCalculator?
    var inProgress : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        for uuid in defaults.supportedProximityUUIDs {
            let region = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.UUIDString)
            rangedRegions.append(region)
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
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        self.beacons.removeAll(keepCapacity: false)

        for indBeacon in beacons {
            switch indBeacon.proximity.rawValue {
                case CLProximity.Immediate.rawValue:
                    immediates.append(indBeacon)
                case CLProximity.Unknown.rawValue:
                    unknowns.append(indBeacon)
                case CLProximity.Far.rawValue:
                    fars.append(indBeacon)
                case CLProximity.Near.rawValue:
                    nears.append(indBeacon)
                default:
                    print("") // do nothing
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
        let progressCell = self.tableView.cellForRowAtIndexPath(indexPath) as! ProgressTableViewCell
        progressCell.progressView.setProgress(percentComplete, animated: true)
    }
    
    // MARK: Table view data source/delegate
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let i = inProgress ? beacons.count + 1 : beacons.count
        return i
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var adjustedSection = section
        
        if inProgress {
            if adjustedSection == 0 {
                return 1
            } else {
                adjustedSection -= 1
            }
        }
        
        let sectionValues = Array(beacons.values)
        return sectionValues[adjustedSection].count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var adjustedSection = section
        
        if inProgress  {
            if adjustedSection == 0 {
                return nil
            } else {
                adjustedSection -= 1
            }
        }
        
        let sectionKeys = Array(beacons.keys)
        let sectionKey = sectionKeys[adjustedSection]
        
        return sectionKey
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let beaconCellIdentifier = "BeaconCell"
        let progressCellIdentifier = "ProgressCell"
        var section = indexPath.section
        let identifier = (inProgress && section == 0) ? progressCellIdentifier : beaconCellIdentifier
        let cell : UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(identifier)
        
        if identifier == progressCellIdentifier {
            return cell as UITableViewCell
        } else if inProgress {
            section -= 1
        }
        
        let sectionKey = Array(beacons.keys)[section]
        if let beacon = beacons[sectionKey]?[indexPath.row] {
            cell.textLabel?.text = beacon.proximityUUID.UUIDString
            cell.detailTextLabel?.text = "Major: \(beacon.major), Minor: \(beacon.minor), Acc: \(beacon.accuracy)"
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let sectionKey = Array(beacons.keys)[indexPath.section]
        if let beacon = self.beacons[sectionKey]?[indexPath.section] {
            if !inProgress {
                
                let major = CLBeaconMajorValue(beacon.major.shortValue)
                let minor = CLBeaconMajorValue(beacon.minor.shortValue)
                let region = CLBeaconRegion(proximityUUID: beacon.proximityUUID, major: major, minor: minor, identifier: defaults.BeaconIdentifier)

                self.stopRangingAllRegions()
                
                calculator = CalibrationCalculator(region: region) { measuredPower, error in
                    if let error = error {
                        if (self.view.window != nil) {
                            let title = "Unable to calibrate device"
                            let cancelTitle = "OK"
                            let alert = UIAlertView(title: title, message: error.userInfo.description, delegate: nil, cancelButtonTitle: cancelTitle)
                            alert.show()
                            
                            self.startRangingAllRegions()
                        }
                    } else {
                        if let endViewController = self.storyboard?.instantiateViewControllerWithIdentifier("EndViewController") as? CalibrationEndViewController {
                            endViewController.measuredPower = measuredPower
                            self.navigationController?.pushViewController(endViewController, animated: true)
                        }
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if inProgress && indexPath.section == 0 {
            return 66.0
        }
        
        return 44.0
    }
}
