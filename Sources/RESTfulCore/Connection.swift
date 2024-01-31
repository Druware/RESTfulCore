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
// TODO: I am not happy with the volume of duplicated code, so will consolidate
//       some of this shortly


import Foundation

public enum ConnectionError: Error {
    case requestError(String)
}

public typealias ConnectionOperationFailure =  (String) -> Void

internal enum RequestMethod : String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
}

public enum ContentType : String {
    case json = "application/json"
    case multiPart = "multipart/form-data"
    // formURLEncoded
    // text
    // xml
}

/// The Connection object is the root of all server communication with the API,
/// and as such, it implements both the primitive functions that the RESTObject
/// based objects use, it is also the cornerstone object that an application
/// uses throughout the lifecycle of an application.
public class Connection {
    
    private var rootPath : String
    private var urlSession : URLSession
    
    public var info : [String]? = nil
    public var hostStatus : Bool {
        get {
            let urlString = rootPath
            Task {
                do {
                    _ = try await doRequestFor(url: urlString, method: .head)
                    return true
                }
                catch
                {
                    setInfo("Error during request")
                    return false
                }
            }
            return true
        }
    }

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
    
    // MARK: Utility
    // MARK: -
    
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
    public func buildUrlString(parts : String ..., queryString: String? = nil) -> String {
        var result : String = rootPath + (rootPath.hasSuffix("/") ? "" : "/")
        
        for s : String in parts {
            if (s != "") {
                result += (result.hasSuffix("/") ? "" : "/")
                result += (s.hasPrefix("/") ? String(s[(s.index(after: s.firstIndex(of: "/")!))...]) : s)
            }
        }
        result += (result.hasSuffix("/") ? "" : "/")
        
        if (queryString != nil) { result += "?\(queryString!)" }
        
        return result;
    }
    
    private func setInfo(_ value: String) -> Void {
        if (info == nil) { info = [String]() }
        info?.append(value)
    }
    
    private func resetInfo() {
        if (info != nil && info?.count ?? 0 > 0) {
            info?.removeAll()
            info = nil
        }
    }
    
