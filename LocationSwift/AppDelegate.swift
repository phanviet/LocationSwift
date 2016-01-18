//
//  AppDelegate.swift
//  LocationSwift
//
//  Created by Phan Hong Viet on 1/14/16.
//  Copyright © 2016 Phan Hong Viet. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var locationTracker: LocationTracker?
  var locationUpdateTimer: NSTimer?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if(UIApplication.sharedApplication().backgroundRefreshStatus == UIBackgroundRefreshStatus.Denied) {
      let alert = UIAlertView(title: "", message: "The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh", delegate: nil, cancelButtonTitle: "OK")
      
      alert.show()
    } else if(UIApplication.sharedApplication().backgroundRefreshStatus == UIBackgroundRefreshStatus.Restricted) {
      let alert = UIAlertView(title: "", message: "The functions of this app are limited because the Background App Refresh is disable.", delegate: nil, cancelButtonTitle: "OK")
      
      alert.show()
    } else {
      self.locationTracker = LocationTracker()
      self.locationTracker?.startLocationTracking()
      
      //Send the best location to server every 60 seconds
      //You may adjust the time interval depends on the need of your app.
      let time: NSTimeInterval = 60.0
      self.locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: Selector("updateLocation"), userInfo: nil, repeats: true)
      
    }
    
    return true
  }
  
  func updateLocation() {
    print("updateLocation")
    
    self.locationTracker?.updateLocationToServer()
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

