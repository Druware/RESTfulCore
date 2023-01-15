import XCTest
@testable import RESTfulCore

final class RESTfulCoreTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(RESTfulCore().text, "Hello, World!")
    }
    
    func testBuildUrl() throws {
        let rootPath = "https://www.trustee13.com/";
        let path = "/api/controller/";
        let id = 12;

        let connection = Connection(basePath: rootPath)
        let result = connection.buildUrlString(parts: path, "", "\(id)");

        XCTAssertEqual(result,
                       "https://www.trustee13.com/api/controller/12/",
                       "Resulting String does not match expected result")
    }
    
    func testList() {
        let expectation = XCTestExpectation(description: "testListPlayers")

        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";

        let connection = Connection(basePath: rootPath)
       
        
        connection.list(path: path) { (results: Result<[Player]?, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("Nope")
            case .success(let players):
                XCTAssertNotNil(players, "Result is nil")
                XCTAssertTrue(players?.count ?? 0 > 1, "Players.Count is not greater than 1")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testListAsync() async throws {
        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";

        let connection = Connection(basePath: rootPath)
       
        let players: [Player]? = try await connection.list(path: path)
        if (players == nil) {
            print(connection.info!)
        }
        
        XCTAssertNotNil(players, "Result is nil")
        XCTAssertTrue(players?.count ?? 0 > 1, "Players.Count is not greater than 1")
        // XCTAssertTrue(player?.playerName == "Mickey Mouse", "PlayerName is not 'Mickey Mouse'")

    }
    
    func testConnectionGet() {
        let expectation = XCTestExpectation(description: "testGetPlayer")
        
        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";
        let id = 1;

        let connection = Connection(basePath: rootPath)
        
        connection.get(path: path, id: "\(id)") { (results: Result<Player?, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("Nope")
            case .success(let player):
                XCTAssertNotNil(player, "Result is nil")
                XCTAssertTrue(player?.playerId == 1, "PlayerId is not 1")
                XCTAssertTrue(player?.playerName == "Mickey Mouse", "PlayerName is not 'Mickey Mouse'")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }

    func testConnectionGetAsync() async throws {
        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";
        let id = 1;

        let connection = Connection(basePath: rootPath)
       
        let player : Player? = try await connection.get(path: path, id: "\(id)")
        if (player == nil) {
            print(connection.info!)
        }
        
        XCTAssertNotNil(player, "Result is nil")
        XCTAssertTrue(player?.playerId == 1, "PlayerId is not 1")
        XCTAssertTrue(player?.playerName == "Mickey Mouse", "PlayerName is not 'Mickey Mouse'")
    }
    
    func testPlayerGet() {
        let expectation = XCTestExpectation(description: "testGetPlayer")
        
        let rootPath = "https://www.trustee13.com/"
        let id = 1;

        let connection = Connection(basePath: rootPath)
        
        Player.get(connection: connection, id: Int64(id)) { (results: Result<Player?, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("Nope")
            case .success(let player):
                XCTAssertNotNil(player, "Result is nil")
                XCTAssertTrue(player?.playerId == 1, "PlayerId is not 1")
                XCTAssertTrue(player?.playerName == "Mickey Mouse", "PlayerName is not 'Mickey Mouse'")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetPlayerAsync() async throws {
        let rootPath = "https://www.trustee13.com/"
        let id = 1

        let connection = Connection(basePath: rootPath)
       
        let player : Player? = try await Player.get(connection: connection, id: Int64(id))
        if (player == nil) {
            print(connection.info!)
        }
        
        XCTAssertNotNil(player, "Result is nil")
        XCTAssertTrue(player?.playerId == 1, "PlayerId is not 1")
        XCTAssertTrue(player?.playerName == "Mickey Mouse", "PlayerName is not 'Mickey Mouse'")

    }
    
    func testPostPlayer() {
        let expectation = XCTestExpectation(description: "testPostPlayer")
        
        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";

        let newPlayer = Player()
        newPlayer.playerName = "Swift Test Player"
        
        let connection = Connection(basePath: rootPath)
        
        connection.post(path: path, model: newPlayer) { (results: Result<Player?, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
            case .success(let player):
                XCTAssertNotNil(player, "Result is nil")
                XCTAssertTrue(player?.playerId ?? 0 > 0, "PlayerId is not set")
                XCTAssertTrue(player?.playerName == "Swift Test Player", "PlayerName is not 'Swift Test Player'")
                
                newPlayer.playerId = player?.playerId
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)

        let delExp = XCTestExpectation(description: "testPostPlayer->Delete")
        
        if (newPlayer.playerId == nil) {
            XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
            return
        }

        connection.delete(path: path, id: String(newPlayer.playerId ?? 0)) { (results: Result<Bool, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
            case .success(let result):
                XCTAssertTrue(result, "Result SHOULD be true")
            }
            delExp.fulfill()
        }

        wait(for: [delExp], timeout: 10.0)

    }
    
    func testPostPlayerAsync() async throws {
        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";
        
        let newPlayer = Player()
        newPlayer.playerName = "Swift Test Async Player"
        
        let connection = Connection(basePath: rootPath)
       
        let player : Player? = try await connection.post(path: path, model: newPlayer)
        if (player == nil) {
            print(connection.info!)
            XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
        }
        
        XCTAssertNotNil(player, "Result is nil")
        XCTAssertTrue(player?.playerId ?? 0 > 0, "PlayerId is not set")
        XCTAssertTrue(player?.playerName == "Swift Test Async Player", "PlayerName is not 'Swift Test Async Player'")
        
        if (player?.playerId == nil) {
            XCTFail("New Player has no ID returned: \(connection.info?.joined(separator:"\n") ?? "unknown")")
            return
        }
        
        let result : Bool = try await connection.delete(path: path, id: String(player!.playerId!))
        XCTAssertTrue(result, "Result SHOULD be true")
    }
    
    func testPutPlayer() {
        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";
        let id = 6 // Pluto

        let connection = Connection(basePath: rootPath)
        
        var player : Player? = nil

        let getExp = XCTestExpectation(description: "testPutPlayer->Get")

        connection.get(path: path, id: "\(id)") { (results: Result<Player?, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
                getExp.fulfill()
            case .success(let p):
                XCTAssertNotNil(p, "Result is nil")
                XCTAssertTrue(p?.playerId == 6, "PlayerId is not 6")
                XCTAssertTrue(p?.playerName == "Pluto", "PlayerName is not 'Pluto'")
                player = p
                getExp.fulfill()
            }
        }
        
        wait(for: [getExp], timeout: 5.0)
        
        if (player == nil)
        {
            XCTFail("Get returned nothing")
            return
        }
        
        // alter the name
        player!.playerName = "Plato"
       
        let putExp = XCTestExpectation(description: "testPutPlayer->Put")
        
        connection.put(path: path, id: String(id), model: player!) { (results: Result<Player?, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
                putExp.fulfill()
            case .success(let player):
                XCTAssertNotNil(player, "Result is nil")
                XCTAssertTrue(player?.playerId ?? 0 > 0, "PlayerId is not set")
                XCTAssertTrue(player?.playerName == "Plato", "PlayerName is not 'Plato'")
                putExp.fulfill()
            }
        }
        
        wait(for: [putExp], timeout: 5.0)
       
        // Reset the name
        player!.playerName = "Pluto"
        
        let restoreExp = XCTestExpectation(description: "testPutPlayer->Restore")
        
        connection.put(path: path, id: String(id), model: player!) { (results: Result<Player?, Error>) in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
                restoreExp.fulfill()

            case .success(let player):
                XCTAssertNotNil(player, "Result is nil")
                XCTAssertTrue(player?.playerId ?? 0 > 0, "PlayerId is not set")
                XCTAssertTrue(player?.playerName == "Pluto", "PlayerName is not 'Pluto'")
                restoreExp.fulfill()

            }
        }
        
        wait(for: [restoreExp], timeout: 5.0)
    }
    
    func testPutPlayerAsync() async throws {
        let rootPath = "https://www.trustee13.com/";
        let path = "/unittest/api/Players/";
        let id = 6

        let connection = Connection(basePath: rootPath)

        var player : Player? = try await connection.get(path: path, id: "\(id)")
        if (player == nil) {
            print(connection.info!)
            XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
            return
        }
        XCTAssertNotNil(player, "Result is nil")
        XCTAssertTrue(player?.playerId == 6, "PlayerId is not 6")
        XCTAssertTrue(player?.playerName == "Pluto", "PlayerName is not 'Pluto'")
       
        player?.playerName = "Plato"
       
        player = try await connection.put(path: path, id: String(id), model: player!)
        if (player == nil) {
            print(connection.info!)
            XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
            return
        }
        
        XCTAssertNotNil(player, "Result is nil")
        XCTAssertTrue(player?.playerId ?? 0 > 0, "PlayerId is not set")
        XCTAssertTrue(player?.playerName == "Plato", "PlayerName is not 'Plato'")
        
        player?.playerName = "Pluto"
       
        player = try await connection.put(path: path, id: String(id), model: player!)
        if (player == nil) {
            print(connection.info!)
            XCTFail("A Failure Occured: \(connection.info?.joined(separator:"\n") ?? "unknown")")
            return
        }
        
        XCTAssertNotNil(player, "Result is nil")
        XCTAssertTrue(player?.playerId ?? 0 > 0, "PlayerId is not set")
        XCTAssertTrue(player?.playerName == "Pluto", "PlayerName is not 'Pluto'")
    }
    
    // delete
    
    
    
}
