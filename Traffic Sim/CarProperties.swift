//
//  CarProperties.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/6/21.
//

import Foundation

class CP {
    static let MIN_SPEED: CGFloat = -0.5 // Cars cannot have negative speeds (i.e. go backwards)
    static let MAX_SPEED: CGFloat = 2 // Speed limit
    
    static let MIN_ACC: CGFloat = -0.05 // Cannot brake too hard
    static let MAX_ACC: CGFloat = 0.05 // Cannot accelerate too quickly
    
    static let TURN_SLOWDOWN: CGFloat = 1.5 // How much cars should slow down at turns
    
    static let MIN_TURN_SLOWDOWN_DISTANCE: CGFloat = 50 // The minimum distance from a turn at which cars begin slowing down
    static let MIN_STOP_DISTANCE: CGFloat = 150 // The minimum distance at which a car can begin stopping
}
