//
//  DraggableViewController.swift
//  Seen
//
//  Created by Alexander Wiegand on 2/5/15.
//  Copyright (c) 2015 Alexander Wiegand. All rights reserved.
//

import UIKit

import Parse

// integration for Draggable Delegate
protocol DraggableViewDelegate {
    func viewSwipedLeft(card:UIView)		// Swipe for Left
    func viewSwipedRight(card:UIView)		// Swipe for Right
}

class DraggableViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var detailView: UIView!
    
    var delegate:DraggableViewDelegate?
    
    // Values for swipe animation
    var xFromCenter:CGFloat = 0.0
    var yFromCenter:CGFloat = 0.0
    var originalPoint:CGPoint = CGPointZero
    
    // Constance for swipe animation
    let ACTION_MARGIN:CGFloat = 120 // distance from center where the action applies. Higher = swipe further in order for the action to be called
    let SCALE_STRENGTH:CGFloat = 4 // how quickly the card shrinks. Higher = slower shrinking
    let SCALE_MAX:CGFloat = 0.93 // upper bar for how much the card shrinks. Higher = shrinks less
    let ROTATION_MAX:CGFloat = 1 // the maximum rotation allowed in radians.  Higher = card can keep rotating longer
    let ROTATION_STRENGTH:CGFloat = 320 // strength of rotation. Higher = weaker rotation
    let ROTATION_ANGLE = CGFloat(M_PI) / 8.0 // Higher = stronger rotation angle
    
    // User data  from Parse
    var userData:NSDictionary = NSDictionary()
    
    // Values for Scroll View
    var numberPages = 0
    var controllers:NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Set corner Radius for Views
        scrollView.layer.cornerRadius = 5
        detailView.layer.cornerRadius = 5
        self.view.layer.cornerRadius = 5
        
        // Change pagecontrol view direction
        pageControl.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // layout the scrollview and detailView
        self.scrollView.frame = self.view.frame
        self.detailView.frame = CGRectMake(self.detailView.frame.origin.x, self.scrollView.frame.size.height - self.detailView.frame.size.height - 20, self.detailView.frame.size.width, self.detailView.frame.size.height)
        
        // show username, gender, location
        let image:NSMutableArray = userData.objectForKey("image") as NSMutableArray
        
        let fUser:PFUser = userData.objectForKey("user") as PFUser
        self.lblUserName.text = fUser.objectForKey("username") as NSString
        self.lblLocation.text = NSString(format: "%@. %@", fUser.objectForKey("gender") as NSString, fUser.objectForKey("Location") as NSString)
        
        // Init PageControl
        self.numberPages = image.count
        self.controllers = NSMutableArray()		// Initialize the image view array
        
        for i in 0..<self.numberPages {
            self.controllers.addObject(NSNull())
        }
        
        // a page is the height of the scroll view
        self.scrollView.pagingEnabled = true
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame) * CGFloat(self.numberPages))
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.scrollsToTop = false
        self.scrollView.delegate = self
        
        self.pageControl.numberOfPages = self.numberPages
        self.pageControl.currentPage = 0
        
        self.gotoPage(false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions
    
    // Get Page instance from page number
    func loadScrollViewWithPage(page:NSInteger) {
        
        if ((page >= (userData.objectForKey("image") as NSMutableArray).count) || (page < 0)) {
            return;
        }
        
        var imgViewObject: AnyObject = self.controllers.objectAtIndex(page)
        if imgViewObject is NSNull {
            
            // get Image file from PFFile Object and create UIImageView from the image
            let imageObject = userData.objectForKey("image") as NSMutableArray
            let imageFile = imageObject.objectAtIndex(page) as PFFile
            
            let imageData = imageFile.getData()
            let image = UIImage(data:imageData)
            
            var imgView = UIImageView(image: image) as UIImageView
            imgView.contentMode = UIViewContentMode.ScaleAspectFill
            
            self.controllers .replaceObjectAtIndex(page, withObject: imgView)
            
            // add UIImageView to scrollview
            if imgView.superview == nil {
                var frame = self.scrollView.frame
                frame.origin.x = 0
                frame.origin.y = CGRectGetHeight(self.scrollView.frame) * CGFloat(page)
                
                imgView.frame = frame
                
                self.scrollView.addSubview(imgView)
                
                activityIndicator.stopAnimating()
                self.detailButton.hidden = false
            }
        }
    }
    
    // Load ImageView Data on ScrollView
    func gotoPage(animated:Bool) {
        let page = pageControl.currentPage
        
        // update the scroll view to the appropriate page
        self.loadScrollViewWithPage(page - 1)
        self.loadScrollViewWithPage(page)
        self.loadScrollViewWithPage(page + 1)
        
        // update the scroll view to the appropriate page
        var frame = scrollView.frame
        frame.origin.x = 0
        frame.origin.y = CGRectGetHeight(frame) * CGFloat(page)
        scrollView.scrollRectToVisible(frame, animated: animated)
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        // Switch the indicator when more that 50% of the previous/next page is visible
        let pageHeight = CGRectGetHeight(scrollView.frame)
        let page = floor((scrollView.contentOffset.y - pageHeight / 2) / pageHeight) + 1		// Get next page index from contentOffset
        pageControl.currentPage = Int(page)
        self.gotoPage(false)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Check scroll enabling from the contentOffset
        if ((scrollView.contentOffset.y < 0) || (scrollView.contentOffset.y > CGRectGetHeight(scrollView.frame) * CGFloat(self.numberPages)) || (scrollView.contentOffset.x > CGRectGetWidth(scrollView.frame)) || (scrollView.contentOffset.x < 0)) {
            scrollView.scrollEnabled = false
        } else {
            scrollView.scrollEnabled = true
        }
    }
    
    // MARK: - IBActions
    @IBAction func showDetail(sender: AnyObject) {
        
    }
    
    @IBAction func pageValueChanged(sender: AnyObject) {
        self.gotoPage(true)
    }
    
    // MARK: - Gesture Functions
    // called when you move your finger across the screen.
    // called many times a second
    @IBAction func beginDragged(gestureRecognizer: UIPanGestureRecognizer) {
        
        // extracts the coordinate data from your swipe movement.
        xFromCenter = gestureRecognizer.translationInView(self.view).x
        yFromCenter = gestureRecognizer.translationInView(self.view).y
        
        // checks what state the gesture is in. (starting, letting go, middle of the swipe)
        switch (gestureRecognizer.state) {
            
            // just started swiping
        case UIGestureRecognizerState.Began:
            self.originalPoint = self.view.center
            break;
            
            // in the middle of a swipe
        case UIGestureRecognizerState.Changed:
            // dictates rotation
            var rotationStrength = min(xFromCenter / ROTATION_STRENGTH, ROTATION_MAX)
            
            // degree change in radians
            var rotationAngel = ROTATION_ANGLE * rotationStrength
            
            // amount the height changes when you move the card up to a certain point
            var scale = max(1 - CGFloat.abs(rotationStrength) / SCALE_STRENGTH, SCALE_MAX)
            
            // move the object's center by center + gesture coordinate
            self.view.center = CGPointMake(self.originalPoint.x + xFromCenter, self.originalPoint.y + yFromCenter)
            
            // rotate by certain amount
            var transform:CGAffineTransform = CGAffineTransformMakeRotation(rotationAngel)
            
            // scale by certain amount
            var scaleTransform:CGAffineTransform = CGAffineTransformScale(transform, scale, scale)
            
            // apply transformations
            self.view.transform = scaleTransform
            
            break;
            
            //%%% go of the view
        case UIGestureRecognizerState.Ended:
            self.afterSwipeAction()
            break;
        case UIGestureRecognizerState.Possible:
            break;
        case UIGestureRecognizerState.Cancelled:
            break;
        case UIGestureRecognizerState.Failed:
            break;
            
        }
    }
    
    // called when the view is let go
    func afterSwipeAction() {
        if xFromCenter > ACTION_MARGIN {
            self.rightAction()
        } else if (xFromCenter < -ACTION_MARGIN) {
            self .leftAction()
        } else { // resets the view
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.view.center = self.originalPoint
                self.view.transform = CGAffineTransformMakeRotation(0)
            })
        }
    }
    
    // called when a swipe exceeds the ACTION_MARGIN to the right
    func rightAction() {
        var finishPoint = CGPointMake(600, 2 * yFromCenter + self.originalPoint.y)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.center = finishPoint
            }, completion: { finished in
                self.view.removeFromSuperview()
        })
        delegate?.viewSwipedRight(self.view)
    }
    
    // called when a swipe exceeds the ACTION_MARGIN to the left
    func leftAction() {
        var finishPoint = CGPointMake(-600, 2 * yFromCenter + self.originalPoint.y)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.center = finishPoint
            }, completion: { finished in
                self.view.removeFromSuperview()
        })
        
        delegate?.viewSwipedRight(self.view)
    }
    
}
