//
//  BackgroundTaskManager.swift
//  LocationSwift
//
//  Created by Phan Hong Viet on 1/14/16.
//  Copyright © 2016 Phan Hong Viet. All rights reserved.
//

import Foundation
import UIKit

extension Array where Element : Equatable {

    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}

class BackgroundTaskManager {

  var bgTaskIdList = [UIBackgroundTaskIdentifier]()
  var masterTaskId: UIBackgroundTaskIdentifier
  
  static var sharedBGTaskManager: BackgroundTaskManager?
  static var onceToken: dispatch_once_t?

  init() {
    bgTaskIdList = []
    masterTaskId = UIBackgroundTaskInvalid
  }

  static func sharedBackgroundTaskManager() -> BackgroundTaskManager? {
    
    if let _ = self.onceToken {
      dispatch_once(&onceToken!) { () -> Void in
        sharedBGTaskManager = BackgroundTaskManager()
      }
    }
    
    return sharedBGTaskManager
  }
  
  func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
    let application = UIApplication.sharedApplication()
    
    var bgTaskId = UIBackgroundTaskInvalid
    if (application.respondsToSelector(Selector("beginBackgroundTaskWithExpirationHandler"))) {
      bgTaskId = application.beginBackgroundTaskWithExpirationHandler({ () -> Void in
        print(String(format: "background task %lu expired", bgTaskId))
        
        self.bgTaskIdList.removeObject(bgTaskId)
        application.endBackgroundTask(bgTaskId)
        bgTaskId = UIBackgroundTaskInvalid
      })
      
      if (self.masterTaskId == UIBackgroundTaskInvalid) {
        self.masterTaskId = bgTaskId
        print(String(format: "started master task %lu", self.masterTaskId))
      } else {
        print(String(format: "started background task %lu", bgTaskId))
        
        self.bgTaskIdList.append(bgTaskId)
        self.endBackgroundTasks()
      }
    }
    
    return bgTaskId
  }
  
  func endBackgroundTasks() {
    self.drainBGTaskList(false)
  }
  
  func endAllBackgroundTasks() {
    self.drainBGTaskList(true)
  }
  
  func drainBGTaskList(all: Bool) {
    //mark end of each of our background task
    let application = UIApplication.sharedApplication()
    
    if (application.respondsToSelector(Selector("endBackgroundTask"))) {
      let count = self.bgTaskIdList.count
      let start = all ? 0 : 1
      for _ in start..<count {
        let bgTaskId: UIBackgroundTaskIdentifier = self.bgTaskIdList[0]
        
        print(String(format: "ending background task with id -%lu", bgTaskId))
        
        application.endBackgroundTask(bgTaskId)
        self.bgTaskIdList.removeAtIndex(0)
      }
      
      if (self.bgTaskIdList.count > 0) {
        print(String(format: "kept background task id %@"))
      }
      
      if (all) {
        print("no more background tasks running")
        application.endBackgroundTask(self.masterTaskId)
        self.masterTaskId = UIBackgroundTaskInvalid
      } else {
        print(String(format: "kept master background task id %lu", self.masterTaskId))
      }
    }
  }
}