//
//  AppDelegate.swift
//  TrackStock
//
//  Created by Arjun Kochhar on 9/19/15.
//  Copyright © 2015 Arjun Kochhar. All rights reserved.
//

import UIKit
import CSwiftV

// Default to 5 seconds for background fetch
let backgroundFetchInterval: NSTimeInterval = 5

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(backgroundFetchInterval)
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("performFetchWithCompletionHandler")
        // Fecth the data, compare and send notification here.
        for key in stockTrack.keys {
            let url = "https://download.finance.yahoo.com/d/quotes.csv?s=" + key + "&f=sl1d1t1c1ohgv&e=.csv"
            let dataUrl: NSURL? = NSURL(string: url)
            
            let session = NSURLSession.sharedSession().dataTaskWithURL(dataUrl!, completionHandler: { (data, response, error) -> Void in
                if data != nil
                {
                    let datastring = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
                    let csv = CSwiftV(String: datastring)
                    print("\(csv.headers[1])")
                    let setLimit = NSString(string: stockTrack[key]!).floatValue
                    let curValue = NSString(string: csv.headers[1]).floatValue
                    if curValue >= setLimit {
                        // Send out a notification.
                        let localNotification: UILocalNotification = UILocalNotification()
                        localNotification.alertAction = "Sending Limit Notification"
                        localNotification.soundName = UILocalNotificationDefaultSoundName
                        localNotification.alertBody = "Stock:" + key + " Set Limit:" + stockTrack[key]! + " Current Value:" + csv.headers[1]
                        localNotification.fireDate = NSDate(timeIntervalSinceNow: 0)
                        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                    }
                }
                
            })
            session.resume()
        }
        completionHandler(UIBackgroundFetchResult.NewData)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
    }
    
    
}