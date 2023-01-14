//
//  APIList.swift
//  Druware Server Admin
//
//  Created by Andrew Satori on 3/31/21.
//

// TODO: Document RESTObjectList

import Foundation

public class RESTObjectList<T : RESTObject> : RESTResultObject {
    public var totalRecords : Int64 = 0
    public var page : Int = 0
    public var perPage : Int = 10
    public var list : [T] = [T]()
    public var succeeded : Bool = true
    public var info : [String] = [String]()
    
    required public init(with: [String: Any]?) {
        super.init(with: with)
        if (with == nil) { return }
        
        // process the array
        if let temp = with!["list"] as? [[String: Any]] {
            temp.forEach { item in
                list.append(T(with: item))
            }
        }
        
        totalRecords = with!["totalRecords"] as! Int64
        page = with!["page"] as! Int
        perPage = with!["perPage"] as! Int
        succeeded = (with!["succeeded"] as? Bool ?? false)
        if (with!["info"] != nil)
        {
            info = with!["info"] as! [String]
        }
    }
    
    required public init() {
        super.init()
    }
}
