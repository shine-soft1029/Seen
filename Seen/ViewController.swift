//
//  ViewController.swift
//  Seen
//
//  Created by Alexander Wiegand on 1/28/15.
//  Copyright (c) 2015 Alexander Wiegand. All rights reserved.
//

import UIKit

import Parse

class ViewController: UIViewController, UIScrollViewDelegate, DraggableViewDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var imgArray:NSMutableArray = []			// Image data from Parse
    var userArray:NSMutableArray = []			// User data from Parse
    
    var dataArray:NSMutableArray = []			// array that has images and users data as NSDictionary
    
    var viewLoadedIndex:NSInteger = 0;			// loaded draggable view count
    var loadedView:NSMutableArray = []			// loaded draggable view array
    var allViews:NSMutableArray = []			// all draggable view array
    
    let MAX_BUFFER_SIZE = 2						// Buffer to load draggable view
    var viewHeight:CGFloat = 0
    var viewWidth:CGFloat = 0
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change Navigation title
        self.title = "Discover"
        
        loadedView = NSMutableArray()
        allViews = NSMutableArray()
        viewLoadedIndex = 0
        
        // Get all Image data from Parse
        var imgQuery = PFQuery(className: "userImages")
        imgQuery.findObjectsInBackgroundWithBlock { (objects:[AnyObject]!, error:NSError!) -> Void in
            if error == nil {
                self.imgArray = NSMutableArray(array: objects)			// Initialize the image array from the result
                
                // Get all user data from Parse
                var userQuery = PFUser.query()
                // You can set the filter value on here
                userQuery.whereKey("eyeColor", equalTo: "Green")
                //                userQuery.whereKey("gender", equalTo: "male")
                //                userQuery.whereKey("hairColor", equalTo: "Brown")
                //                userQuery.whereKey("hairLength", equalTo: "Long")
                //                userQuery.whereKey("profession", containsString: "Model")
                
                userQuery.findObjectsInBackgroundWithBlock { (objects:[AnyObject]!, error:NSError!) -> Void in
                    if error == nil {
                        self.userArray = NSMutableArray(array: objects)
                        if self.userArray.count > 0 {
                            self.dataArray = NSMutableArray(capacity: self.userArray.count)		// Initialize the data array
                            self.filterImageArray()		// filter the data array from image and user data
                            
                            self.activityIndicator.stopAnimating()
                            self.loadImagesViews()		// load draggable view from the dataArray
                        } else {
                            var alert = UIAlertView(title: "Filter", message: "No users in DB", delegate: nil, cancelButtonTitle: "OK")
                            alert.show()
                        }
                        
                    } else {
                        NSLog("%@", error.userInfo!)
                    }
                }
            } else {
                NSLog("%@", error.description);
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    
    // MARK: - Functions
    
    // Create one draggable View
    func createDraggableViewWithDataAtIndex(index:NSInteger)->DraggableViewController {
        // Get DraggableViewController with storyid
        var storyboard = UIStoryboard(name:"Main", bundle: nil)
        var dView = storyboard.instantiateViewControllerWithIdentifier("DraggableViewController") as DraggableViewController
        
        dView.view.frame = CGRectMake(10, 74, self.view.frame.size.width - 20, self.view.frame.size.height - 84)
        dView.userData = NSDictionary(dictionary: dataArray.objectAtIndex(index) as NSDictionary)		// set data for this view
        dView.delegate = self
        return dView
    }
    
    // load draggable view from the dataArray
    func loadImagesViews() {
        if dataArray.count > 0 {
            var numLoadedViewCap:NSInteger = (dataArray.count > MAX_BUFFER_SIZE) ? MAX_BUFFER_SIZE : dataArray.count	// count to load data
            
            for i in 0..<dataArray.count {
                var dView:DraggableViewController = self.createDraggableViewWithDataAtIndex(i)
                allViews.addObject(dView)
                
                if i < numLoadedViewCap {
                    loadedView.addObject(dView)		// Initialize the draggable view array
                }
            }
            
            // add draggable views to current view
            for j in 0..<loadedView.count {
                if j > 0 {
                    self.view.insertSubview((loadedView.objectAtIndex(j) as UIViewController).view, belowSubview:(loadedView.objectAtIndex(j - 1) as UIViewController).view)
                } else {
                    self.view.addSubview((loadedView.objectAtIndex(j) as UIViewController).view)
                }
                
                viewLoadedIndex += 1
            }
        }
    }
    
    // Filter images from users filter
    func filterImageArray() {
        for object in self.userArray {
            
            var images = NSMutableArray()
            var imgCount = 0
            for imageObject in self.imgArray {
                var username = object.objectForKey("username") as NSString
                if username.isEqualToString(imageObject.objectForKey("username") as NSString) {
                    images.addObject(imageObject.objectForKey("mainImage")!)
                    imgCount += 1
                }
                
                if imgCount == 2 {
                    break;
                }
            }
            
            self.dataArray.addObject(NSDictionary(objectsAndKeys: object, "user", images, "image"))
        }
        
    }
    
    // add next draggable view to current view
    func addNextView() {
        if viewLoadedIndex < allViews.count {
            loadedView.addObject(allViews.objectAtIndex(viewLoadedIndex))
            viewLoadedIndex += 1
            self.view.insertSubview((loadedView.objectAtIndex(MAX_BUFFER_SIZE - 1) as UIViewController).view, belowSubview:(loadedView.objectAtIndex(MAX_BUFFER_SIZE - 2) as UIViewController).view)
        }
    }
    
    // MARK: - IBActions
    @IBAction func showDetail(sender: AnyObject) {
        
    }
    
    
    @IBAction func newButtonPressed(sender: AnyObject) {
    }
    
    @IBAction func menuButtonPressed(sender: AnyObject) {
    }
    
    // MARK: -DraggableViewControllerDelegate
    func viewSwipedLeft(card: UIView) {
        loadedView.removeObjectAtIndex(0)
        
        NSTimer.scheduledTimerWithTimeInterval(0.1, target:self, selector:Selector("addNextView"), userInfo:nil, repeats:false)
    }
    
    func viewSwipedRight(card: UIView) {
        loadedView.removeObjectAtIndex(0)
        
        NSTimer.scheduledTimerWithTimeInterval(0.1, target:self, selector:Selector("addNextView"), userInfo:nil, repeats:false)
    }
}

