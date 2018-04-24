//
//  ViewController.swift
//  Ball in a Box
//
//  Created by James Bruno on 4/19/18.
//  Copyright © 2018 Yudoni Vineaux. All rights reserved.
//

import UIKit
import CoreMotion

/////////////////////////////////
//                             //
// MARK: Protocols/Extensions  //
//                             //
/////////////////////////////////

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
    
//    @IBOutlet weak var ball: UIView!
    
    
    /////////////////////////////////
    //                             //
    // MARK: Custom Classes/Types  //
    //                             //
    /////////////////////////////////
    
    class Ball {
        
        init( delegate d : ViewController , view v : UIView) {
            self.delegate = d
            self.view = v
        }
        
        var delegate: ViewController!
        var view: UIView!
        var center: CGPoint? {
            get {
                return view?.center
            }
        }
        var radius: Double? {
            get {
                return Double(( view?.frame.height )! / 2 )
            }
        }
        
        // Speed stuff...
        var speed: ( x: Double , y: Double ) = ( 0 , 0 ) {
            didSet {
                if abs(speed.x) > delegate!.speedLimit {
                    if speed.x < 0 { speed.x = -delegate!.speedLimit } else { speed.x = delegate!.speedLimit }
                }
                if abs(speed.y) > delegate!.speedLimit {
                    if speed.y < 0 { speed.y = -delegate!.speedLimit } else { speed.y = delegate!.speedLimit }
                }
            }
        }
        
    }
    
    class BallConflux {
        init(ball: Ball , view: UIView) {
            self.ball = ball
            self.view = view
        }
        var ball : Ball
        var view : UIView
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
        case s1 = 1
        case s2 = 1.25
        case s3 = 1.5
    }
    
    
    /////////////////////////////////
    //                             //
    // MARK: Helper Functions      //
    //                             //
    /////////////////////////////////
    
    func makeAndPresentBallConfluence( radius r : CGFloat , delegate del : ViewController ) -> BallConflux {
        
        let rect = CGRect(x: ((del.view.center.x)-r/2), y: 200, width: r, height: r)
        let view = UIView(frame: rect)
        view.layer.cornerRadius = r/2
        view.backgroundColor = .black
        
        let ball = Ball(delegate: del, view: view)
        let newBallConflux = BallConflux(ball: ball, view: view)
        
        del.view.addSubview(view)
        balls.append(newBallConflux)
        return newBallConflux
    }
    
    
    /////////////////////////////////
    //                             //
    // MARK: Other Setup/Consts    //
    //                             //
    /////////////////////////////////
    
    // Setup
    let MM = CMMotionManager()
    var balls = [BallConflux]()

    
    
    
    // Consts
    let universalDecimalPlace = 3
    let universalGravityFactor = GravityFactor.g1.rawValue
    let universalBounceFactor = BounceFactor.b2.rawValue
    let universalSlideSensitivity = SlideSensitivity.s2.rawValue
    let speedApplicationRatio = 1.0
    


    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /////////////////////////////////
        //                             //
        // MARK: The first Ball        //
        //                             //
        /////////////////////////////////
        
        let theBall = makeAndPresentBallConfluence(radius: 200, delegate: self)
        
        
        
        /////////////////////////////////
        //                             //
        // MARK: The Loop              //
        //                             //
        /////////////////////////////////
        
        precondition( MM.isMagnetometerAvailable && MM.isAccelerometerAvailable, "Not all motion captures available on this device." )
        
        let deviceMotionHandler: CMDeviceMotionHandler = { motionData , error in

            
            
            if let md = motionData {
                
                //Rotation Data
                let mdrxDeg = ((md.attitude.roll).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mdryDeg = ((md.attitude.pitch).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mdrzDeg = ((md.attitude.yaw).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                
                //Acceleration Data
                let mdax = (md.userAcceleration.x).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mday = (md.userAcceleration.y).toDecimal(decimalPlaces: self.universalDecimalPlace)
                let mdaz = (md.userAcceleration.z).toDecimal(decimalPlaces: self.universalDecimalPlace)
                

                //Data about the view frame edges (Left edge, top, right, bottom)
                let vle: CGFloat = 0
                let vte: CGFloat = 0
                let vre: CGFloat = self.view.frame.width
                let vbe: CGFloat = self.view.frame.height
//                Data about the ball UIView frame dimensions

                let bw = theBall.view.frame.width
                let bh = theBall.view.frame.height
                let bc = theBall.view.center
//                Ball Edges (Left, Top, Right, Bottom)
                let ble = CGPoint(x:(bc.x-(bw/2)),y:(bc.y))
                let bte = CGPoint(x:(bc.x),y:(bc.y-(bh/2)))
                let bre = CGPoint(x:(bc.x+(bw/2)),y:(bc.y))
                let bbe = CGPoint(x:(bc.x),y:(bc.y+(bh/2)))


//                 MARK: Screen Edge Colision Checks

                //Left/Right Collision
                if ( ble.x <= vle || bre.x >= vre || ( ble.x + CGFloat(theBall.ball.speed.x) ) <= vle || ( bre.x + CGFloat(theBall.ball.speed.x) ) >= vre   ){
                    theBall.ball.speed.x = ( (theBall.ball.speed.x + mday) * self.universalBounceFactor  )
                }
                if ( ble.x < vle ){theBall.view.frame.origin.x = vle}
                if ( bre.x > vre ){theBall.view.frame.origin.x = vre-bw}

                //Up/Down Collision
                if ( bte.y <= vte || bbe.y >= vbe || ( bte.y + CGFloat(theBall.ball.speed.y) ) <= vte || ( bbe.y + CGFloat(theBall.ball.speed.y) ) >= vbe   ){
                    theBall.ball.speed.y = ( (theBall.ball.speed.y + mdax) * self.universalBounceFactor  )
                }
                if ( bte.y < vte ){theBall.view.frame.origin.y = vte}
                if ( bbe.y > vbe ){theBall.view.frame.origin.y = vbe-bh}




                
              
                
//                Calculate ball speed
                theBall.ball.speed.x += (( mdrxDeg * self.universalGravityFactor ).toDecimal(decimalPlaces: self.universalDecimalPlace)+(mdax * self.universalSlideSensitivity))
                theBall.ball.speed.y += (( mdryDeg * self.universalGravityFactor ).toDecimal(decimalPlaces: self.universalDecimalPlace)-(mday * self.universalSlideSensitivity))
                
//                Apply ball speed to ball view
                theBall.view.frame.origin.y += CGFloat(theBall.ball.speed.y * self.speedApplicationRatio)
                theBall.view.frame.origin.x += CGFloat(theBall.ball.speed.x * self.speedApplicationRatio)
                
                
                print("""
                    
                    X Rote: \(mdrxDeg) | Y Rote: \(mdryDeg) | Z Rote: \(mdrzDeg)
                    X Acc: \(mdax) | Y Acc: \(mday) | Z Acc: \(mdaz)
                    Ball Speed (x,y) : ( \( theBall.ball.speed.x.toDecimal(decimalPlaces: 3) ) , \( theBall.ball.speed.y.toDecimal(decimalPlaces: 3) ) ) )
                    
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

