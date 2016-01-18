//
//  LocationShareModel.swift
//  LocationSwift
//
//  Created by Phan Hong Viet on 1/14/16.
//  Copyright © 2016 Phan Hong Viet. All rights reserved.
//

import Foundation
import CoreLocation

class LocationShareModel {
  var timer: NSTimer?
  var delay10Seconds: NSTimer?
  var bgTask: BackgroundTaskManager?
  var myLocationArray = [[String:Double]]()
  
  static var sharedMyModel: LocationShareModel?
  static var onceToken: dispatch_once_t?

  static func sharedModel() -> LocationShareModel? {
    
    if let _ = self.onceToken {
      dispatch_once(&self.onceToken!) { () -> Void in
        sharedMyModel = LocationShareModel()
      }
    }
    
    return sharedMyModel
  }
}