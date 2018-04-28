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
        var collidingWith : BallConflux?
    }
    
    enum GravityFactor : Double {
        case g1 = 0.01
        case g2 = 0.05
        case g3 = 0.1
    }
    
    enum BounceFactor : Double {
        case bhalf = -0.1
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
    
    func makeAndPresentBallConfluence( radius r : CGFloat , delegate del : ViewController , color: UIColor ) -> BallConflux {
        
        let rect = CGRect(x: ((del.view.center.x)-r/2), y: 200, width: r, height: r)
        let view = UIView(frame: rect)
        view.layer.cornerRadius = r/2
        view.backgroundColor = color
        
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
        // MARK: The first Balls       //
        //                             //
        /////////////////////////////////
        
        let _ = makeAndPresentBallConfluence(radius: 50, delegate: self , color: .black)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            _ = self.makeAndPresentBallConfluence(radius: 50, delegate: self , color: .red)
        })
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
//            _ = self.makeAndPresentBallConfluence(radius: 50, delegate: self , color: .blue)
//        })
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
//            _ = self.makeAndPresentBallConfluence(radius: 50, delegate: self)
//        })
        
        
        
        
        /////////////////////////////////
        //                             //
        // MARK: The Loop              //
        //                             //
        /////////////////////////////////
        
        precondition( MM.isMagnetometerAvailable && MM.isAccelerometerAvailable, "Not all motion captures available on this device." )
        
        let deviceMotionHandler: CMDeviceMotionHandler = { motionData , error in
            
            for ball in self.balls {
                
                if let md = motionData {
                    
                    
                    //MARK: Screen Edge Colision Checks
                    
                    //Rotation Data
                    let mdrxDeg = ((md.attitude.roll).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                    let mdryDeg = ((md.attitude.pitch).radiansToDegrees).toDecimal(decimalPlaces: self.universalDecimalPlace)
                    
                    //Acceleration Data
                    let mdax = (md.userAcceleration.x).toDecimal(decimalPlaces: self.universalDecimalPlace)
                    let mday = (md.userAcceleration.y).toDecimal(decimalPlaces: self.universalDecimalPlace)
                    
                    
                    
                    //Data about the view frame edges (Left edge, top, right, bottom)
                    let vle: CGFloat = 0
                    let vte: CGFloat = 0
                    let vre: CGFloat = self.view.frame.width
                    let vbe: CGFloat = self.view.frame.height
                    
                    // Data about the ball UIView frame dimensions
                    let bw = ball.view.frame.width
                    let bh = ball.view.frame.height
                    let bc = ball.view.center
                    
                    //Ball Edges (Left, Top, Right, Bottom)
                    let ble = CGPoint(x:(bc.x-(bw/2)),y:(bc.y))
                    let bte = CGPoint(x:(bc.x),y:(bc.y-(bh/2)))
                    let bre = CGPoint(x:(bc.x+(bw/2)),y:(bc.y))
                    let bbe = CGPoint(x:(bc.x),y:(bc.y+(bh/2)))
                    
                    
                    //Left/Right Collision
                    if ( ble.x <= vle || bre.x >= vre || ( ble.x + CGFloat(ball.ball.speed.x) ) <= vle || ( bre.x + CGFloat(ball.ball.speed.x) ) >= vre   ){
                        ball.ball.speed.x = ( (ball.ball.speed.x + mday) * self.universalBounceFactor  )
                    }
                    if ( ble.x < vle ){ball.view.frame.origin.x = vle}
                    if ( bre.x > vre ){ball.view.frame.origin.x = vre-bw}
                    
                    //Up/Down Collision
                    if ( bte.y <= vte || bbe.y >= vbe || ( bte.y + CGFloat(ball.ball.speed.y) ) <= vte || ( bbe.y + CGFloat(ball.ball.speed.y) ) >= vbe   ){
                        ball.ball.speed.y = ( (ball.ball.speed.y + mdax) * self.universalBounceFactor  )
                    }
                    if ( bte.y < vte ){ball.view.frame.origin.y = vte}
                    if ( bbe.y > vbe ){ball.view.frame.origin.y = vbe-bh}
                    
                    //MARK: Inter-Ball Collision
                    
                    for otherBall in self.balls {
                        if otherBall === ball {
                            continue
                        }else if ball.collidingWith === otherBall {
                            continue
                        }else{
                            
                            otherBall.collidingWith = ball
                            ball.collidingWith = otherBall
                            
                            let distanceX = Double((ball.ball.center?.x)! - (otherBall.ball.center?.x)!)
                            let lastDistanceX = (Double((ball.ball.center?.x)!) - ball.ball.speed.x) - (Double((otherBall.ball.center?.x)!) - otherBall.ball.speed.x)
                            let distanceY = Double((ball.ball.center?.y)! - (otherBall.ball.center?.y)!)
                            let lastDistanceY = (Double((ball.ball.center?.y)!) - ball.ball.speed.y) - (Double((otherBall.ball.center?.y)!) - otherBall.ball.speed.y)
                            let totalDistance = sqrt((distanceX * distanceX) + (distanceY * distanceY))
                            let lastTotalDistance = sqrt((lastDistanceX * lastDistanceX) + (lastDistanceY * lastDistanceY))
                            

                            
                            if totalDistance < ball.ball.radius! + otherBall.ball.radius! && ( lastTotalDistance > totalDistance ) && ( lastTotalDistance > ball.ball.radius! + otherBall.ball.radius! ){
                                



                                // Set up the interaction slope, the collision angle is required first...

                                //Setting collision angle
                                if let ballCenterX = ball.ball.center?.x , let ballCenterY = ball.ball.center?.y , let otherBallCenterX = otherBall.ball.center?.x , let otherBallCenterY = otherBall.ball.center?.y {

                                    let ballspeedX = ball.ball.speed.x
                                    let ballspeedY = ball.ball.speed.y
                                    let otherBallspeedX = otherBall.ball.speed.x
                                    let otherBallspeedY = otherBall.ball.speed.y
                                    let interactionSlope: CGFloat?
                                    let refractionSlope: CGFloat?

                                    interactionSlope = ( ballCenterY - otherBallCenterY ) / ( ballCenterX - otherBallCenterX )
                                    refractionSlope = 1/interactionSlope!
                                    
                                    var interactionAngle = atan(interactionSlope!) * ( 180 / .pi )
                                    
                                    if interactionAngle <= -90 { interactionAngle += 180 }

                                    
                                    print("\n\nInteraction Angle: \(String(describing: interactionAngle.toDecimal(decimalPlaces: self.universalDecimalPlace)))")


                                    let ballAbsoluteSpeed = CGFloat( abs(ballspeedX) + abs(ballspeedY) )
                                    let otherBallAbsoluteSpeed = CGFloat( abs(otherBallspeedX) + abs(otherBallspeedY) )
                                    
                                    print("Ball Velocity: ( \(ballspeedX.toDecimal(decimalPlaces: self.universalDecimalPlace)) , \(ballspeedY.toDecimal(decimalPlaces: self.universalDecimalPlace)) )\nOther Ball Velocity: ( \(otherBallspeedX.toDecimal(decimalPlaces: self.universalDecimalPlace)) , \(otherBallspeedY.toDecimal(decimalPlaces: self.universalDecimalPlace)) )")
                                    
                                    let ballNewSpeed: ( x: Double , y: Double )
                                    let otherBallNewSpeed : ( x: Double , y: Double )
                                    
                                    //Finding new post-collision slopes
                                    let ballSlope = CGFloat(ballspeedY / ballspeedX)
                                    var ballSlopeInDegrees = atan(ballSlope) * ( 180 / .pi )
                                    if ballSlopeInDegrees <= -90 { ballSlopeInDegrees += 180 }
                                    let otherBallSlope = CGFloat(otherBallspeedY / otherBallspeedX)
                                    var otherBallSlopeInDegrees = atan(otherBallSlope) * ( 180 / .pi )
                                    if otherBallSlopeInDegrees  <= -90 { otherBallSlopeInDegrees += 180 }
                                    
                                    print("BALL Angle: \(ballSlopeInDegrees.toDecimal(decimalPlaces: self.universalDecimalPlace))\nOTHER BALL Angle: \(otherBallSlopeInDegrees.toDecimal(decimalPlaces: self.universalDecimalPlace))")
                                    
                                    
                                    //To lessen overlap...
                                    
//                                    if totalDistance < ball.ball.radius! + otherBall.ball.radius! {
//                                        if ( Double((ball.ball.center?.x)!) < Double((otherBall.ball.center?.x)!) ){
//                                            ball.view.center.x -= CGFloat(( ball.ball.radius! + otherBall.ball.radius! ) - distanceX)
//                                        }else{
//                                            ball.view.center.x -= CGFloat(( ball.ball.radius! + otherBall.ball.radius! ) - distanceX)
//                                        }
//                                    }

                                    
                                    
                                    
                                    
                                    // Wikipedia'd Newtonian method
                                    
                                    let mitigation:Double = 0.5
                                    
                                    
                                    ballNewSpeed.x =  Double( ( ( ballAbsoluteSpeed * cos( ballSlopeInDegrees - interactionAngle ) * ( 1 - 1 ) + 2 * 1 * otherBallAbsoluteSpeed * cos( otherBallSlopeInDegrees - interactionAngle ) ) / 1 + 1 ) * cos( interactionAngle ) + ballAbsoluteSpeed * sin( ballSlopeInDegrees - interactionAngle ) * cos( interactionAngle + ( .pi / 2 ) ))
                                    
                                    ballNewSpeed.y =  -Double( ( ( ballAbsoluteSpeed * cos( ballSlopeInDegrees - interactionAngle ) * ( 1 - 1 ) + 2 * 1 * otherBallAbsoluteSpeed * cos( otherBallSlopeInDegrees - interactionAngle ) ) / 1 + 1 ) * sin( interactionAngle ) + ballAbsoluteSpeed * sin( ballSlopeInDegrees - interactionAngle ) * sin( interactionAngle + ( .pi / 2 ) ))
                                    
                                    
                                    otherBallNewSpeed.x =  Double( ( ( otherBallAbsoluteSpeed * cos( otherBallSlopeInDegrees - interactionAngle ) * ( 1 - 1 ) + 2 * 1 * ballAbsoluteSpeed * cos( ballSlopeInDegrees - interactionAngle ) ) / 1 + 1 ) * cos( interactionAngle ) + otherBallAbsoluteSpeed * sin( otherBallSlopeInDegrees - interactionAngle ) * cos( interactionAngle + ( .pi / 2 ) ))
                                    
                                    otherBallNewSpeed.y =  -Double( ( ( otherBallAbsoluteSpeed * cos( otherBallSlopeInDegrees - interactionAngle ) * ( 1 - 1 ) + 2 * 1 * ballAbsoluteSpeed * cos( ballSlopeInDegrees - interactionAngle ) ) / 1 + 1 ) * sin( interactionAngle ) + otherBallAbsoluteSpeed * sin( otherBallSlopeInDegrees - interactionAngle ) * sin( interactionAngle + ( .pi / 2 ) ))
                            
                                    


//
                                    ball.ball.speed.x = ( ballNewSpeed.x )
                                    ball.ball.speed.y =  ( ballNewSpeed.y )
                                    otherBall.ball.speed.x =  ( otherBallNewSpeed.x )
                                    otherBall.ball.speed.y = ( otherBallNewSpeed.y  )


                                }else{
                                    print("Ball centers returned nil for some reason.")
                                }



                            }
                        }
                    }
                    
                    
                    
                    
                    
                    
                    
                    //                Calculate ball speed
                    ball.ball.speed.x += (( mdrxDeg * self.universalGravityFactor ).toDecimal(decimalPlaces: self.universalDecimalPlace)+(mdax * self.universalSlideSensitivity))
                    ball.ball.speed.y += (( mdryDeg * self.universalGravityFactor ).toDecimal(decimalPlaces: self.universalDecimalPlace)-(mday * self.universalSlideSensitivity))
                    
                    //                Apply ball speed to ball view
                    ball.view.frame.origin.y += CGFloat(ball.ball.speed.y * self.speedApplicationRatio)
                    ball.view.frame.origin.x += CGFloat(ball.ball.speed.x * self.speedApplicationRatio)
                    
                    
                    //                    print("""
                    //
                    //                        X Rote: \(mdrxDeg) | Y Rote: \(mdryDeg) | Z Rote: \(mdrzDeg)
                    //                        X Acc: \(mdax) | Y Acc: \(mday) | Z Acc: \(mdaz)
                    //                        Ball Speed (x,y) : ( \( theBall.ball.speed.x.toDecimal(decimalPlaces: self.universalDecimalPlace) ) , \( theBall.ball.speed.y.toDecimal(decimalPlaces: self.universalDecimalPlace) ) ) )
                    //
                    //                        """)
                    
                }
                else {
                    print("Couldn't get Motion Data")
                }
            }
            for ball in self.balls {
                ball.collidingWith = nil
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

