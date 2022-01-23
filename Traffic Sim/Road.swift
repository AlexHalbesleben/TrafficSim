//
//  Road.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/1/21.
//

import Foundation
import GameplayKit

protocol Drivable {
    var cars: [Car] { get set }
    var distance: CGFloat { get }
    
    var lastCar: Car? { get }
    var lastCarDest: Drivable? { get }
    
    func location(progress: CGFloat) -> CGPoint
}

class Road: Drivable, Equatable {
    static func == (lhs: Road, rhs: Road) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to && lhs.linkages == rhs.linkages
    }
    
    var lastCar: Car? {
        get {
            if (cars.count <= 0) {
                return nil
            }
            return cars.last!
        }
    }
    var lastCarDest: Drivable? {
        lastCar?.next
    }
    
    func carWillTurn(_ to: Linkage) -> Bool {
        return lastCar != nil && lastCarDest! as! Linkage == to && lastCar!.velocity * 2 < lastCar!.distanceToNext
    }
    
    var from: CGPoint
    var to: CGPoint
    
    var cars: [Car] = []
    
    var linkages: [Linkage] = []
    
    var distance: CGFloat {
        sqrt((to.x - from.x) * (to.x - from.x) + (to.y - from.y) * (to.y - from.y))
    }
    
    init(_ from: CGPoint, _ to: CGPoint, _ scene: GameScene) {
        self.from = from
        self.to = to
    }
    
    convenience init(_ fromX: CGFloat, _ fromY: CGFloat, _ toX: CGFloat, _ toY: CGFloat, _ scene: GameScene) {
        self.init(CGPoint(x: fromX, y: fromY), CGPoint(x: toX, y: toY), scene)
    }
    
    func location(progress: CGFloat) -> CGPoint {
        let x = (to.x - from.x) * (progress / distance) + from.x - 192
        let y = (to.y - from.y) * (progress / distance) + from.y
        return CGPoint(x: x, y: y)
    }
}

class Linkage: Drivable, Equatable {
    var from: Road
    var to: Road
    
    static func == (lhs: Linkage, rhs: Linkage) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
    
    var lastCar: Car? {
        get {
            if (cars.count <= 0) {
                return nil
            }
            return cars.last!
        }
    }
    var lastCarDest: Drivable? {
        lastCar?.next
    }
    
    var cars: [Car] = []
    var isEmpty: Bool {
        cars.count == 0
    }
    
    var distance: CGFloat {
        sqrt((to.from.x - from.to.x) * (to.from.x - from.to.x) + (to.from.y - from.to.y) * (to.from.y - from.to.y))
    }
    
    var canTurn: (_ isHuman: Bool) -> Bool = { _ in true }
    var thru: Bool {
        (from.from.x == from.to.x && from.to.x == to.from.x && to.from.x == to.to.x)
            || (from.from.y == from.to.y && from.to.y == to.from.y && to.from.y == to.to.y)
    }
    
    init(_ from: Road, _ to: Road, _ scene: GameScene) {
        self.from = from
        self.to = to
        from.linkages.append(self)
    }
    
    func location(progress: CGFloat) -> CGPoint {
        let x = (to.from.x - from.to.x) * (progress / distance) + from.to.x - 192
        let y = (to.from.y - from.to.y) * (progress / distance) + from.to.y
        return CGPoint(x: x, y: y)
    }
}

class FourWay {
    var downTo: Road
    var downFrom: Road
    var upTo: Road
    var upFrom: Road
    var rightTo: Road
    var rightFrom: Road
    var leftTo: Road
    var leftFrom: Road
    
    var upThru: Linkage
    var downThru: Linkage
    var rightThru: Linkage
    var leftThru: Linkage
    
    var upRight: Linkage
    var rightRight: Linkage
    var downRight: Linkage
    var leftRight: Linkage
    
    var upLeft: Linkage
    var rightLeft: Linkage
    var downLeft: Linkage
    var leftLeft: Linkage
    
    var linkages: [Linkage] {
        [upThru, downThru, rightThru, leftThru, upRight, downRight, leftRight, rightRight, upLeft, downLeft, leftLeft, rightLeft]
    }
    
