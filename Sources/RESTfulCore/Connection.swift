//
//  Connection.swift
//  RESTfulCore
//
//  Created by Andrew Satori on 3/31/21.
//

// TODO: Complete documentation of Connection Methods

import Foundation


enum ConnectionError: Error {
    case requestError(String)
}

public typealias ConnectionOperationFailure =  (String) -> Void

/// The Connection object is the root of all server communication with the API,
/// and as such, it implements both the primitive functions that the RESTObject
/// based objects use, it is also the cornerstone object that an application
/// uses throughout the lifecycle of an application.
public class Connection {
    
    private var rootPath : String
    public var info : [String]? = nil
    private var urlSession : URLSession

    /// The core initialiizer for a Connection, with the basePath being the
    /// hostPath ( including the [http/https]://hostname portion of the path )
    /// - Parameter basePath: <#basePath description#>
    public init(basePath: String) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpCookieAcceptPolicy = .always
        sessionConfig.httpShouldSetCookies = true
        HTTPCookieStorage.shared.cookies(for: URL(string: basePath)!)

        urlSession = URLSession(configuration: sessionConfig)
        self.rootPath = basePath
    }
    
    /// Builds a URL from string parts, appended to the internal rootPath that
    /// was established upon creation of the Connection object.
    ///
    /// - parameter parts: an array of the string parts to be appended to the
    ///                    path
    /// - returns: the resulting string, with properly formed elements using a
    ///            "/" delimiter
    ///
    /// # Notes: #
    /// * At this point, the code works, but will probably be identified to have
    ///   issues once evaluated more fully.
    ///
    /// # Example #
    /// ```
    /// let conn = Connection(basePath: "http://localhost")
    /// let url = conn.buildUrlString(parts: "api/controller/", "itemId")
    /// // resulting url = "http://localhost/api/controller/itemId"
    /// print(url)
    /// ```
    public func buildUrlString(parts : String ...) -> String {
        var result : String = rootPath + (rootPath.hasSuffix("/") ? "" : "/")

        for s : String in parts {
            result += (s.hasPrefix("/") ?
                       String(s[(s.index(after: s.firstIndex(of: "/")!))...]) : s)
            result += (result.hasSuffix("/") ? "" : "/")
        }

        return result;
    }
    
    private func setInfo(_ value: String) -> Void {
        if (info == nil) { info = [String]() }
        info?.append(value)
    }
    
    public func get<T: RESTObject>(path: String, id: String?) async throws -> T? {
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        // TODO: add guard around potential nil url result
        
        do {
            let (data, response) = try await urlSession.data(from: url!)
            
            if ((response as? HTTPURLResponse)?.statusCode != 200) {
                setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)?.statusCode)")
                return nil
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                    return nil
                }

                let result = T(with: json)
                // if the status is a failure call the failure instead
                return result
            } catch {
                setInfo("Error: Unable to parse the result")
                return nil
            }
            
        } catch {
            print(error)
        }
        
        return nil
    }
    
    public func get<T : RESTObject>(
        path: String,
        id: String?,
        completion: @escaping (Result<T?, Error>) -> Void)
    {
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        let task = urlSession.dataTask(with: url!, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(error!))
                return
            }
            guard let responseData = data else {
                self.setInfo("Request Response is Empty: \(String(describing: data))")
                completion(.failure(ConnectionError.requestError("Request Response is Empty: \(String(describing: data))")))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                completion(.failure(ConnectionError.requestError("Request produced an invalid HTTP response: \(String(describing: response))")))
                return
            }
            if (httpResponse.statusCode == 200) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                        completion(.failure(ConnectionError.requestError("See Info for more details")))
                        return
                    }

                    let result = T(with: json)
                    // if the status is a failure call the failure instead
                    return completion(.success(result))
                } catch {
                    self.setInfo("Error: Unable to parse the result")
                    completion(.failure(ConnectionError.requestError("See Info for more details")))
                    completion(.failure(ConnectionError.requestError("See Info for more details")))
                    return
                }
            } else {
                self.setInfo("Error: \(httpResponse.statusCode) : \(String(describing: data))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
            }
            return
        })
        task.resume()
    }
    
    /*
    public func get<T: RESTObject>(path: String, id: String?, failure: ConnectionOperationFailure? = nil) async throws -> T? {
        let full: String = "\(self.base)/\(path)/\(id ?? "")"
        let url = URL(string: full)!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                if (failure == nil) {
                    throw ConnectionError.requestError("Request produced an invalid HTTP response: \(String(describing: response))")
                } else {
                    failure!("Request produced an invalid HTTP response: \(String(describing: response))")
                    return nil
                }
            }
            if (httpResponse.statusCode == 200) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        throw ConnectionError.requestError("Request produced an invalid HTTP response: \(String(describing: response))")
                    }
                    
                    let result = T(with: json)
                    return result
                } catch {
                    throw ConnectionError.requestError("Error: Unable to parse the result")
                }
            } else {
                throw ConnectionError.requestError("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        } catch {
            return nil
        }
    }
    
    // TODO: Fix this so that it can make a choice between an APIList<> or an APISearchResult<>
    //       and parse and return the correct format..
    public func list<T : RESTObject>(path: String,
                                  completion: @escaping (RESTObjectList<T>) -> Void,
                                  failure: @escaping (String) -> Void,
                                  page: Int = 0, count: Int = 100) {
        let full: String = "\(self.base)/\(path)?page=\(page)&count=\(count)"
        let url = URL(string: full)!
        
        let task = urlSession.dataTask(with: url, completionHandler: { data, response, error in
            guard error == nil else {
                failure("Request Encountered an error: \(String(describing: error))")
                return
            }
            guard let responseData = data else {
                failure("Request Response is Empty: \(String(describing: data))")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                failure("Request produced an invalid HTTP response: \(String(describing: response))")
                return
            }
            if (httpResponse.statusCode == 200) {
                do {
                    // TODO: Alter this to accept EITHER a list, or a SearchResult
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options:[]) as? [String: Any] else {
                        failure("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }
                    // let json = String(decoding: responseData, as: UTF8.self)
                    let result = RESTObjectList<T>(with: json)
                    completion(result)
                } catch {
                    failure("Error: Unable to parse the result")
                }
            } else {
                failure("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        })
        task.resume()
    }
    
    public func query<T : RESTObject, U : RESTObject>(path: String,
                                                            query: U,
                                                            completion: @escaping (RESTObjectList<T>?) -> Void,
                                                            failure: @escaping (String) -> Void) {
        let full: String = "\(self.base)/\(path)"
        let url = URL(string: full)!
        
        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        // build the jsonData from the model
        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(query)
            request.httpBody = jsonData
        } catch {
            failure("Encoding Failed the Operation")
            return
        }

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                failure("Request Encountered an error: \(String(describing: error))")
                return
            }
            guard let responseData = data else {
                failure("Request Response is Empty: \(String(describing: data))")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                failure("Request produced an invalid HTTP response: \(String(describing: response))")
                return
            }
            if (httpResponse.statusCode == 200) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        failure("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }

                    let result = RESTObjectList<T>(with: json)
                    completion(result)
                } catch {
                    failure("Error: Unable to parse the result")
                }
            } else {
                failure("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        })
        task.resume()
    }
    
    public func model<T : RESTObject>(path: String, completion: @escaping (T?) -> Void, failure: @escaping (String) -> Void) {
        let full: String = "\(self.base)/\(path)/model"
        let url = URL(string: full)!
        
        let task = urlSession.dataTask(with: url, completionHandler: { data, response, error in
            guard error == nil else {
                failure("Request Encountered an error: \(String(describing: error))")
                return
            }
            guard let responseData = data else {
                failure("Request Response is Empty: \(String(describing: data))")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                failure("Request produced an invalid HTTP response: \(String(describing: response))")
                return
            }
            if (httpResponse.statusCode == 200) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        failure("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }

                    let result = T(with: json)
                    completion(result)
                } catch {
                    failure("Error: Unable to parse the result")
                }
            } else {
                failure("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        })
        task.resume()
    }
    
    public func post<T : RESTObject>(path: String,
                                    model: RESTObject,
                                    completion: @escaping (T?) -> Void,
                                    onFailure: @escaping (String) -> Void) {
        let full: String = "\(self.base)/\(path)"
        let url = URL(string: full)!
        
        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        // build the jsonData from the model
        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            // print(String(decoding: jsonData, as: UTF8.self))
            request.httpBody = jsonData
        } catch {
            onFailure("Encoding Failed the Operation")
            return
        }

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                onFailure("Request Encountered an error: \(String(describing: error))")
                return
            }
            guard let responseData = data else {
                onFailure("Request Response is Empty: \(String(describing: data))")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                onFailure("Request produced an invalid HTTP response: \(String(describing: response))")
                return
            }
            if (httpResponse.statusCode == 200) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        onFailure("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }

                    let result = T(with: json)
                    // if the status is a failure call the failure instead
                    completion(result)
                } catch {
                    onFailure("Error: Unable to parse the result")
                }
            } else {
                onFailure("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        })
        task.resume()
    }
    
    public func put<T : RESTObject>(path: String, id: String, model: RESTObject, completion: @escaping (T?) -> Void, failure: @escaping (String) -> Void) {
        let full: String = "\(self.base)/\(path)/\(id)"
        let url = URL(string: full)!
        
        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        // build the jsonData from the model
        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            request.httpBody = jsonData
        } catch {
            failure("Encoding Failed the Operation")
            return
        }

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                failure("Request Encountered an error: \(String(describing: error))")
                return
            }
            guard let responseData = data else {
                failure("Request Response is Empty: \(String(describing: data))")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                failure("Request produced an invalid HTTP response: \(String(describing: response))")
                return
            }
            if (httpResponse.statusCode == 200) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        failure("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }

                    let result = T(with: json)
                    // if the status is a failure call the failure instead
                    completion(result)
                } catch {
                    failure("Error: Unable to parse the result")
                }
            } else {
                failure("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        })
        task.resume()
    }
    
    public func delete(
        path: String,
        id: String,
        completion: @escaping (Bool) -> Void,
        failure: @escaping (String) -> Void
    ) {
        let full: String = "\(self.base)/\(path)/\(id)"
        let url = URL(string: full)!

        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                failure("Request Encountered an error: \(String(describing: error))")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                failure("Request produced an invalid HTTP response: \(String(describing: response))")
                return
            }
            if (httpResponse.statusCode == 200) {
                completion(true)
            } else {
                failure("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        })
        task.resume()
    }
    
    public func delete(
        path: String,
        id: String,
        completion: @escaping (Result?) -> Void,
        failure: @escaping (String) -> Void
    ) {
        let full: String = "\(self.base)/\(path)/\(id)"
        let url = URL(string: full)!

        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                failure("Request Encountered an error: \(String(describing: error))")
                return
            }
            guard let responseData = data else {
                failure("Request Response is Empty: \(String(describing: data))")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                failure("Request produced an invalid HTTP response: \(String(describing: response))")
                return
            }
            if (httpResponse.statusCode == 200) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        failure("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }

                    let result = Result(with: json)
                    // if the status is a failure call the failure instead
                    completion(result)
                } catch {
                    failure("Error: Unable to parse the result")
                }
            } else {
                failure("Error: \(httpResponse.statusCode) : \(String(describing: data))")
            }
        })
        task.resume()
    }*/
}
