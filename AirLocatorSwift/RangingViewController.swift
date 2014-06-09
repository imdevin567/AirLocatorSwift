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
    var rangedRegions = NSMutableDictionary()
    var proximityBeacons : AnyObject[]?
    
    let defaults = Defaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        for (uuid) in defaults.supportedProximityUUIDs {
            var region = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.UUIDString)
            rangedRegions[region] = NSArray()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        for (region : AnyObject, value : AnyObject) in rangedRegions {
            locationManager.startRangingBeaconsInRegion(region as CLBeaconRegion)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        for (region : AnyObject, value : AnyObject) in rangedRegions {
            locationManager.stopRangingBeaconsInRegion(region as CLBeaconRegion)
        }
    }
    
    // MARK: Location manager delegate
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: AnyObject[]!, inRegion region: CLBeaconRegion!) {
        rangedRegions[region] = beacons
        
        var allBeacons = NSMutableArray.array()
        allBeacons.addObjectsFromArray(rangedRegions.allValues)
        
        let clProximities = [CLProximity.Unknown, CLProximity.Immediate, CLProximity.Near, CLProximity.Far]
        
        for (range) in clProximities {
            var proximityPredicate = NSPredicate(format: "proximity = \(range.toRaw())", argumentArray: nil)
            self.proximityBeacons = allBeacons.filteredArrayUsingPredicate(proximityPredicate)
            
            if self.proximityBeacons?.count > 0 {
                switch range {
                    case .Unknown:
                        self.beacons["Unknown"] = self.proximityBeacons
                    case .Immediate:
                        self.beacons["Immediate"] = self.proximityBeacons
                    case .Near:
                        self.beacons["Near"] = self.proximityBeacons
                    case .Far:
                        self.beacons["Far"] = self.proximityBeacons
                    default:
                        println() // Do nothing here
                }
            }
        }
        
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