    var downLight: LightColors = .GREEN
    var upLight: LightColors = .GREEN
    var rightLight: LightColors = .RED
    var leftLight: LightColors = .RED
    
    var scene: GameScene
    
    init(downTo: Road, downFrom: Road, upTo: Road, upFrom: Road, rightTo: Road, rightFrom: Road, leftTo: Road, leftFrom: Road, _ scene: GameScene) {
        self.downTo = downTo
        self.downFrom = downFrom
        self.upTo = upTo
        self.upFrom = upFrom
        self.rightTo = rightTo
        self.rightFrom = rightFrom
        self.leftTo = leftTo
        self.leftFrom = leftFrom
        
        self.scene = scene
        
        upThru = Linkage(downTo, upFrom, scene)
        downThru = Linkage(upTo, downFrom, scene)
        rightThru = Linkage(leftTo, rightFrom, scene)
        leftThru = Linkage(rightTo, leftFrom, scene)
        
        upRight = Linkage(upTo, leftFrom, scene)
        leftRight = Linkage(leftTo, downFrom, scene)
        downRight = Linkage(downTo, rightFrom, scene)
        rightRight = Linkage(rightTo, upFrom, scene)
        
        upLeft = Linkage(upTo, rightFrom, scene)
        rightLeft = Linkage(rightTo, downFrom, scene)
        downLeft = Linkage(downTo, leftFrom, scene)
        leftLeft = Linkage(leftTo, upFrom, scene)
        
        upThru.canTurn = { [self] _ in upLight == .GREEN && rightThru.isEmpty && leftThru.isEmpty }
        downThru.canTurn = { [self] _ in downLight == .GREEN && rightThru.isEmpty && leftThru.isEmpty }
        rightThru.canTurn = { [self] _ in rightLight == .GREEN && upThru.isEmpty && downThru.isEmpty }
        leftThru.canTurn = { [self] _ in leftLight == .GREEN && upThru.isEmpty && downThru.isEmpty }
        
        // FIXME - no implementation of right on red
        upRight.canTurn = { [self] _ in upLight == .GREEN || (upLight == .RED && rightThru.isEmpty && !rightTo.carWillTurn(rightThru)) }
        downRight.canTurn = { [self] _ in downLight == .GREEN || (downLight == .RED && leftThru.isEmpty && !leftTo.carWillTurn(rightThru)) }
        rightRight.canTurn = { [self] _ in rightLight == .GREEN || (rightLight == .RED && downThru.isEmpty && !downTo.carWillTurn(downThru)) }
        leftRight.canTurn = { [self] _ in leftLight == .GREEN || (leftLight == .RED && upThru.isEmpty && !upTo.carWillTurn(upThru))}
        
        upLeft.canTurn = { [self] _ in upLight == .GREEN_ARROW }
        downLeft.canTurn = { [self] _ in downLight == .GREEN_ARROW }
        rightLeft.canTurn = { [self] _ in rightLight == .GREEN_ARROW }
        leftLeft.canTurn = { [self] _ in leftLight == .GREEN_ARROW }
        
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in self.updateLights() })
    }
    
    // FIXME - Turn lights are yellow
    func updateLights() {
        scene.stats["light changes"]! += 1
        if (upLight == .GREEN) {
            upLight = .RED
            downLight = .RED
            rightLight = .GREEN_ARROW
            leftLight = .GREEN_ARROW
            
            scene.upLight?.color = .red
            scene.downLight?.color = .red
            scene.rightLight?.color = .white
            scene.leftLight?.color = .white
        } else if (rightLight == .GREEN_ARROW) {
            rightLight = .GREEN
            leftLight = .GREEN
            
            scene.rightLight?.color = .green
            scene.leftLight?.color = .green
        } else if (rightLight == .GREEN) {
            rightLight = .RED
            leftLight = .RED
            upLight = .GREEN_ARROW
            downLight = .GREEN_ARROW
            
            scene.rightLight?.color = .red
            scene.leftLight?.color = .red
            scene.upLight?.color = .white
            scene.downLight?.color = .white
        } else if (upLight == .GREEN_ARROW) {
            upLight = .GREEN
            downLight = .GREEN
            
            scene.upLight?.color = .green
            scene.downLight?.color = .green
        } else {
            fatalError("Invalid traffic lights")
        }
    }
}

