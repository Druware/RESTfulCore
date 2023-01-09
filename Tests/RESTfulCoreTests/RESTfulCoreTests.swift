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
    
    func testGetPlayer() {
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

    func testGetPlayerAsync() async throws {
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
}
