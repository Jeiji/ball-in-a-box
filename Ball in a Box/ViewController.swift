//
//  ViewController.swift
//  Ball in a Box
//
//  Created by James Bruno on 4/19/18.
//  Copyright © 2018 Yudoni Vineaux. All rights reserved.
//

import UIKit
import CoreMotion


extension FloatingPoint {
    func toDecimal( decimalPlaces dp: Int ) -> Self {
        var decimalFactor : Self = 1
        for _ in 1...dp{
            decimalFactor *= 10
        }
        return ( Darwin.round( self * decimalFactor ) ) / decimalFactor
    }
    var radiansToDegrees : Self {
        return self * ( 180 / .pi )
    }

}

protocol ballDelegate {
    var speedLimit: Double{ get set }
}

class ViewController: UIViewController, ballDelegate {
    
    //MARK: Speed Limit
    var speedLimit: Double = 1000000
    
    
    /////////////////////////////////
    //                             //
    // MARK: Outlets               //
    //                             //
    /////////////////////////////////
    
    @IBOutlet weak var ball: UIView!
    
    
    /////////////////////////////////
    //                             //
    // MARK: Custom Classes/Types  //
    //                             //
    /////////////////////////////////
    
    class Ball {
        var delegate: ViewController?
        
        init(delegate d: ViewController) {
            self.delegate = d
        }
        // Speed stuff...
        var speedX: Double = 0 {
            didSet {
                if abs(speedX) > delegate!.speedLimit {
                    if speedX < 0 { speedX = -15 } else { speedX = delegate!.speedLimit }
                }
            }
        }
        var speedY: Double = 0 {
            didSet {
                if abs(speedY) > delegate!.speedLimit {
                    if speedY < 0 { speedY = -15 } else { speedY = delegate!.speedLimit }
                }
            }
        }
    }
    
    enum GravityFactor : Double {
        case g1 = 0.01
        case g2 = 0.05
        case g3 = 0.1
    }
    
    enum BounceFactor : Double {
        case b1 = -0.2
        case b2 = -0.5
        case b3 = -0.9
    }
    
    enum SlideSensitivity : Double {
        case s1 = 1.5
        case s2 = 3
        case s3 = 4.5
    }
    
    
    /////////////////////////////////
    //                             //
    // MARK: Other Setup/Consts    //
    //                             //
    /////////////////////////////////
    
    let MM = CMMotionManager()
    let universalDecimalPlace = 3
    let universalGravityFactor = GravityFactor.g1.rawValue
    let universalBounceFactor = BounceFactor.b1.rawValue
    let universalSlideSensitivity = SlideSensitivity.s1.rawValue
    let speedApplicationRatio = 1.0

    
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /////////////////////////////////
        //                             //
        // MARK: The Ball              //
        //                             //
        /////////////////////////////////
        
        let theBall = Ball( delegate: self )
        
        
        /////////////////////////////////
        //                             //
        // MARK: Motion Managers/Loops //
        //                             //
        /////////////////////////////////
        
        precondition( MM.isMagnetometerAvailable && MM.isAccelerometerAvailable, "Not all motion captures available on this device." )
        
        
        // MARK: The Loop
        let deviceMotionHandler: CMDeviceMotionHandler = { motionData , error in
            
            if let md = motionData {
                
                
                //Data about the view frame edges (Left edge, top, right, bottom)
                let vle: CGFloat = 0
                let vte: CGFloat = 0
                let vre: CGFloat = self.view.frame.width
                let vbe: CGFloat = self.view.frame.height
                //Data about the ball UIView frame dimensions
                let bw = self.ball.frame.width
                let bh = self.ball.frame.height
                let bc = self.ball.center
                //Ball Edges (Left, Top, Right, Bottom)
                let ble = CGPoint(x:(bc.x-(bw/2)),y:(bc.y))
                let bte = CGPoint(x:(bc.x),y:(bc.y-(bh/2)))
                let bre = CGPoint(x:(bc.x+(bw/2)),y:(bc.y))
                let bbe = CGPoint(x:(bc.x),y:(bc.y+(bh/2)))
                
                
                // MARK: Colision Checks
                
                //Left/Right Collision
                if ( ble.x <= vle || bre.x >= vre || ( ble.x + CGFloat(theBall.speedX) ) <= vle || ( bre.x + CGFloat(theBall.speedX) ) >= vre   ){
                    theBall.speedX = ( theBall.speedX * self.universalBounceFactor  )
                }
                if ( ble.x < vle ){self.ball.frame.origin.x = vle}
                if ( bre.x > vre ){self.ball.frame.origin.x = vre-bw}
                
                //Up/Down Collision
                if ( bte.y <= vte || bbe.y >= vbe || ( bte.y + CGFloat(theBall.speedY) ) <= vte || ( bbe.y + CGFloat(theBall.speedY) ) >= vbe   ){
                    theBall.speedY = ( theBall.speedY * self.universalBounceFactor  )
                }
                if ( bte.y < vte ){self.ball.frame.origin.y = vte}
                if ( bbe.y > vbe ){self.ball.frame.origin.y = vbe-bh}
                
                
                
                //Rotation Data
                let mdrxDeg = ((md.attitude.roll).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mdryDeg = ((md.attitude.pitch).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mdrzDeg = ((md.attitude.yaw).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                
                //Acceleration Data
                let mdaxDeg = (md.userAcceleration.x).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mdayDeg = (md.userAcceleration.y).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mdazDeg = (md.userAcceleration.z).toDecimal(decimalPlaces: self.universalDecimalPlace)
                
                //Calculate ball speed
                theBall.speedX += (( mdrxDeg * self.universalGravityFactor ).toDecimal(decimalPlaces: self.universalDecimalPlace)+(mdaxDeg * self.universalSlideSensitivity))
                theBall.speedY += (( mdryDeg * self.universalGravityFactor ).toDecimal(decimalPlaces: self.universalDecimalPlace)-(mdayDeg * self.universalSlideSensitivity))
                
                //Apply ball speed to ball outlet
                self.ball.frame.origin.y += CGFloat(theBall.speedY * self.speedApplicationRatio)
                self.ball.frame.origin.x += CGFloat(theBall.speedX * self.speedApplicationRatio)
                
                
                print("""
                    
                    X Rote: \(mdrxDeg) | Y Rote: \(mdryDeg) | Z Rote: \(mdrzDeg)
                    X Acc: \(mdaxDeg) | Y Acc: \(mdayDeg) | Z Acc: \(mdazDeg)
                    Ball Speed (x,y) : ( \(theBall.speedX) , \(theBall.speedY) )
                    
                    """)
                
            }
            else {
                print("Couldn't get Motion Data")
            }
            
        }
        
        
        MM.deviceMotionUpdateInterval = 1/1000
        MM.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: deviceMotionHandler)
        
        
        
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

