//
//  AppDelegate.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
                            
    var window: UIWindow?
    var locationManager = CLLocationManager()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        locationManager.delegate = self
        
        return true
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) -> Void {
        let notification = UILocalNotification()
        
        if state == .Inside {
            notification.alertBody = "You're inside the region"
        } else if state == .Outside {
            notification.alertBody = "You're outside the region"
        } else {
            return
        }
        
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) -> Void {
        let cancelButtonTitle = "OK"
        let alert = UIAlertView(title: notification.alertBody, message: nil, delegate: nil, cancelButtonTitle: cancelButtonTitle)
        alert.show()
    }

}

