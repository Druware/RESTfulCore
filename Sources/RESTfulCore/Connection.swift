//
//  Connection.swift
//  RESTfulCore
//
//  Created by Andrew Satori on 3/31/21.
//

// TODO: Complete documentation of Connection Methods

// FIXME: Alter all POST and PUT methods to properly handle the 200 return
//        200 (OK)
//        201 (Created)
//        202 (Accepted)
//        204 (No Content)
// TODO: Add associatd UnitTests and Server Test cases for each


import Foundation


public enum ConnectionError: Error {
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
    
    private func resetInfo() {
        if (info != nil) { info?.removeAll() }
    }
    
    /// request an array list from the server path, where the resulting array is
    /// an array / list of typed object based upon the RESTObject Base object.
    ///
    /// - parameter path:
    /// - parameter completion: a closure
    /// - returns: an array of RESTObjects as defined by the generic T
    public func list<T: RESTObject>(path: String,
                                    completion: @escaping (Result<[T]?, Error>) -> Void) {
        resetInfo()
        let urlString = buildUrlString(parts: path)
        let url = URL(string: urlString)
        
        let task = urlSession.dataTask(with: url!, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(error!))
                return
            }
            if (data == nil) {
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
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]] else {
                        self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }
                    var result : [T] = [T]()
                    // process the array
                    json.forEach { item in
                        let i = T(with: item)
                        result.append(i)
                    }
                    
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
    
    public func list<T: RESTObject>(path: String) async throws -> [T]? {
        resetInfo()

        let urlString = buildUrlString(parts: path)
        let url = URL(string: urlString)
        if (url == nil) {
            setInfo("Failed to construct a valid URL")
            return nil
        }
        
        do {
            let (data, response) = try await urlSession.data(from: url!)
            
            let code = (response as? HTTPURLResponse)?.statusCode
            if (code != 200) {
                setInfo("Server Responded with a non-200 Status Code \(code ?? 0)")
                return nil
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                    setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                    return nil
                }
                var result : [T] = [T]()
                // process the array
                json.forEach { item in
                    let i = T(with: item)
                    result.append(i)
                }
                
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
       
    public func list<T: RESTObject>(path: String, page: Int32, perPage: Int32,
                                    completion: @escaping (Result<RESTObjectList<T>?, Error>) -> Void) {
        resetInfo()
        let urlString = buildUrlString(parts: path)
        let url = URL(string: urlString)
        
        let task = urlSession.dataTask(with: url!, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(error!))
                return
            }
            if (data == nil) {
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
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
                        self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                        return
                    }
                    let result = RESTObjectList<T>(with: json)
                    completion(.success(result))
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
    
    public func get<T: RESTObject>(path: String, id: String?) async throws -> T? {
        resetInfo()
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        // TODO: add guard around potential nil url result
        
        do {
            let (data, response) = try await urlSession.data(from: url!)
            
            if ((response as? HTTPURLResponse)?.statusCode != 200) {
                setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
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
        resetInfo()
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
    
    // MARK: Query
    
    /*
    
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
    */
    
    // MARK: Post
    
    /// post() submits a post request to a server, json encoding the model
    ///   passed in in the parameter list.
    ///
    ///   #NOTES#
    ///   Pay attention to the result type requested, as the result may return
    ///   as eitehr a bool, or an object, and if a bool is requested and the
    ///   call results in a data stream, that data stream will be discarded.
    ///
    /// - Parameters:
    ///   - connection: A Connection instance, usually a shared instance
    ///   - model: A model that inherits from the RESTObject base type
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns:
    ///   - RESTObject, assuming a result code of 200, and in any other case a
    ///     nil value, with the connection.info array containing the details of
    ///     the action
    public func post<T : RESTObject, U : RESTObject>(
        path: String,
        model: T,
        completion: @escaping (Result<U?, Error>) -> Void) {

            resetInfo()
        let urlString = buildUrlString(parts: path)
        let url = URL(string: urlString)
        
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        // build the jsonData from the model
        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            request.httpBody = jsonData
        } catch {
            self.setInfo("Encoding Failed before the post operation")
            completion(.failure(ConnectionError.requestError("See Info for more details")))
            return
        }

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough // OK
            case 201: // created
                do {
                    if (data == nil) {
                        completion(.success(nil))
                        return
                    }
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
                        self.setInfo("Failed, Invalid HTTP response: \(String(describing: response))")
                        completion(.failure(ConnectionError.requestError("See Info for more details")))
                        return
                    }

                    let result = U(with: json)
                    completion(.success(result))
                } catch {
                    self.setInfo("Error: Unable to parse the result")
                    completion(.failure(ConnectionError.requestError("See Info for more details")))
                }
            case 202: fallthrough // accepted
            case 204: // no content
                self.setInfo("Succeeded, but no object was returned")
                completion(.success(nil))
                return
            default:
                self.setInfo("Failed, Status Code: \((response as? HTTPURLResponse)!.statusCode)")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
        })
        task.resume()
    }
    
    /// post() submits a post request to a server, json encoding the model
    ///   passed in in the parameter list.
    ///
    ///   #NOTES#
    ///   Pay attention to the result type requested, as the result may return
    ///   as eitehr a bool, or an object, and if a bool is requested and the
    ///   call results in a data stream, that data stream will be discarded.
    ///
    /// - Parameters:
    ///   - connection: A Connection instance, usually a shared instance
    ///   - model: A model that inherits from the RESTObject base type
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns:
    ///   - RESTObject, assuming a result code of 200, and in any other case a
    ///     nil value, with the connection.info array containing the details of
    ///     the action
    public func post<T : RESTObject>(
        path: String,
        model: T,
        completion: @escaping (Result<Bool, Error>) -> Void) {

            resetInfo()
        let urlString = buildUrlString(parts: path)
        let url = URL(string: urlString)
        
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        // build the jsonData from the model
        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            request.httpBody = jsonData
        } catch {
            self.setInfo("Encoding Failed before the post operation")
            completion(.failure(ConnectionError.requestError("See Info for more details")))
            return
        }

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough // OK
            case 201: fallthrough // created
            case 202: fallthrough // accepted
            case 204: // no content
                completion(.success(true))
                return
            default:
                self.setInfo("Failed, Status Code: \((response as? HTTPURLResponse)!.statusCode)")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
        })
        task.resume()
    }
    
    /// post() submits a post request to a server, json encoding the model
    ///   passed in in the parameter list.
    ///
    ///   #NOTES#
    ///   Pay attention to the result type requested, as the result may return
    ///   as eitehr a bool, or an object, and if a bool is requested and the
    ///   call results in a data stream, that data stream will be discarded.
    ///
    /// - Parameters:
    ///   - connection: A Connection instance, usually a shared instance
    ///   - model: A model that inherits from the RESTObject base type
    /// - Returns:
    ///   - RESTObject, assuming a result code of 200, and in any other case a
    ///     nil value, with the connection.info array containing the details of
    ///     the action
    public func post<T: RESTObject, U: RESTObject>(path: String, model: T) async throws -> U? {
        resetInfo()
        let urlString = buildUrlString(parts: path)
        let url = URL(string: urlString)
        
        // build thre request object
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            request.httpBody = jsonData
        } catch {
            self.setInfo("Failed, Unable to Encode the Model")
            return nil
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough // OK
            case 201: // created
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        setInfo("Failed, Invalid HTTP response: \(String(describing: response))")
                        return nil
                    }
                    return U(with: json)
                } catch {
                    setInfo("Succeeded, but unable to parse the result")
                    return nil
                }
            case 202: fallthrough // accepted
            case 204: // no content
                self.setInfo("Succeeded, but no object was returned")
                return nil
            default:
                self.setInfo("Failed, Status Code: \((response as? HTTPURLResponse)!.statusCode)")
                return nil
            }
        } catch {
            self.setInfo(error.localizedDescription)
        }
        
        return nil
    }
    
    /// post() submits a post request to a server, json encoding the model
    ///   passed in in the parameter list.
    ///
    ///   #NOTES#
    ///   Pay attention to the result type requested, as the result may return
    ///   as either a bool, or an object, and if a bool is requested and the
    ///   call results in a data stream, that data stream will be discarded.
    ///
    /// - Parameters:
    ///   - connection: A Connection instance, usually a shared instance
    ///   - model: A model that inherits from the RESTObject base type
    /// - Returns:
    ///   - bool, assuming a result code of 200-204
    public func post<T: RESTObject>(path: String, model: T) async throws -> Bool {
        resetInfo()
        let urlString = buildUrlString(parts: path)
        let url = URL(string: urlString)
        
        // build thre request object
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            request.httpBody = jsonData
        } catch {
            self.setInfo("Encoding Failed before the post operation")
            return false
        }
        
        do {
            let (_, response) = try await urlSession.data(for: request)

            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough
            case 201: fallthrough
            case 202: fallthrough
            case 204:
                return true
            default:
                self.setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
                return false
            }
        } catch {
            self.setInfo("Request encountered an unexpected error \(error.localizedDescription)")
        }
        return false
    }
    
    // MARK: Put
    
    public func put<T : RESTObject, U : RESTObject>(
        path: String,
        id: String?,
        model: T,
        completion: @escaping (Result<U?, Error>) -> Void) {

        resetInfo()
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        var request : URLRequest = URLRequest(url: url!)
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
            self.setInfo("Encoding Failed before the post operation")
            completion(.failure(ConnectionError.requestError("See Info for more details")))
            return
        }

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            guard let responseData = data else {
                self.setInfo("Request Response is Empty: \(String(describing: data))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            // 200 == success
            // 201 == success with body
            // 202 == success no body
            // 204 == success no body
            if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                        completion(.failure(ConnectionError.requestError("See Info for more details")))
                        return
                    }

                    let result = U(with: json)
                    // if the status is a failure call the failure instead
                    completion(.success(result))
                } catch {
                    self.setInfo("Error: Unable to parse the result")
                    completion(.failure(ConnectionError.requestError("See Info for more details")))
                }
            } else if (httpResponse.statusCode == 202 || httpResponse.statusCode == 204) {
                self.setInfo("Succeeded, but no object was returned")
                completion(.success(nil))
            } else {
                self.setInfo("Error: \(httpResponse.statusCode) : \(data == nil ? "" : String(decoding:data!, as: UTF8.self))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
            }
        })
        task.resume()
    }
    
    public func put<T : RESTObject>(
        path: String,
        id: String?,
        model: T,
        completion: @escaping (Result<Bool, Error>) -> Void) {

        resetInfo()
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        var request : URLRequest = URLRequest(url: url!)
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
            self.setInfo("Encoding Failed before the post operation")
            completion(.failure(ConnectionError.requestError("See Info for more details")))
            return
        }

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            // 200 == success
            // 201 == success with body
            // 204 == success no body
            if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 ||
                httpResponse.statusCode == 202 || httpResponse.statusCode == 204) {
                self.setInfo("Succeeded, but no object was returned")
                completion(.success(true))
            } else {
                self.setInfo("Error: \(httpResponse.statusCode) : \(data == nil ? "" : String(decoding:data!, as: UTF8.self))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
            }
        })
        task.resume()
    }
    
    public func put<T: RESTObject, U: RESTObject>(path: String, id: String?, model: T) async throws -> U? {
        resetInfo()
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        // build thre request object
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            request.httpBody = jsonData
        } catch {
            self.setInfo("Encoding Failed before the post operation")
            return nil
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough
            case 201:
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                        return nil
                    }

                    let result = U(with: json)
                    // if the status is a failure call the failure instead
                    return result
                } catch {
                    setInfo("Error: Unable to parse the result")
                    return nil
                }
            case 202: fallthrough
            case 204:
                self.setInfo("Succeeded, but no object was returned")
                return nil
            default:
                setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
                return nil
            }
        } catch {
            print(error)
            setInfo(error.localizedDescription)
        }
        
        return nil
    }
    public func put<T: RESTObject>(path: String, id: String?, model: T) async throws -> Bool {
        resetInfo()
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        // build thre request object
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let encoder : JSONEncoder = JSONEncoder()
        do
        {
            let jsonData = try encoder.encode(model)
            request.httpBody = jsonData
        } catch {
            self.setInfo("Encoding Failed before the post operation")
            return false
        }
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough
            case 201: fallthrough
            case 202: fallthrough
            case 204:
                return true
            default:
                setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
                return false
            }
        } catch {
            setInfo(error.localizedDescription)
        }
        
        return false
    }
    
    public func delete(path: String, id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        resetInfo()
        let urlString = buildUrlString(parts: path, id)
        let url = URL(string: urlString)

        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            guard let _ = response as? HTTPURLResponse else {
                self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough
            case 201: fallthrough
            case 204:
                completion(.success(true))
                return
            default:
                self.setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
        })
        task.resume()
    }
    
    public func delete<T: RESTObject>(path: String, id: String, completion: @escaping (Result<T?, Error>) -> Void) {
        resetInfo()
        let urlString = buildUrlString(parts: path, id)
        let url = URL(string: urlString)

        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                self.setInfo("Request Encountered an error: \(String(describing: error))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            guard let _ = response as? HTTPURLResponse else {
                self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough
            case 201:
                do {
                    if (data != nil) {
                        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
                            self.setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                            completion(.failure(ConnectionError.requestError("See Info for more details")))
                            return
                        }
                        completion(.success(T(with: json)))
                        return
                    } else {
                        completion(.success(T()))
                        return
                    }
                } catch {
                    self.setInfo("Error: Unable to parse the result")
                    completion(.failure(ConnectionError.requestError("See Info for more details")))
                    return
                }
            case 204:
                completion(.success(T()))
                return
            default:
                self.setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
                completion(.failure(ConnectionError.requestError("See Info for more details")))
                return
            }
        })
        task.resume()
    }
        
    public func delete(path: String, id: String?) async throws -> Bool {
        resetInfo()
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough
            case 201: fallthrough
            case 204:
                return true
            default:
                setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
                return false
            }
        } catch {
            print(error)
            setInfo(error.localizedDescription)
        }
        
        return false
    }
    
    public func delete<T: RESTObject>(path: String, id: String?) async throws -> T? {
        resetInfo()
        let urlString = buildUrlString(parts: path, id ?? "")
        let url = URL(string: urlString)
        
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough
            case 201:
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        setInfo("Request produced an invalid HTTP response: \(String(describing: response))")
                        return nil
                    }
                    
                    return T(with: json)
                } catch {
                    setInfo("Error: Unable to parse the result")
                    return nil
                }
            case 204:
                return T()
            default:
                setInfo("Server Responded with a non-200 Status Code \((response as? HTTPURLResponse)!.statusCode)")
                return nil
            }
        } catch {
            print(error)
            setInfo(error.localizedDescription)
        }
        
        return nil
    }
}