class SideRoad {
    var outsideLaneFrom: Road
    var outsideLaneTo: Road
    var insideLaneFrom: Road
    var insideLaneTo: Road
    var sideToLane: Road
    var sideFromLane: Road
    
    var outsideLinkage: Linkage
    var insideLinkage: Linkage
    var insideSideLinkage: Linkage
    var outsideSideLinkage: Linkage
    var sideInsideLinkage: Linkage
    var sideOutsideLinkage: Linkage
    
    init(outsideLaneFrom: Road, outsideLaneTo: Road, insideLaneFrom: Road, insideLaneTo: Road, sideToLane: Road, sideFromLane: Road, _ scene: GameScene) {
        self.outsideLaneFrom = outsideLaneFrom
        self.outsideLaneTo = outsideLaneTo
        self.insideLaneFrom = insideLaneFrom
        self.insideLaneTo = insideLaneTo
        self.sideToLane = sideToLane
        self.sideFromLane = sideFromLane
        
        outsideLinkage = Linkage(outsideLaneTo, outsideLaneFrom, scene)
        insideLinkage = Linkage(insideLaneTo, insideLaneFrom, scene)
        insideSideLinkage = Linkage(insideLaneTo, sideFromLane, scene)
        outsideSideLinkage = Linkage(outsideLaneTo, sideFromLane, scene)
        sideInsideLinkage = Linkage(sideToLane, insideLaneFrom, scene)
        sideOutsideLinkage = Linkage(sideToLane, outsideLaneFrom, scene)
        
        outsideLinkage.canTurn = { [self] _ in outsideSideLinkage.isEmpty && sideOutsideLinkage.isEmpty }
        insideLinkage.canTurn = { [self] _ in outsideSideLinkage.isEmpty && sideOutsideLinkage.isEmpty && insideSideLinkage.isEmpty && sideInsideLinkage.isEmpty }
        insideSideLinkage.canTurn = { [self] _ in outsideSideLinkage.isEmpty }
        sideInsideLinkage.canTurn = { [self] _ in insideLinkage.isEmpty && !(insideLaneTo.lastCar != nil && insideLaneTo.lastCarDest! as! Linkage == insideLinkage && insideLaneTo.lastCar!.distanceToNext < 50) }
        outsideSideLinkage.canTurn = { [self] _ in insideLinkage.isEmpty && insideSideLinkage.isEmpty && sideOutsideLinkage.isEmpty }
        sideOutsideLinkage.canTurn = { [self] _ in insideLinkage.isEmpty && outsideLinkage.isEmpty && outsideSideLinkage.isEmpty }
    }
}

class Roads {
    // Naming conventions for outside roads:
    // out(Up|Down|Right|Left)(Up|Down|Right|Left)(Out|In)
    // out(overall section)(section of section)(out or in)
    var outRightUpOut: Road
    var outRightUpIn: Road
    var outRightDownOut: Road
    var outRightDownIn: Road
    var outLeftUpOut: Road
    var outLeftUpIn: Road
    var outLeftDownOut: Road
    var outLeftDownIn: Road
    var outUpRightOut: Road
    var outUpRightIn: Road
    var outUpLeftOut: Road
    var outUpLeftIn: Road
    var outDownRightOut: Road
    var outDownRightIn: Road
    var outDownLeftOut: Road
    var outDownLeftIn: Road
    
    // Naming conventions for inside roads:
    // in(Up|Down|Right|Left)(Up|Down|Right|Left)
    // in(overall section)(lane)
    var inRightUp: Road
    var inRightDown: Road
    var inLeftUp: Road
    var inLeftDown: Road
    var inUpRight: Road
    var inUpLeft: Road
    var inDownRight: Road
    var inDownLeft: Road
    
    var intersection: FourWay
    
    var upSideRoad: SideRoad
    var downSideRoad: SideRoad
    var rightSideRoad: SideRoad
    var leftSideRoad: SideRoad
    
    var upRightCornerOut: Linkage
    var downRightCornerOut: Linkage
    var downLeftCornerOut: Linkage
    var upLeftCornerOut: Linkage
    
