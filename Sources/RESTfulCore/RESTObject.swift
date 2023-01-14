//
//  APIObject.swift
//  Druware Server Admin
//
//  Created by Andrew Satori on 3/27/21.
//

import Foundation

open class RESTResultObject {
    required public init() { }
    required public init(with: [String: Any]?) { }
}

open class RESTObject : RESTResultObject, Hashable, Codable {
    // MARK: Static Functions
    public static func == (lhs: RESTObject, rhs: RESTObject) -> Bool {
        return true
    }
    
    // MARK: Constructors
    public required init() {
        super.init()
    }
    
    required public init(with: [String: Any]?) {
        super.init(with: with)
        if (with != nil) {
        }
    }
    
    required public init(from: Decoder) throws {
        super.init()
        
        // let values = try from.container(keyedBy: CodingKeys.self)
    }
        
    // MARK: Hashable Protocol
    open func hash(into hasher: inout Hasher) {
    }
}
