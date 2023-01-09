//
//  Player.swift
//  
//
//  Created by Andrew Satori on 1/8/23.
//

import Foundation
import RESTfulCore

public class Player : RESTObject, Identifiable {
    /// Interanl path for the api on the server.
    internal static let path : String = "unittest/api/Players"
    private var _connection : Connection? = nil
    
    public var playerId: Int64?
    public var playerName: String?
    
    public override init() {
        // an empty init for put/post methods to use
        super.init()
    }
    
    public init(_ id: Int64) {
        // an empty init for put/post methods to use
        super.init()
        self.playerId = id
    }
    
    required public init(with: [String: Any]?) {
        super.init(with: with)
        
        playerId = with!["playerId"] as? Int64
        playerName = with!["playerName"] as? String
    }
    /*
    public func delete() -> Bool {
        connection.delete(
            path: Tag.path,
            id: String(self.tagId!),
            completion: { (result : Bool ) in
                completion(result)
            }) { (error) in
            failure(error)
        }
    }
    
    public func save(
        connection: Connection,
        completion: @escaping (Player?) -> Void,
        failure: @escaping (String) -> Void
    ) {
        if (!isDirty) { return }
        if (isNew) {
            // post
            connection.post(
                path: Tag.path,
                model: self,
                completion: { (result : Tag? ) in
                    if (result == nil) { failure("Request returned an empty result") }
                    completion(result)
                }) { (error) in
                failure(error)
            }
        } else {
            // put
            connection.put(
                path: Tag.path,
                id: String(self.tagId!),
                model: self,
                completion: { (result : Tag? ) in
                    if (result == nil) { failure("Request returned an empty result") }
                    completion(result)
                }) { (error) in
                failure(error)
            }
        }
    }
     */
     
    // MARK: Identifiable

    
    // MARK: Codable
    
    private enum CodingKeys: String, CodingKey {
        case playerId
        case playerName
    }
    
    // MARK: Decodable
    
    public required init(from: Decoder) throws {
        try super.init(from: from)
        
        let values = try from.container(keyedBy: CodingKeys.self)
        
        self.playerId = try values.decodeIfPresent(Int64.self, forKey: .playerId)!
        self.playerName = try values.decodeIfPresent(String.self, forKey: .playerName)!
    }
    
    // MARK: Encodable
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(playerId, forKey: .playerId)
        try container.encode(playerName, forKey: .playerName)
    }
    
    // MARK: Equitable
    
    public static func == (lhs: Player, rhs: Player) -> Bool {
        if (lhs.playerId == rhs.playerId) { return false }
        if (lhs.playerName == rhs.playerName) { return false }

        return true;
    }
    
    // MARK: Hashable Protocol
    
    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        hasher.combine(playerId)
        hasher.combine(playerName)
    }
}

// MARK: Connection Methods

extension Player {
    
    /// Player.get() fetches a Player from the server referenced by the Id
    /// passed to the server.
    ///
    /// # Notes#
    /// An active API.Connection is required.
    ///
    /// - Parameters:
    ///   - connection: A Connection instance, usually a shared instance
    ///   - id: an Int64 id representing a tag
    ///   - completion: A closure function that returns the resulting APITag
    ///   - failure: If an error occurs, the failure closure is called with the
    ///              error condition in the result
    public static func get(connection: Connection, id: Int64) async throws -> Player? {
        let result : Player? = try await connection.get(path: Player.path, id: "\(id)")
        return result
    }
    /*
    /// APITag.list() requires a connection, and takes option page and length parameters to request a list of
    ///   APITags from the API.
    ///
    /// ** NOTE ** At some time in the near future this will need to be altered
    ///            to support two factor authentiation methods.
    /// - Parameters:
    ///   - connection: An APIConnection instance, usually a shared instance
    ///   - user: A string value of the user login name ( or email )
    ///   - password: A string value of the user password ( will not be returned )
    ///   - completion: A closure function that returns the resulting APISession
    ///   - failure: If an error occurs, the failure closure is called with the
    ///              error condition in the result
    public static func list(connection: Connection,
                            completion: @escaping (APIList<Tag>) -> Void,
                            failure: @escaping (String) -> Void,
                            page: Int = 0, count: Int = 100
    ) {
        connection.list(path: Tag.path,
                        completion: { (result : APIList<Tag>? ) in
            if (result == nil) { failure("Request returned an empty result") }
            completion(result!)
        }, failure: { (error) in
            failure(error)
        }, page: page, count: count)
    }

    // query
    
    // put
    // post
    // delete
     */
}

