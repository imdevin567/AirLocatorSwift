//
//  RangingViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class RangingViewController : UITableViewController, CLLocationManagerDelegate {
    var beacons = Dictionary<String, AnyObject[]>()
    var locationManager = CLLocationManager()
    var rangedRegions = Array<CLBeaconRegion>()
    var proximityBeacons : AnyObject[]?
    
    var immediates = CLBeacon[]()
    var unknowns = CLBeacon[]()
    var fars = CLBeacon[]()
    var nears = CLBeacon[]()
    
    let defaults = Defaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        for (uuid) in defaults.supportedProximityUUIDs {
            let region = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.UUIDString)
            rangedRegions += region
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        for (region) in rangedRegions {
            locationManager.startRangingBeaconsInRegion(region)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        for (region) in rangedRegions {
            locationManager.stopRangingBeaconsInRegion(region)
        }
    }
    
    // MARK: Location manager delegate

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

    // MARK: Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return self.beacons.count
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        var sectionValues = Array(self.beacons.values)
        return sectionValues[section].count
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        var sectionKeys = Array(self.beacons.keys)
        var sectionKey : String = sectionKeys[section]
        
        return sectionKey
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let identifier = "Cell"
        var cell : AnyObject! = tableView.dequeueReusableCellWithIdentifier(identifier)
        var sectionKey = Array(self.beacons.keys)[indexPath.section]
        var beacon : AnyObject? = self.beacons[sectionKey]?[indexPath.section]
        
        if var cellLabel = cell.textLabel {
            cellLabel.text = beacon!.proximityUUID.value!.UUIDString
        }
        
        if var cellDetailTextLabel = cell.detailTextLabel {
            cellDetailTextLabel.text = "Major: \(beacon?.major), Minor: \(beacon?.minor), Acc: \(beacon?.accuracy)"
        }
        
        return cell as UITableViewCell
    }
    
}
