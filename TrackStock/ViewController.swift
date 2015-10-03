//
//  ViewController.swift
//  TrackStock
//
//  Created by Arjun Kochhar on 9/19/15.
//  Copyright © 2015 Arjun Kochhar. All rights reserved.
//

import UIKit
import BTNavigationDropdownMenu
import CSwiftV

// Actual dictionary storing the value set by the user and the ticker symbol
var stockTrack = [String:String]()

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSURLConnectionDataDelegate, UISearchBarDelegate {

    // TODO: Request Notifications and fetch and notify user of the value
    // Make sure the entry user is adding is not repeating, and update the value when he adds it.
    // Add Code to delete the entry from the table View.
    // Add Code to update the entry from the table View.
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    // Read the contents of .csv file
    lazy var data = NSMutableData()
    
    var menuView: BTNavigationDropdownMenu!
    
    // Standard arrays to fetch fields from the data read from .csv file.
    var array = [String]() // ticker and Company
    var arr = [String]() // tickers
    var rows = [[String]]()
    var stocks = ["NYSE", "NASDAQ", "AMEX"]
    var ticker:String = ""
    
    // Store and Restore the data entered by the user
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
    
        self.view.addSubview(activityIndicator)
        self.view.addSubview(self.tableView)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        // Restore the stored data
        if let dict = self.defaults.objectForKey("SavedData") as? [String: String]? ?? [String: String]()
        {
            stockTrack = dict
            self.tableView.reloadData()
        }
        
        // Get the ticker symbols, just the NYSE stocks for now
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            //Background Thread
            if self.array.isEmpty
            {
                self.activityIndicator.startAnimating()
                for stock in self.stocks {
                    let path = NSBundle.mainBundle().pathForResource(stock, ofType: "csv")
                    do {
                        let data = try String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
                        let csv = CSwiftV(String: data)
                        self.rows = csv.rows
                        for row in self.rows {
                            self.array.append(row[0] + " (" + row[1] + ") ")
                            self.arr.append(row[0])
                        }
                        self.array.sortInPlace()
                        self.arr.sortInPlace()
                    } catch  let error {
                        print("\(error)")
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                //Run UI Updates
                self.activityIndicator.stopAnimating()
                self.navigationController?.navigationBar.translucent = true
                self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.0/255.0, green:180/255.0, blue:220/255.0, alpha: 1.0)
                self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
                
                let menuView = BTNavigationDropdownMenu(title: "Pick Stock to Track", items: self.array)
                menuView.cellHeight = 50
                menuView.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
                menuView.cellSelectionColor = UIColor(red: 0.0/255.0, green:160.0/255.0, blue:195.0/255.0, alpha: 0.75)
                menuView.cellTextLabelColor = UIColor.whiteColor()
                menuView.cellTextLabelFont = UIFont(name: "Avenir-Heavy", size: 17)
                menuView.arrowPadding = 15
                menuView.animationDuration = 0.25
                menuView.maskBackgroundColor = UIColor.blackColor()
                menuView.maskBackgroundOpacity = 0.3
                
                menuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
                    print("Did select item at index: \(indexPath)")
                    
                    self.ticker = self.arr[indexPath]
                    print("\(self.ticker)")
                    
                    // Get the stock data JSON from quandl's stock API
                    // Change api_key <API_KEY> with the key generated at https://www.quandl.com/tools/api
                    let urlPath: String = "https://www.quandl.com/api/v3/datasets/WIKI/" + self.ticker + ".json" + "?api_key=<API_KEY>&limit=1"
                    let url: NSURL? = NSURL(string: urlPath)
                    
                    // Show network/activity indicators
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    self.activityIndicator.startAnimating()
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),
                    {
                        //Background Thread
                        if let dataUrl = url as NSURL!
                        {
                            let session = NSURLSession.sharedSession().dataTaskWithURL(dataUrl, completionHandler: { (data, response, error) -> Void in
                                // Handle the response
                                dispatch_async(dispatch_get_main_queue(), {
                                    //UI Updates
                                    do
                                    {
                                        // Read the JSON data received via URL session
                                        var found = false
                                        let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                                        if let datajson = jsonResult["dataset"] as? NSDictionary
                                        {
                                            let json = datajson["data"] as! NSArray
                                            let token = self.ticker +  " High:" + String(json[0][2]) + " Low:" + String(json[0][3])
                                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                            self.activityIndicator.stopAnimating()
                                            
                                            for stock in stockTrack.keys {
                                                if (stock == self.ticker)
                                                {
                                                  found = true
                                                  break
                                                }
                                            }
                                            
                                            if (!found)
                                            {
                                                self.showAlert("Please set the stock limit for ", placeholder: "Stock limit value", token: token, firstButton: "Cancel", secondButton: "Confirm")
                                            }
                                            else
                                            {
                                                self.showAlert("Stock already exists.Set new value. ", placeholder: "Stock limit value", token: token, firstButton: "Cancel", secondButton: "Confirm")
                                            }
                                        }
                                        else
                                        {
                                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                            self.activityIndicator.stopAnimating()
                                            self.handleError("Unable to fetch the stock")

                                        }
                                    } catch let error {
                                        print("\(error)")
                                    }
                                })
                            });
                            session.resume()
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), {
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            self.activityIndicator.stopAnimating()
                            self.handleError("Stock URL is invalid or null")
                        })
                    }
                    });
                }
                self.navigationItem.titleView = menuView
            });
        });
    }
    
    func showAlert(title: String, placeholder: String, token: String, firstButton: String, secondButton: String)
    {
        let alert = UIAlertController(title: title, message: token, preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textfield) -> Void in
            textfield.placeholder = placeholder
            textfield.keyboardType = UIKeyboardType.DecimalPad
        })
        
        switch firstButton {
            case "Cancel":
                alert.addAction(UIAlertAction(title: firstButton, style: .Cancel, handler: { (alert: UIAlertAction) -> Void in
                    // do nothing
                }))
            
            default:
                break
        }
        
        switch secondButton {
            case "Confirm", "Edit":
                alert.addAction(UIAlertAction(title: secondButton, style: .Default, handler: { (action: UIAlertAction) -> Void in
                    // Handle the value
                    let tf = alert.textFields?.first as UITextField?
                    if (tf != nil && tf!.text! != ""){
                        print("\(tf!.text!)")
                        stockTrack[self.ticker] = tf!.text!
                        self.defaults.setObject(stockTrack, forKey: "SavedData")
                        self.tableView.reloadData()
                    }
                }))
            
            default:
                break
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func handleError(string: String) {
        // Failed to fetch the data, ignore or retry(TODO)
        let alert = UIAlertController(title: string, message: nil, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { (alert: UIAlertAction) -> Void in
            // Do nothing
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // TableView Delegates
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected cell \(indexPath.row)!")
        let index = stockTrack.startIndex.advancedBy(indexPath.row)
        self.ticker = stockTrack.keys[index]
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        (cell!.accessoryView as! UIActivityIndicatorView).startAnimating()
        
        // Just get the latest set of stock values
        let urlPath: String = "https://www.quandl.com/api/v3/datasets/WIKI/" + self.ticker + ".json" + "?api_key=wmy2SFbHQfxs-GzTNhxM&limit=1"
        let url: NSURL = NSURL(string: urlPath)!
        
        // Show network/activity indicators
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),
            {
                //Background Thread
                let session = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
                    // Handle the response
                    dispatch_async(dispatch_get_main_queue(), {
                        //UI Updates
                        do
                        {
                            // Read the JSON data received via URL session
                            let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                            (cell!.accessoryView as! UIActivityIndicatorView).stopAnimating()
                            if let datajson = jsonResult["dataset"] as? NSDictionary
                            {
                                let json = datajson["data"] as! NSArray
                                let token = self.ticker +  " High:" + String(json[0][2]) + " Low:" + String(json[0][3])
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                                self.showAlert("Set a new limit", placeholder: stockTrack.values[index], token: token, firstButton: "Cancel", secondButton: "Edit")
                            }
                            else
                            {
                                // Failed to fetch the data, ignore or retry(TODO)
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                (cell!.accessoryView as! UIActivityIndicatorView).stopAnimating()
                                self.handleError("Unable to fetch the stock")
                            }
                        } catch let error {
                            print("\(error)")
                        }
                    })
                });
                session.resume()
        });
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stockTrack.count
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            let index = stockTrack.startIndex.advancedBy(indexPath.row)
            stockTrack[stockTrack.keys[index]] = nil
            self.tableView.reloadData()
            self.defaults.setObject(stockTrack, forKey: "SavedData")
            
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell!
        let index = stockTrack.startIndex.advancedBy(indexPath.row)
        cell.textLabel?.text = stockTrack.keys[index]
        cell.detailTextLabel?.text = "Limit:" + stockTrack.values[index]
        cell.accessoryView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        return cell
    }

}

