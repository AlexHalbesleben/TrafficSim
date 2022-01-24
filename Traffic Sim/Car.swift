//
//  Car.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/21/21.
//

import Foundation
import GameplayKit
import SpriteKit

class Car: GKEntity {
    static var nextID: Int = 0
    var id: Int
    
    var node: SKSpriteNode
    var scene: GameScene
    
    var current: Drivable
    var next: Drivable
    
    var distanceToNext: CGFloat {
        current.distance - progress
    }
    var progress: CGFloat = 0
    var velocity: CGFloat = 0
    var acceleration: CGFloat = 0
    
    private var t: CGFloat = 0
    
    var position: CGPoint {
        current.location(progress: progress)
    }
    
    var onRoad: Bool {
        type(of: next) == Linkage.self
    }
    var turnAhead: Bool {
        onRoad ? !(next as! Linkage).thru : false
    }
    var canGo: Bool {
        onRoad ? (next as! Linkage).canTurn(isHuman) : true
    }
    var carAhead: Car? = nil
    var carDistance: CGFloat? = nil
    
    var followingDistance: CGFloat {
        0
    }
    var distanceAdjustment: CGFloat? {
        carDistance != nil ? carDistance! - followingDistance : nil
    }
    var velocityDiff: CGFloat? {
        carAhead != nil ? carAhead!.velocity - velocity : nil
    }
    
    var carInSameRoad: Bool = false
    
    var isHuman: Bool {
        true
    }
    
    var velocityReason: String = ""
    
    func findCarAhead() {
        carAhead = current.cars.first { $0.progress > progress }
        
        carInSameRoad = carAhead != nil
        if (carAhead != nil ) { // If there's a car in the same section of road, that's the car ahead
            carDistance = carAhead!.progress - progress
            carInSameRoad = true
        } else if (next.cars.count > 0) { // Otherwise, look at the next section
            carAhead = next.cars.first!
            carDistance = distanceToNext + carAhead!.progress
        } else if (onRoad && (next as! Linkage).to.cars.count > 0)  { // If we can tell what the nextion section of road is, find the first car, if there is one
            carAhead = (next as! Linkage).to.cars.first!
            carDistance = distanceToNext + next.distance + carAhead!.progress
        }
    }
    
    func checkTurn() {
        if (distanceToNext < 0) {
            progress = 0 // Reset progress
            current.cars.removeAll { $0 == self } // Remove from current road
            current = next // The current road is now the old next road
            current.cars.append(self) // Add self to the new list of cars
            current.cars.sort { $0.progress < $1.progress } // Make sure everything's in order (this saves computation later)
            nextRoad() // Clean up (position car, choose next route, etc)
        }
    }
    
    func updatePosition() {
        progress += velocity
        scene.stats["distance"]! += velocity
        // If something has gone dreadfully wrong, ignore it
        if (position.x.isFinite && position.y.isFinite) {
            node.position = position
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if (!exists) {
            return
        }
    }
    
    init(node: SKSpriteNode, scene: GameScene, road: Drivable) {
        self.node = node
        self.scene = scene
        self.current = road
        next = road // Will be immediately overriden following call to super
        id = Car.nextID
        Car.nextID += 1
        super.init()
        
        nextRoad()
        
        node.anchorPoint.y = 1
    }
    
    func nextRoad() {
        // If the current path is a Linkage, the next path is the road it leads to. If it's a road, go to a random linkage
        if (type(of: current) == Linkage.self) {
            if (scene.road.intersection.linkages.contains(current as! Linkage)) {
                scene.stats["cars through intersection"]! += 1
            }
            next = (current as! Linkage).to
        } else {
            next = (current as! Road).linkages.randomElement()!
        }
        
        let to = current.location(progress: current.distance)
        let from = current.location(progress: 0)
        let angle = atan2(to.y - from.y, to.x - from.x) - CGFloat.pi / 2
        node.run(SKAction.rotate(toAngle: angle, duration: 0.25, shortestUnitArc: true))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var exists = true
    
    deinit {
        current.cars.removeAll { $0 == self }
        node.removeFromParent()
        if let idx = scene.entities.firstIndex(of: self) {
            scene.entities.remove(at: idx)
        }
        exists = false
    }
}
