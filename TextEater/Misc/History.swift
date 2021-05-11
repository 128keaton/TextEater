//
//  History.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/7/21.
//

import Foundation


class History {
    static let shared = History()
    
    private var items: [String] = []
    
    private init() {
    }
    
    public func add(_ item: String) {
        self.items.append(self.cleanString(item))
    }
    
    public func clear() {
        self.items = []
    }
    
    public func getString() -> String {
        return self.items.joined(separator: "\n")
    }
    
    private func cleanString(_ input: String) -> String {
        if input.hasSuffix("\n") {
            return String(input.dropLast())
         }
        
        return input
    }
}
