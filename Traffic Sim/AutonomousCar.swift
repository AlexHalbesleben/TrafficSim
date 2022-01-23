//
//  Car.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/1/21.
//

import Foundation
import GameplayKit

class AutonomousCar: Car {
    override var followingDistance: CGFloat {
        48 + velocity * (carAhead != nil && carAhead!.isHuman ? 16 : 8)
    }
    override func update(deltaTime seconds: TimeInterval) {
        if (!exists) { // If the car has been removed, don't do anything
            return
        }
         
        checkTurn()
        findCarAhead()
        
        // If there is a car ahead
        if (carAhead != nil) {
            acceleration = carAhead!.acceleration + distanceAdjustment! // Acceleration is simply the car ahead's acceleration adjusted so that you reach the following distance
            velocityReason = "Adjusting to car ahead (\(carAhead!.id))"
        } else { // If there's no car ahead
            // If there's a turn ahead, slow down a little. Otherwise, go as fast as possible
            let baseSpeed: CGFloat = turnAhead && distanceToNext < CP.MIN_TURN_SLOWDOWN_DISTANCE ? CP.TURN_SLOWDOWN : CP.MAX_SPEED
            acceleration = (baseSpeed - velocity)
            velocityReason = "Adjusting to base speed"
        }
        
        if (!canGo && distanceToNext < 5 - velocity * velocity / (0.5 * CP.MIN_ACC)) {
            acceleration = CP.MIN_ACC
            velocityReason = "Decelerating at stop"
            
            if (velocity.magnitude < 0.1) { // If the velocity's very small, chop it down to 0. This avoids floating-point arithmetic errors
                velocity = 0
                acceleration = 0
                velocityReason += " and fully stopped"
            }
        }
        
        // Clamp acceleration
        if (acceleration > CP.MAX_ACC) {
            acceleration = CP.MAX_ACC
            velocityReason += " and clamped at upper bound"
        }
        if (acceleration < CP.MIN_ACC) {
            acceleration = CP.MIN_ACC
            velocityReason += " and clamped at lower bound"
        }
        
        velocity = velocity + acceleration // Makes the car go
            
        // Clamp velocity
        if (velocity > CP.MAX_SPEED) {
            velocity = CP.MAX_SPEED
            
            if (acceleration > 0) {
                acceleration = 0
                velocityReason += " and set to 0 because the velocity was over the max"
            }
        }
        if (velocity < CP.MIN_SPEED) {
            velocity = CP.MIN_SPEED
            
            if (acceleration < 0) {
                acceleration = 0
                velocityReason += " and set to 0 because the velocity was under the min"
            }
        }
        
        updatePosition()
        scene.stats["av distance"]! += velocity
    }
    
    func changeColor() {
        node.texture = SKTexture(imageNamed: "CarGreen")
    }
}
