//
//  HumanCar.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/21/21.
//

import Foundation
import GameplayKit

class HumanCar: Car {
    var queue: [CGFloat] = Array(repeating: 0.01, count: 20)
    
    var queueSize: Int {
        Int(15 * wildness)
    }
    
    // The actual acceleration seen by other cars
    override var acceleration: CGFloat {
        get {
            queue.first!
        }
        set (to) {
            queue[0] = to
        }
    }
    
    // The delayed acceleration seen by this car
    var _acceleration: CGFloat {
        get {
            queue.last!
        }
        set (to) {
            if (queue.count == queueSize) {
                queue[queueSize - 1] = to
            } else {
                queue.append(to)
            }
        }
    }
    
    override var followingDistance: CGFloat {
        64 + velocity * 48 * wildness
    }
    
    override var isHuman: Bool {
        true
    }
    
    let wildness: CGFloat = CGFloat.random(in: 0.75...1.25)
    
    var topSpeed: CGFloat {
        CP.MAX_SPEED * wildness / 1.125
    }
    
    
    override func update(deltaTime seconds: TimeInterval) {
        if (!exists) {
            return
        }
        queue.removeFirst()
        
        checkTurn()
        findCarAhead()
        
        let shouldStopAtTurn = !carInSameRoad && !canGo && distanceToNext < CP.MIN_STOP_DISTANCE
        
        if (carAhead != nil && !(!carInSameRoad && !canGo)) {
            if (distanceAdjustment! > 20) {
                _acceleration = 0.03
            } else if (distanceAdjustment! < -20) {
                _acceleration = -0.03
            } else {
                _acceleration = 0
            }
            velocityReason = "Adjusting to velocity of car ahead (\(carAhead!.id))"
        } else if (shouldStopAtTurn) {
            velocityReason = "Stopping at turn"
            
            let targetVelocity = (distanceToNext / CP.MIN_STOP_DISTANCE - 0.2) * topSpeed
            _acceleration = (targetVelocity - velocity) / 50
        } else {
            velocityReason += "Speeding up as fast as possible"
            var targetVelocity = topSpeed
            if (distanceToNext < CP.MIN_TURN_SLOWDOWN_DISTANCE && turnAhead) {
                velocityReason += " and slowing down for a turn"
                targetVelocity = CP.TURN_SLOWDOWN / 1.33
            }
            _acceleration = (targetVelocity - velocity) / 50
        }
        
        if (_acceleration > CP.MAX_ACC / 1.5) {
            _acceleration = CP.MAX_ACC / 1.5
            velocityReason += " and being clamped to upper bound"
        }
        if (_acceleration < CP.MIN_ACC / 1.5) {
            _acceleration = CP.MIN_ACC / 1.5
            velocityReason += " and being clamped to lower bound"
        }
        
        velocity = velocity + acceleration
            
        if (velocity > topSpeed) {
            velocity = topSpeed
            
            if (acceleration > 0) {
                acceleration = 0
                velocityReason += " and being set to 0 because the velocity is greater than the max"
            }
        }
        if (velocity < 0) {
            velocity = 0
            
            if (_acceleration < 0) {
                _acceleration = 0 // Since the negative acceleration is not lowering the velocity, the acceleration is effectively zero and should be registered as such
                velocityReason += " and being set to 0 because the velocity is less than the min"
            }
        }
        
        updatePosition()
        scene.stats["human distance"]! += velocity
    }
}
