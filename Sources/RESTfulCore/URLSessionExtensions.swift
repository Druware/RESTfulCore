#if (os(Windows))

import Foundation
import FoundationNetworking


enum RESTfulCoreError: Error {
    case DataIsNil
    case ResultIsNil
    case Unspecified(String)
}

extension URLSession {
    private func fetchData(for request: URLRequest, completion: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        self.dataTask(with: request) { (data, response, error) in 
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(RESTfulCoreError.DataIsNil))
                return
            }

            guard let response = response else {
                completion(.failure(RESTfulCoreError.ResultIsNil))
                return
            }
            
            completion(.success((data, response)))        
        }.resume()
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let results : (Data, URLResponse) = try await withCheckedThrowingContinuation({ continuation in
            self.fetchData(for: request) { result in
                switch result {
                case .success(let contents):
                    // Resume with fetched albums
                    continuation.resume(returning: contents)
                    
                case .failure(let error):
                    // Resume with error
                    continuation.resume(throwing: error)
                }
            }
        })
        
        return results
    }
}

#endif