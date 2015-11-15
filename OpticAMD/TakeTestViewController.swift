//
//  TakeTestViewController.swift
//  OpticAMD
//
//  Created by Brian on 11/5/15.
//  Copyright © 2015 Med AppJam 2015 - Team 9. All rights reserved.
//

import UIKit

@IBDesignable
class TakeTestViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var mainImageView: UIImageView! // Contains drawing except for the line currently being drawn
    @IBOutlet weak var tempImageView: UIImageView! // Contains line currently being drawn

    var lastPointDrawn = CGPoint.zero    // last point drawn on canvas
    var brushLineWidth: CGFloat = 5      // width of line to draw
    var continuousStroke = false              // true if stroke is continuous
    var red:        CGFloat = 0
    var green:      CGFloat = 0
    var blue:       CGFloat = 255
    var opacity:    CGFloat = 1
    var savedTestResults = SavedTestResults()
    var saveAlertController: UIAlertController?
    var saveAndContinueAlertController: UIAlertController?
    var finishAlertController: UIAlertController?
    
    var leftImage: UIImage?
    var rightImage: UIImage?
    

    var gridLineWidth: CGFloat = 5
    var squareSize: CGFloat = 25

    
    // MARK: Overriden Methods
    override func viewDidLoad() {

        // Create and configure alert controller to be used later (when save is tapped)
        saveAlertController = UIAlertController(title: "Your test was saved", message: nil, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default) { (ACTION) -> Void in
        }
        saveAlertController?.addAction(alertAction)
        
        // 'Save & Continue' alert controller
        saveAndContinueAlertController = UIAlertController(title: "Left eye test result saved", message: nil, preferredStyle: .Alert)
        let saveAndContinueAlertAction = UIAlertAction(title: "OK", style: .Default) { (ACTION) -> Void in
            self.performSegueWithIdentifier("LeftToRightSegue", sender: self)
        }
        saveAndContinueAlertController?.addAction(saveAndContinueAlertAction)

        // 'Finish' alert controller
        finishAlertController = UIAlertController(title: "Right eye test result saved", message: nil, preferredStyle: .Alert)
        let finishAlertControllerAction = UIAlertAction(title: "OK", style: .Default) { (ACTION) -> Void in
            self.performSegueWithIdentifier("RightToMainSegue", sender: self)
        }
        finishAlertController?.addAction(finishAlertControllerAction)
        
        drawNewGrid()
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Called when one or more fingers touch down in a view or window

        // Reset continuousStroke boolean
        continuousStroke = false

        // Save touch location in lastPointDrawn
        if let touch = touches.first as UITouch! {
            print(touch.locationInView(self.view))
            lastPointDrawn = touch.locationInView(self.view)
            lastPointDrawn.x -= mainImageView.superview!.frame.origin.x
            lastPointDrawn.y -= mainImageView.superview!.frame.origin.y
        }

    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Called when one or more fingers associated with an event move within a view or window

        // 6
        continuousStroke = true
        if let touch = touches.first as UITouch! {
            var currentPoint = touch.locationInView(view)
            currentPoint.x -= mainImageView.superview!.frame.origin.x
            currentPoint.y -= mainImageView.superview!.frame.origin.y
            drawLineFrom(lastPointDrawn, toPoint: currentPoint)

            // 7
            lastPointDrawn = currentPoint
        }

    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Called when one or more fingers are raised from a view or window

        if !continuousStroke {
            // draw a single point
            drawLineFrom(lastPointDrawn, toPoint: lastPointDrawn)
        }

        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(mainImageView.superview!.frame.size)

        mainImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: superviewWidth(), height: superviewHeight()), blendMode: CGBlendMode.Normal, alpha: 1.0)
        tempImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: tempImageView.superview!.frame.size.width, height: tempImageView.superview!.frame.size.height), blendMode: CGBlendMode.Normal, alpha: 1.0)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        tempImageView.image = nil
    }



    // MARK: Actions
    @IBAction func reset(sender: UIBarButtonItem) {
        setOrResetView()
    }

    @IBAction func saveLeft(sender: UIBarButtonItem) {
        leftImage = createImageFromGrid()
        self.presentViewController(saveAlertController!, animated: true, completion: nil)
    }
    @IBAction func saveLeftAndContinue(sender: UIBarButtonItem) {
        leftImage = createImageFromGrid()
        self.presentViewController(saveAndContinueAlertController!, animated: true, completion: nil)
    }
    @IBAction func next(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("LeftToRightSegue", sender: sender)
    }
    
    @IBAction func saveRight(sender: UIBarButtonItem) {
        rightImage = createImageFromGrid()
        if leftImage == nil {
            leftImage = UIImage(named: "cat")
        }
        savedTestResults.add(TestResult(date: NSDate(), leftImage: leftImage, rightImage: rightImage)!)
        savedTestResults.save()
        self.presentViewController(saveAlertController!, animated: true, completion: nil)
    }
    @IBAction func saveRightAndFinish(sender: UIBarButtonItem) {
        rightImage = createImageFromGrid()
        if leftImage == nil {
            leftImage = UIImage(named: "cat")
        }
        savedTestResults.add(TestResult(date: NSDate(), leftImage: leftImage, rightImage: rightImage)!)
        savedTestResults.save()
        self.presentViewController(finishAlertController!, animated: true, completion: nil)
    }
    @IBAction func finish(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("RightToMainSegue", sender: sender)
    }
    
    func createImageFromGrid() -> UIImage {
        // Create rectangle from middle of current image
        let cropRect = CGRectMake(gridLeftEdge() - (gridLineWidth / 2), gridTopEdge() - (gridLineWidth / 2) , gridSize() + (gridLineWidth / 2), gridSize() + (gridLineWidth / 2)) ;
        let imageRef = CGImageCreateWithImageInRect(mainImageView.image?.CGImage, cropRect)
        let croppedImage = UIImage(CGImage: imageRef!)
        return croppedImage
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LeftToRightSegue" {
            if let destinationViewController = segue.destinationViewController as? TakeTestViewController {
                destinationViewController.leftImage = leftImage
            }
        }
    }

    func drawLineFrom(fromPoint:CGPoint, toPoint:CGPoint) {
        // Called by touchesMoved to draw a line between two points

        // 1
        UIGraphicsBeginImageContext(tempImageView.superview!.frame.size)
        let context = UIGraphicsGetCurrentContext()
        tempImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: tempImageView.superview!.frame.size.width, height: tempImageView.superview!.frame.size.height))

        // 2
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)


        // 3
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, brushLineWidth)
        CGContextSetRGBStrokeColor(context, red, 0.5, blue, 1.0)
        CGContextSetBlendMode(context, CGBlendMode.Normal)

        // 4
        CGContextStrokePath(context)

        // Fill outside of grid with white (so you can't draw outside of grid)
        CGContextSetRGBFillColor(context, 1, 1, 1, 1.0)
        CGContextFillRect(context, CGRect(x: 0, y: 0, width: superviewWidth(), height: gridTopEdge()))
        CGContextFillRect(context, CGRect(x: 0, y: gridTopEdge() + gridSize() , width: superviewWidth(), height: gridTopEdge() ))

        // 5
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = opacity
        UIGraphicsEndImageContext()
    }

    func setOrResetView() {
        mainImageView.image = nil
        tempImageView.image = nil
        drawNewGrid()
    }

    func drawNewGrid() {
        var xPos : CGFloat
        var yPos : CGFloat
        var context: CGContext?

        // BORDER
//        drawGridBorderForDebugging()


        // Set up for drawing
        UIGraphicsBeginImageContext(mainImageView.superview!.frame.size)
        context = UIGraphicsGetCurrentContext()
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, gridLineWidth)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        mainImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: superviewWidth(), height: superviewHeight()))

        // WHITE (Background)
        CGContextSetRGBFillColor(context, 1, 1, 1, 1.0)
        CGContextFillRect(context, CGRect(x: 0, y: 0, width: mainImageView.superview!.frame.size.width, height: mainImageView.superview!.frame.size.height))
        
        // BLUE (Horizontal)
        xPos = gridLeftDrawingEdge()
        yPos = gridTopDrawingEdge()
        for _ in 1...gridNumLines() {
            CGContextMoveToPoint(context, xPos, yPos)
            CGContextAddLineToPoint(context, xPos, gridTopEdge() + gridSize() - (gridLineWidth / 2) )
            xPos += squareSize + gridLineWidth
        }
