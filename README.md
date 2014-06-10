AirLocatorSwift
===============

CoreLocation app for iBeacons written in Swift

##Description  
This is essentially a clone of the AirLocate app from the iOS 7 sample codes. It allows you to configure your device as an iBeacon as well as search to find other iBeacons nearby.

##Usage
AirLocatorSwift shows how to use `CLLocationManager` to monitor and range `CLBeaconRegion`.

You can configure an iOS device as a beacon as follows:

1. Obtain two iOS devices equipped with Bluetooth LE. One will be a target device, one will be a remote (calibration) device.

2. Load and launch this app on both devices.

3. Turn the target device into a beacon by selecting Configuration and turning on the Enabled switch.

4. Take the calibration device and move one meter away from the target device.

5. On the calibration device start the calibration process by selecting Calibration.

6. Choose the target device from the table view.

7. The calibration process will start. You should wave the calibration device from side-to-side while this process is running.

8. When the calibration process is done, it will show a calibrated RSSI value on the screen.

9. On the target device, go back to the Configuration screen and enter this value under Measured Power.

Note: The calibration process is optional, but recommended as it will fine-tune ranging for your environment.
You can configure an iOS device as a beacon without calibrating it by not specifying a measured power.
If a measured power is not specified, CoreLocation default to a pre-determined value.

Once you've setup your target device as a beacon, you can use this app to demo beacon ranging and monitoring.
To demo ranging, select Ranging from the remote device. `RangingViewController` ranges a set of `CLBeaconRegion`.
To demo monitoring, select Monitoring from the remote device. `MonitoringViewController` allows you to configure a `CLBeaconRegion` to monitor.