    var upRightCornerIn: Linkage
    var downRightCornerIn: Linkage
    var downLeftCornerIn: Linkage
    var upLeftCornerIn: Linkage
    
    init(scene: GameScene) {
        outRightUpOut = Road(360, 50, 360, 340, scene)
        outRightUpIn = Road(300, 280, 300, 50, scene)
        outRightDownOut = Road(360, -340, 360, -50, scene)
        outRightDownIn = Road(300, -50, 300, -280, scene)
        
        outLeftUpOut = Road(-360, 340, -360, 50, scene)
        outLeftUpIn = Road(-300, 50, -300, 280, scene)
        outLeftDownOut = Road(-360, -50, -360, -340, scene)
        outLeftDownIn = Road(-300, -280, -300, -50, scene)
        
        outUpRightOut = Road(340, 360, 50, 360, scene)
        outUpRightIn = Road(50, 300, 280, 300, scene)
        outUpLeftOut = Road(-50, 360, -340, 360, scene)
        outUpLeftIn = Road(-280, 300, -50, 300, scene)
        
        outDownRightOut = Road(50, -360, 340, -360, scene)
        outDownRightIn = Road(280, -300, 50, -300, scene)
        outDownLeftOut = Road(-340, -360, -50, -360, scene)
        outDownLeftIn = Road(-50, -300, -280, -300, scene)
        
        inRightUp = Road(280, 25, 50, 25, scene)
        inRightDown = Road(50, -25, 280, -25, scene)
        inLeftUp = Road(-50, 25, -280, 25, scene)
        inLeftDown = Road(-280, -25, -50, -25, scene)
        
        inUpRight = Road(25, 50, 25, 280, scene)
        inUpLeft = Road(-25, 280, -25, 50, scene)
        inDownRight = Road(25, -280, 25, -50, scene)
        inDownLeft = Road(-25, -50, -25, -280, scene)
        
        intersection = FourWay(downTo: inDownRight, downFrom: inDownLeft, upTo: inUpLeft, upFrom: inUpRight, rightTo: inRightUp, rightFrom: inRightDown, leftTo: inLeftDown, leftFrom: inLeftUp, scene)
        
        upSideRoad = SideRoad(outsideLaneFrom: outUpLeftOut, outsideLaneTo: outUpRightOut, insideLaneFrom: outUpRightIn, insideLaneTo: outUpLeftIn, sideToLane: inUpRight, sideFromLane: inUpLeft, scene)
        downSideRoad = SideRoad(outsideLaneFrom: outDownRightOut, outsideLaneTo: outDownLeftOut, insideLaneFrom: outDownLeftIn, insideLaneTo: outDownRightIn, sideToLane: inDownLeft, sideFromLane: inDownRight, scene)
        rightSideRoad = SideRoad(outsideLaneFrom: outRightUpOut, outsideLaneTo: outRightDownOut, insideLaneFrom: outRightDownIn, insideLaneTo: outRightUpIn, sideToLane: inRightDown, sideFromLane: inRightUp, scene)
        leftSideRoad = SideRoad(outsideLaneFrom: outLeftDownOut, outsideLaneTo: outLeftUpOut, insideLaneFrom: outLeftUpIn, insideLaneTo: outLeftDownIn, sideToLane: inLeftUp, sideFromLane: inLeftDown, scene)
        
        upRightCornerOut = Linkage(outRightUpOut, outUpRightOut, scene)
        upLeftCornerOut = Linkage(outUpLeftOut, outLeftUpOut, scene)
        downLeftCornerOut = Linkage(outLeftDownOut, outDownLeftOut, scene)
        downRightCornerOut = Linkage(outDownRightOut, outRightDownOut, scene)
        
        upRightCornerIn = Linkage(outUpRightIn, outRightUpIn, scene)
        downRightCornerIn = Linkage(outRightDownIn, outDownRightIn, scene)
        downLeftCornerIn = Linkage(outDownLeftIn, outLeftDownIn, scene)
        upLeftCornerIn = Linkage(outLeftUpIn, outUpLeftIn, scene)
    }
}