    private func doRequestFor(url: String, 
                              method: RequestMethod = .get,
                              model: RESTObject? = nil,
                              contentType: ContentType = .json) async throws -> Data? {
        resetInfo()
        let _url = URL(string: url)
        
        if (_url == nil) {
            throw ConnectionError.requestError("No Empty URL's allowed")
        }
        
        var request : URLRequest = URLRequest(url: _url!)
        
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        
        // if this is a multiPart, instead of using the JSONEncoder, use
        // a MultipartEncoding ( if it is supported by the object, otherwise,
        // throw an error )
        if (model != nil) {
            if (contentType == .multiPart) {
                if let mp = model as? MultipartForm {
                    let mpr = mp.multipartRequest()
                    request.setValue(mpr?.header, forHTTPHeaderField: "Content-Type")
                    request.httpBody = mpr?.body
                }
            } else {
                // JSON
                let encoder : JSONEncoder = JSONEncoder()
                do
                {
                    let jsonData = try encoder.encode(model)
                    request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type") // the request is JSON
                    request.httpBody = jsonData
                } catch {
                    self.setInfo("Failed, Unable to Encode the Model")
                    throw error
                }
            }
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            switch ((response as? HTTPURLResponse)?.statusCode) {
            case 200: fallthrough // OK
            case 201: // created
                return data
            case 202: fallthrough // accepted
            case 204: // no content
                self.setInfo("Succeeded, but no content was returned")
                return nil
            default:
                self.setInfo("Failed, Status Code: \((response as? HTTPURLResponse)!.statusCode)")
                return nil
            }
        } catch {
            self.setInfo(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: List
    // MARK: -
    
    // Async
    
    /// request an array list from the server path, where the resulting array is
    /// an array / list of typed object based upon the RESTObject Base object.
    /// async version
    /// - Parameter path:
    /// - Returns: an array of RESTObjects as defined by the generic T
    public func list<T: RESTObject>(path: String,
                                    page: Int32 = 0,
                                    perPage: Int32 = 50) async throws -> [T]? {
        // use the generic request
        var data : Data? = nil
        let urlString = buildUrlString(parts: path, queryString: "page=\(page)&count=\(perPage)")
        do {
            data = try await doRequestFor(url: urlString, method: .get)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        var result : [T] = [T]()
        // process the array
        json.forEach { item in
            let i = T(with: item)
            result.append(i)
        }
        
        return result
    }
    
    /// request an array list from the server path, where the resulting array is
    /// an array / list of typed object based upon the RESTObject Base object.
    /// async version
    /// - Parameter path:
    /// - Returns: an array of RESTObjects as defined by the generic T
    public func list<T: Any>(path: String) async throws -> [T]? {
        
        // use the generic request
        var data : Data? = nil
        let urlString = buildUrlString(parts: path)
        do {
            data = try await doRequestFor(url: urlString, method: .get)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        var result : [T] = [T]()
        // process the array
        json.forEach { item in
            // let i = T(with: item)
            result.append(item as! T)
        }
        
        return result
    }
    

    /// request a list from the server path, where the resulting array is
    /// a RESTfulObjectListof typed object based upon the RESTObject Base object.
    /// async version
    /// - Parameter path:
    /// - Returns: a RESTfulObjectList of RESTObjects as defined by the generic T
    public func list<T: RESTObject>(path: String, page: Int32 = 0, perPage: Int32 = 50) async throws -> RESTObjectList<T>? {
        // use the generic request
        var data : Data? = nil
        let urlString = buildUrlString(parts: path, queryString: "page=\(page)&count=\(perPage)")
        do {
            data = try await doRequestFor(url: urlString, method: .get)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        let result = RESTObjectList<T>(with: json)
        return result
    }
    
    // Sync w/ closures
    
    /// request an array list from the server path, where the resulting array is
    /// an array / list of typed object based upon the RESTObject Base object.
    ///
    /// - parameter path:
    /// - parameter completion: a closure
    /// - returns: an array of RESTObjects as defined by the generic T
    public func list<T: RESTObject>(path: String,
                                    page: Int32 = 0,
                                    perPage: Int32 = 50,
                                    completion: @escaping (Result<[T]?, Error>) -> Void) {
        _ = Task { () -> Result<[T]?, Error> in
            do {
                let result : [T]? = try await self.list(path: path, page: page, perPage: perPage)
                // call the completion closure
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    /// request an array list from the server path, where the resulting array is
    /// an array / list of typed object based upon the RESTObject Base object.
    ///
    /// - parameter path:
    /// - parameter completion: a closure
    /// - returns: an array of any as defined by the generic T
    public func list<T: Any>(path: String,
                                    page: Int32 = 0,
                                    perPage: Int32 = 50,
                                    completion: @escaping (Result<[T]?, Error>) -> Void) {
        _ = Task { () -> Result<[T]?, Error> in
            do {
                let result : [T]? = try await self.list(path: path)
                // call the completion closure
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    /// request an object list from the server path, where the resulting array
    /// is an array / list of typed object based upon the RESTObject Base that
    /// is wrapped in a RESTObjectList that includes paging information as well
    /// as total record counts.
    ///
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - page: 0 based page within the result set
    ///   - perPage: number of records in the page
    ///   - completion: the closure that will return the results of the request
    ///         in the form a a Result that can include the successful result,
    ///         or the error.
    public func list<T: RESTObject>(path: String, page: Int32, perPage: Int32,
                                    completion: @escaping (Result<RESTObjectList<T>?, Error>) -> Void) {
        _ = Task { () -> Result<RESTObjectList<T>?, Error> in
            do {
                let result : RESTObjectList<T>? = try await self.list(path: path, page: page, perPage: perPage)
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    // MARK: Get
    // MARK: -
    
    /// request an object from the server endpoint, where the resulting object
    /// based upon the RESTObject base class
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - query: optional query string keys and values preassembled without
    ///         the leading ?
    /// - Returns: the typed object based upon RESTObject
    public func get<T: RESTObject>(path: String, id: String? = nil, query: String? = nil) async throws -> T? {
        var data : Data? = nil
        let urlString = buildUrlString(parts: path, id ?? "", queryString: query)
        do {
            data = try await doRequestFor(url: urlString, method: .get)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        let result = T(with: json)
        return result
    }
    
    /// request an object from the server endpoint, where the resulting object
    /// based upon the RESTObject base class, wrapping the async call in a sync
    /// wrapper
    ///     /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - query: optional query string keys and values preassembled without
    ///         the leading ?
    ///   - completion: a closure that enables the return of the data from the
    ///         sync method.
    public func get<T : RESTObject>(
        path: String,
        id: String? = nil,
        query: String? = nil,
        completion: @escaping (Result<T?, Error>) -> Void)
    {
        _ = Task { () -> Result<T?, Error> in
            do {
                let result : T? = try await self.get(path: path, id: id, query: query)
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    // MARK: Post
    // MARK: -
    
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
    public func post<T: RESTObject, U: RESTObject>(path: String, model: T, type: ContentType = .json) async throws -> U? {
        var data : Data? = nil
        let urlString = buildUrlString(parts: path)
        do {
            data = try await doRequestFor(url: urlString, method: .post, model: model, contentType: type)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        let result = U(with: json)
        return result
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
    public func post<T: RESTObject>(path: String, model: T, type: ContentType = .json) async throws -> Bool {
        let urlString = buildUrlString(parts: path)
        do {
            let _ : Data? = try await doRequestFor(url: urlString, method: .post, model: model, contentType: type)
            return true
        }
        catch
        {
            setInfo("Error during request")
            return false
        }
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
    public func post<T : RESTObject, U : RESTObject>(
        path: String,
        model: T,
        type: ContentType = .json,
        completion: @escaping (Result<U?, Error>) -> Void) {
        _ = Task { () -> Result<U?, Error> in
            do {
                let result : U? = try await self.post(path: path, model: model, type: type)
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
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
        type: ContentType = .json,
        completion: @escaping (Result<Bool, Error>) -> Void) {
        _ = Task { () -> Result<Bool, Error> in
            do {
                let _ : Bool = try await self.post(path: path, model: model, type: type)
                completion(Result.success(true))
                return Result.success(true)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    // MARK: Put
    // MARK: -
        
    /// performs a put ( update ) of the model to the endpint appended with the
    /// id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - model: A model that inherits from the RESTObject base type
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns: a RESTObject derived object as returned from the server.
    public func put<T: RESTObject, U: RESTObject>(path: String, id: String?, model: T, type: ContentType = .json) async throws -> U? {
        var data : Data? = nil
        let urlString = buildUrlString(parts: path, id ?? "")
        do {
            data = try await doRequestFor(url: urlString, method: .put, model: model, contentType: type)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        let result = U(with: json)
        return result
    }
    
    /// performs a put ( update ) of the model to the endpint appended with the
    /// id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - model: A model that inherits from the RESTObject base type
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns: a bool as success or failure
    public func put<T: RESTObject>(path: String, id: String?, model: T, type: ContentType = .json) async throws -> Bool {
        let urlString = buildUrlString(parts: path, id ?? "")
        do {
            _ = try await doRequestFor(url: urlString, method: .put, model: model, contentType: type)
            return true
        }
        catch
        {
            setInfo("Error during request")
            return false
        }
    }
    
    /// performs a put ( update ) of the model to the endpint appended with the
    /// id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - model: A model that inherits from the RESTObject base type
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns: a RESTfulObject as defined by the server endpoint
    public func put<T : RESTObject, U : RESTObject>(
        path: String,
        id: String?,
        model: T,
        type: ContentType = .json,
        completion: @escaping (Result<U?, Error>) -> Void) {
        _ = Task { () -> Result<U?, Error> in
            do {
                let result : U? = try await self.put(path: path, id: id, model: model, type: type)
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    /// performs a put ( update ) of the model to the endpint appended with the
    /// id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - model: A model that inherits from the RESTObject base type
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns: a bool as success or failure
    public func put<T : RESTObject>(
        path: String,
        id: String?,
        model: T,
        type: ContentType = .json,
        completion: @escaping (Result<Bool, Error>) -> Void) {
        _ = Task { () -> Result<Bool, Error> in
            do {
                let _ : Bool = try await self.put(path: path, id: id, model: model, type: type)
                completion(Result.success(true))
                return Result.success(true)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }

    // MARK: Delete
    // MARK: -
    
    /// performs a delete on the endpint appended with the id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns: a bool as success or failure
    public func delete(path: String, id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        _ = Task { () -> Result<Bool, Error> in
            do {
                let _ : Bool = try await self.delete(path: path, id: id)
                completion(Result.success(true))
                return Result.success(true)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    /// performs a delete on the endpint appended with the id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    ///   - completion: A closure to be called upon completion with either a
    ///     success or failure as the payload. Any additional information is
    ///     contained in the connection.info property
    /// - Returns: a RESTfulObject as success and or the failure condition in
    ///     the Result
    public func delete<T: RESTObject>(path: String, id: String, completion: @escaping (Result<T?, Error>) -> Void) {
        _ = Task { () -> Result<T?, Error> in
            do {
                let result : T? = try await self.delete(path: path, id: id)
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
        
    /// performs a delete on the endpint appended with the id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    /// - Returns: a bool as success or failure
    public func delete(path: String, id: String?) async throws -> Bool {
        let urlString = buildUrlString(parts: path, id ?? "")
        do {
            _ = try await doRequestFor(url: urlString, method: .delete)
            return true
        }
        catch
        {
            setInfo("Error during request")
            return false
        }
    }
    
    /// performs a delete on the endpint appended with the id to the path.
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - id: optional id for a specific record
    /// - Returns: a bool as success or failure
    public func delete<T: RESTObject>(path: String, id: String?) async throws -> T? {
        var data : Data? = nil
        let urlString = buildUrlString(parts: path, id ?? "")
        do {
            data = try await doRequestFor(url: urlString, method: .delete)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        let result = T(with: json)
        return result
    }
    
    // MARK: Query
    // MARK: -
    
    /// request an array list from the server path using a posted model to
    /// establish the filter patterns, where the resulting array is
    /// an array / list of typed object based upon the RESTObject Base object.
    /// async version
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - model: required search criteria
    ///   - page: the page within the result set
    ///   - perPage: the number of items perPage in the result set.
    /// - Returns: an array of RESTObjects as defined by the generic T
    public func query<T: RESTObject>(path: String,
                                    model: T,
                                    page: Int32 = 0,
                                    perPage: Int32 = 50) async throws -> [T]? {
        // use the generic request
        var data : Data? = nil
        let urlString = buildUrlString(parts: path, queryString: "page=\(page)&count=\(perPage)")
        do {
            data = try await doRequestFor(url: urlString, method: .post, model: model)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        var result : [T] = [T]()
        // process the array
        json.forEach { item in
            let i = T(with: item)
            result.append(i)
        }
        
        return result
    }
    
    /// request a list from the server path, where the resulting array is
    /// a RESTfulObjectListof typed object based upon the RESTObject Base object.
    /// async version
    /// - Parameter path:
    /// - Returns: a RESTfulObjectList of RESTObjects as defined by the generic T
    public func query<T: RESTObject>(path: String,
                                     model: T,
                                     page: Int32 = 0,
                                     perPage: Int32 = 50) async throws -> RESTObjectList<T>? {
        // use the generic request
        var data : Data? = nil
        let urlString = buildUrlString(parts: path, queryString: "page=\(page)&count=\(perPage)")
        do {
            data = try await doRequestFor(url: urlString, method: .post, model: model)
        }
        catch
        {
            setInfo("Error during request")
            return nil
        }
        
        // if we get here, and have data, parse it, however a no data response
        // is valid, so in that case return nil without an error ( there should
        if (data == nil) { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
            setInfo("Response cannot be parsed into the expected object")
            return nil
        }
        let result = RESTObjectList<T>(with: json)
        return result
    }
    
    // Sync w/ closures
    
    /// request an array list from the server path, where the resulting array is
    /// an array / list of typed object based upon the RESTObject Base object.
    ///
    /// - parameter path:
    /// - parameter completion: a closure
    /// - returns: an array of RESTObjects as defined by the generic T
    public func query<T: RESTObject>(path: String,
                                    model: T,
                                    page: Int32 = 0,
                                    perPage: Int32 = 50,
                                    completion: @escaping (Result<[T]?, Error>) -> Void) {
        _ = Task { () -> Result<[T]?, Error> in
            do {
                let result : [T]? = try await self.query(path: path, model: model, page: page, perPage: perPage)
                // call the completion closure
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }
    
    /// request an object list from the server path, where the resulting array
    /// is an array / list of typed object based upon the RESTObject Base that
    /// is wrapped in a RESTObjectList that includes paging information as well
    /// as total record counts.
    ///
    /// - Parameters:
    ///   - path: path to the endpoint
    ///   - page: 0 based page within the result set
    ///   - perPage: number of records in the page
    ///   - completion: the closure that will return the results of the request
    ///         in the form a a Result that can include the successful result,
    ///         or the error.
    public func query<T: RESTObject>(path: String,
                                     model: T,
                                     page: Int32,
                                     perPage: Int32,
                                     completion: @escaping (Result<RESTObjectList<T>?, Error>) -> Void) {
        _ = Task { () -> Result<RESTObjectList<T>?, Error> in
            do {
                let result : RESTObjectList<T>? = try await self.query(path: path, model: model, page: page, perPage: perPage)
                completion(Result.success(result))
                return Result.success(result)
            }
            catch{
                completion(Result.failure(error))
                return Result.failure(error)
            }
        }
    }

}
    
