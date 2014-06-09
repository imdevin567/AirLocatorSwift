//
//  CalibrationCalculator.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/9/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import CoreLocation

class CalibrationCalculator : NSObject, CLLocationManagerDelegate {
    let CalibrationDwell = 20.0
    let AppErrorDomain = "com.ios.imdevin567.AirLocatorSwift"
    
    typealias CalibrationProgressHandler = (percentComplete: Double) -> Void
    typealias CalibrationCompletionHandler = (measuredPower: Int, error: NSError) -> Void
    
    var progressHandler : CalibrationProgressHandler?
    var completionHandler : CalibrationCompletionHandler?
    
    var locationManager = CLLocationManager()
    var region : CLBeaconRegion?
    var calibrating : Bool?
    var rangedBeacons = Array<AnyObject[]>()
    var timer : NSTimer?
    var percentComplete : Double = 0
    
    func initWithRegion(region: CLBeaconRegion, completionHandler handler: CalibrationCompletionHandler) -> AnyObject {
        self.locationManager.delegate = self
        self.region = region
        self.completionHandler = handler
        
        return self
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: AnyObject[]!, inRegion region: CLBeaconRegion!) {
        // Begin lock
        objc_sync_enter(self)
        
        rangedBeacons += beacons
        
        if progressHandler != nil {
            dispatch_async(dispatch_get_main_queue()) {
                var addPercent = 1.0 / self.CalibrationDwell
                self.percentComplete += addPercent
                self.progressHandler?(percentComplete: self.percentComplete)
            }
        }
        
        // End lock
        objc_sync_exit(self)
    }
    
    func performCalibrationWithProgressHandler(handler: CalibrationProgressHandler) {
        // Begin lock
        objc_sync_enter(self)
        
        if !calibrating {
            calibrating = true
            rangedBeacons.removeAll(keepCapacity: false)
            percentComplete = 0
            progressHandler = handler
            
            locationManager.startRangingBeaconsInRegion(region)
            
            timer = NSTimer(fireDate: NSDate(timeIntervalSinceNow: CalibrationDwell), interval: 0, target: self, selector: Selector("timerElapsed"), userInfo: nil, repeats: false)
            
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
        } else {
            let errorString = "Calibration is already in progress"
            let userInfo = ["Error string": errorString]
            let error = NSError(domain: AppErrorDomain, code: 4, userInfo: userInfo)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.completionHandler!(measuredPower: 0, error: error)
            }
        }
        
        // End lock
        objc_sync_exit(self)
    }
    
    func cancelCalibration() {
        // Begin lock
        objc_sync_enter(self)
        
        if calibrating {
            calibrating = false
            timer?.fire()
        }
        
        // End lock
        objc_sync_exit(self)
    }
    
    func timerElapsed(sender: AnyObject?) {
        // Begin lock
        objc_sync_enter(self)
        
        locationManager.stopRangingBeaconsInRegion(region)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // Begin more locks
            objc_sync_enter(self)
            
            var error : NSError? = nil
            var allBeacons = NSMutableArray()
            var measuredPower = 0
            
            if !self.calibrating {
                let errorString = "Calibration was cancelled"
                let userInfo = ["Error string": errorString]
                error = NSError.errorWithDomain(self.AppErrorDomain, code: 2, userInfo: userInfo)
            } else {
                func enumBlock(index: Int, object: AnyObject[], inout stop: Bool) -> Void {
                    if object.count > 1 {
                        let errorString = "More than one beacon of the specified type was found"
                        let userInfo = ["Error string": errorString]
                        error = NSError(domain: self.AppErrorDomain, code: 1, userInfo: userInfo)
                    } else {
                        allBeacons.addObjectsFromArray(object)
                    }
                }
                
                for (index, object) in enumerate(self.rangedBeacons) {
                    var stop = false
                    enumBlock(index, object, &stop)
                    
                    if stop {
                        break
                    }
                }
                
                if allBeacons.count <= 0 {
                    let errorString = "No beacon of the specified type was found"
                    let userInfo = ["Error string": errorString]
                    error = NSError(domain: self.AppErrorDomain, code: 3, userInfo: userInfo)
                } else {
                    let outlierPadding = Double(allBeacons.count) * 0.1
                    let sortDescriptor = [NSSortDescriptor(key: "rssi", ascending: true)]
                    allBeacons.sortUsingDescriptors(sortDescriptor)
                    let len = Double(allBeacons.count) - (outlierPadding * 2)
                    let range = NSMakeRange(outlierPadding.bridgeToObjectiveC().integerValue, len.bridgeToObjectiveC().integerValue)
                    let sample = allBeacons.subarrayWithRange(range)
                    measuredPower = sample.bridgeToObjectiveC().valueForKeyPath("@avg.rssi").integerValue
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.completionHandler!(measuredPower: measuredPower, error: error!)
            }
            
            self.calibrating = false
            self.rangedBeacons.removeAll(keepCapacity: false)
            self.progressHandler = nil
            
            objc_sync_exit(self)
        }
        
        // End lock
        objc_sync_exit(self)
    }
}