//        CGContextSetRGBStrokeColor(context, 0, 0, 1, 1.0)
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0)
        CGContextStrokePath(context)

        // RED (Vertical)
        xPos = gridLeftDrawingEdge()
        yPos = gridTopDrawingEdge()
        for _ in 1...gridNumLines() {
            CGContextMoveToPoint(context, xPos, yPos)
            CGContextAddLineToPoint(context, gridLeftEdge() + gridSize() - (gridLineWidth / 2), yPos)
            yPos += squareSize + gridLineWidth
        }
//        CGContextSetRGBStrokeColor(context, 1, 0, 0, 1.0)
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0)
        CGContextStrokePath(context)

        // Finish drawing
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        mainImageView.alpha = 1
        UIGraphicsEndImageContext()
    }

    func superviewWidth() -> CGFloat {
        return mainImageView.superview!.frame.size.width
    }
    func superviewHeight() -> CGFloat {
        return mainImageView.superview!.frame.size.height
    }
    func gridNumSquares() -> Int {
        return Int(floor((min(superviewWidth(), superviewHeight()) - gridLineWidth) / (gridLineWidth + squareSize)))
    }
    func gridNumLines() -> Int {
        return gridNumSquares() + 1
    }
    func gridSize() -> CGFloat {
        return CGFloat(gridNumSquares()) * (squareSize + gridLineWidth) + gridLineWidth
    }
    func gridLeftEdge() -> CGFloat {
        return floor((superviewWidth() - gridSize()) / 2)
    }
    func gridTopEdge() -> CGFloat {
        return floor((superviewHeight() - gridSize()) / 2)
    }
    func gridLeftDrawingEdge() -> CGFloat {
        return gridLeftEdge() + (gridLineWidth / 2)
    }
    func gridTopDrawingEdge() -> CGFloat {
        return gridTopEdge() + (gridLineWidth / 2)
    }


    func printDebugInfo1() {
        print("tempImageView.frame.size: \(tempImageView.frame.size)")
        print("gridLineWidth: \(gridLineWidth)")
        print("squareSize:    \(squareSize)")
        print("gridNumSquares():  \(gridNumSquares())")
        print("gridNumLines():    \(gridNumLines())")
        print("gridSize():    \(gridSize())")
        print("leftTop:       \(gridLeftEdge()), \(gridTopEdge()) ")
    }
    func drawGridBorderForDebugging() {
        var context: CGContext?
        UIGraphicsBeginImageContext(mainImageView.superview!.frame.size)
        context = UIGraphicsGetCurrentContext()
        mainImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: superviewWidth(), height: superviewHeight()))
        CGContextMoveToPoint(context, 0, 0)
        CGContextAddLineToPoint(context, superviewWidth(), 0)
        CGContextAddLineToPoint(context, superviewWidth(), superviewHeight())
        CGContextAddLineToPoint(context, 0, superviewHeight())
        CGContextAddLineToPoint(context, 0, 0)
        CGContextMoveToPoint(context, mainImageView.superview!.frame.origin.x, mainImageView.superview!.frame.origin.y)
        CGContextAddLineToPoint(context, mainImageView.superview!.frame.origin.x + 100, mainImageView.superview!.frame.origin.y + 100)
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, gridLineWidth)
        CGContextSetRGBStrokeColor(context, 0, 1, 1, 1.0)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        CGContextStrokePath(context)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        mainImageView.alpha = 1
        UIGraphicsEndImageContext()
    }

}
