//
//  LocationTracker.swift
//  LocationSwift
//
//  Created by Phan Hong Viet on 1/14/16.
//  Copyright © 2016 Phan Hong Viet. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

let LATITUDE = "latitude"
let LONGITUDE = "longitude"
let ACCURACY = "theAccuracy"

let IS_OS_8_OR_LATER = Float(UIDevice.currentDevice().systemVersion) >= 8.0

class LocationTracker: NSObject {
  var myLastLocation: CLLocationCoordinate2D?
  var myLastLocationAccuracy: CLLocationAccuracy?
  var myLocation: CLLocationCoordinate2D?
  var myLocationAccuracy: CLLocationAccuracy?
  var shareModel: LocationShareModel?
  static var locationManager: CLLocationManager?
    
  override init() {
    super.init()
    //Get the share model and also initialize myLocationArray
    self.shareModel = LocationShareModel.sharedModel()
    self.shareModel?.myLocationArray = []
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationEnterBackground"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
  }
  
  static func sharedLocationManager() -> CLLocationManager? {
    objc_sync_enter(self)
      if locationManager == nil {
        locationManager = CLLocationManager()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        if #available(iOS 9.0, *) {
            locationManager?.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
        locationManager?.pausesLocationUpdatesAutomatically = false
      }
    objc_sync_exit(self)

    return locationManager
  }
  
  func applicationEnterBackground() {
    if let locationManager = LocationTracker.sharedLocationManager() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
      locationManager.distanceFilter = kCLDistanceFilterNone
      
      if (IS_OS_8_OR_LATER) {
        locationManager.requestAlwaysAuthorization()
      }
      locationManager.startUpdatingLocation()
      
      //Use the BackgroundTaskManager to manage all the background Task
      self.shareModel?.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
      self.shareModel?.bgTask?.beginNewBackgroundTask()
    }
  }
  
  func restartLocationUpdates() {
    
    print("restartLocationUpdates")
    
    if (self.shareModel?.timer != nil) {
      self.shareModel?.timer?.invalidate()
      self.shareModel?.timer = nil
    }
    
    if let locationManager = LocationTracker.sharedLocationManager() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
      locationManager.distanceFilter = kCLDistanceFilterNone
      
      if (IS_OS_8_OR_LATER) {
        locationManager.requestAlwaysAuthorization()
      }
      locationManager.startUpdatingLocation()
    }
  }
  
  func startLocationTracking() {
    print("startLocationTracking")
    if (!CLLocationManager.locationServicesEnabled()) {
      print("locationServicesEnabled false")
      
      let servicesDisabledAlert = UIAlertView(title: "Location Services Disabled", message: "You currently have all location services for this device disabled", delegate: nil, cancelButtonTitle: "OK")
      servicesDisabledAlert.show()
    } else {
      let authorizationStatus = CLLocationManager.authorizationStatus()
      
      if (authorizationStatus == CLAuthorizationStatus.Denied || authorizationStatus == CLAuthorizationStatus.Restricted) {
        print("authorizationStatus failed")
      } else {
        print("authorizationStatus authorized")
        
        if let locationManager = LocationTracker.sharedLocationManager() {
          
          locationManager.delegate = self
          locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
          locationManager.distanceFilter = kCLDistanceFilterNone

          if (IS_OS_8_OR_LATER) {
            locationManager.requestAlwaysAuthorization()
          }
          
          locationManager.startUpdatingLocation()
        }
      }
    }
  }
  
  func stopLocationTracking() {
    print("stopLocationTracking")
    
    if (self.shareModel?.timer != nil) {
      self.shareModel?.timer?.invalidate()
      self.shareModel?.timer = nil
    }
    
    if let locationManager = LocationTracker.sharedLocationManager() {
      locationManager.stopUpdatingLocation()
    }
  }
  
  func stopLocationDelayBy10Seconds() {
    if let locationManager = LocationTracker.sharedLocationManager() {
      locationManager.stopUpdatingLocation()
      
      print("locationManager stop Updating after 10 seconds")
    }
  }
  
  //Send the location to Server
  func updateLocationToServer() {
    print("updateLocationToServer")
    
    // Find the best location from the array based on accuracy
    var myBestLocation = [String:Double]()
    if let shareModel = self.shareModel {
      let count = shareModel.myLocationArray.count
      for i in 0..<count {
        let currentLocation = shareModel.myLocationArray[i]
        
        if i == 0 {
          myBestLocation = currentLocation
        } else {
          if currentLocation[ACCURACY] <= myBestLocation[ACCURACY] {
            myBestLocation = currentLocation
          }
        }
      }
    }
    
    print("My Best location ", dump(myBestLocation))
    
    //If the array is 0, get the last location
    //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
    if (self.shareModel?.myLocationArray.count == 0) {
      print("Unable to get location, use the last known location")
      
      self.myLocation = self.myLastLocation
      self.myLocationAccuracy = self.myLastLocationAccuracy
    } else {
      if let lat = myBestLocation[LATITUDE], long = myBestLocation[LONGITUDE] {
        let theBestLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        self.myLocation = theBestLocation
        self.myLocationAccuracy = myBestLocation[ACCURACY]
      }
      
    }
    
    print("Send to Server:")
    print("Latitude", self.myLocation?.latitude)
    print("Longitude", self.myLocation?.longitude)
    print("Accuracy", self.myLocationAccuracy)
    
    //TODO: Your code to send the self.myLocation and self.myLocationAccuracy to your server
    
    //After sending the location to the server successful, remember to clear the current array with the following code. It is to make sure that you clear up old location in the array and add the new locations from locationManager
    self.shareModel?.myLocationArray.removeAll()
    self.shareModel?.myLocationArray = []
  }
}

