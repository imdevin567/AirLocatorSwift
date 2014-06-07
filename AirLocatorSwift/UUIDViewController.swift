//
//  UUIDViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit


class UUIDViewController: UITableViewController {
    var uuid: NSUUID?
    let defaults = Defaults()
    
    // MARK: Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return defaults.supportedProximityUUIDs.count
    }

    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let CellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath:indexPath) as UITableViewCell
        
        if indexPath.row < defaults.supportedProximityUUIDs.count {
            cell.textLabel.text = defaults.supportedProximityUUIDs[indexPath.row].UUIDString
            
            if self.uuid == defaults.supportedProximityUUIDs[indexPath.row] {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
        }
        
        return cell
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        let selectionIndexPath = tableView.indexPathForSelectedRow()
        var selection = 0
        
        if selectionIndexPath.row < defaults.supportedProximityUUIDs.count {
            selection = selectionIndexPath.row
        }
        
        uuid = defaults.supportedProximityUUIDs[selection]
    }
}