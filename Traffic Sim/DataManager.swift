//
//  DataManager.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 1/8/22.
//

import Foundation

class DataManager {
    static let keys = ["DCS", "aDCS", "hDCS", "CPL"]
    
    var id: UUID = UUID()
    
    init() {
        for key in DataManager.keys {
            UserDefaults.standard.set(Array(repeating: [], count: 11), forKey: "\(id)_\(key)")
        }
    }
    
    func addEntry(key: String, density: CGFloat, value: CGFloat) {
        let index = Int(density / 10)
        var data: [[CGFloat]] = UserDefaults.standard.array(forKey: "\(id)_\(key)") as! [[CGFloat]]
        data[index].append(value)
        UserDefaults.standard.set(data, forKey: "\(id)_\(key)")
    }
    
    func getValues(key: String, density: Int) -> [CGFloat] {
        return UserDefaults.standard.array(forKey: "\(id)_\(key)")![density] as! [CGFloat]
    }
    
    func getValues(key: String, density: CGFloat) -> [CGFloat] {
        return getValues(key: key, density: Int(density / 10))
    }
    
    
    func output() {
        for key in DataManager.keys {
            print(key)
            for density in 0...10 {
                for value in getValues(key: key, density: density) {
                    print(value)
                }
            }
            print("\n")
        }
    }
}