extension LocationTracker : CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    print("locationManager didUpdateLocations")
    
    for i in 0..<locations.count {
      let newLocation = locations[i]
      let theLocation = newLocation.coordinate
      let theAccuracy = newLocation.horizontalAccuracy
      
      let locationAge = -(newLocation.timestamp.timeIntervalSinceNow)
      if (locationAge > 30.0) {
        continue
      }
      
      //Select only valid location and also location with good accuracy
      if (theAccuracy > 0 && theAccuracy < 2000
          && (!(theLocation.latitude == 0.0 && theLocation.longitude == 0.0))) {
            
        self.myLastLocation = theLocation
        self.myLastLocationAccuracy = theAccuracy
            
        var dict = [String:Double]()
        
        dict[LATITUDE] = theLocation.latitude
        dict[LONGITUDE] = theLocation.longitude
        dict[ACCURACY] = theAccuracy
        
        //Add the vallid location with good accuracy into an array
        //Every 1 minute, I will select the best location based on accuracy and send to server
        self.shareModel?.myLocationArray.append(dict)
      }
    }
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.shareModel?.timer != nil) {
      return
    }
    
    self.shareModel?.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
    self.shareModel?.bgTask?.beginNewBackgroundTask()
    
    //Restart the locationMaanger after 1 minute
    self.shareModel?.timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("restartLocationUpdates"), userInfo: nil, repeats: false)
    
    //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
    //The location manager will only operate for 10 seconds to save battery
    if (self.shareModel?.delay10Seconds != nil) {
      self.shareModel?.delay10Seconds?.invalidate()
      self.shareModel?.delay10Seconds = nil
    }
    
    self.shareModel?.delay10Seconds = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("stopLocationDelayBy10Seconds"), userInfo: nil, repeats: false)
    
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    let errorCode = CLError(rawValue: error.code)!
    switch (errorCode) {
      case CLError.Network: // general, network-related error
        let alert = UIAlertView(title: "Network Error", message: "Please check your network connection.", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
        break
      case CLError.Denied:
        let alert = UIAlertView(title: "Enable Location Service", message: "You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services", delegate: self, cancelButtonTitle: "OK")
        alert.show()
        break
      default:
        break
    }
  }
}