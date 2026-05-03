//
//  NetWorkManager.swift
//  musicApp
//
//  Created by 陈爽 on 2025/6/19.
//
import UIKit
import Alamofire

typealias NetWorkRequestResult = Result<Data,Error>
typealias NetWorkCompletionHandler = (NetWorkRequestResult) -> Void

// 定义流式回调类型
typealias StreamReceiveHandler = (String) -> Void
typealias StreamCompletionHandler = (Error?) -> Void

class NetWorkManager{
    static let shared = NetWorkManager()
    
    private let streamSession: Session
        
    private init() {
        // 2. 配置 Session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
            
        // ⚠️ 关键：彻底禁用缓存
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
            
        // 初始化 session
        self.streamSession = Session(configuration: configuration)
    }
    
    // MARK: - POST
    @discardableResult
    func requestpost(parameters:Parameters?,
                     completion:@escaping NetWorkCompletionHandler) -> DataRequest{
        AF.request(url,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers,
                   requestModifier: {$0.timeoutInterval=30})
        .responseData(completionHandler: {response in
            switch response.result{
            case let .success(data):
                completion(.success(data))
            case let .failure(error):
                completion(self.handleError(error))
            }
        })
    }
    
    // MARK: - 流式请求
    @discardableResult
    func requestSteam(parameters:Parameters?,
                      onReceive: @escaping StreamReceiveHandler,
                      completion: @escaping StreamCompletionHandler) -> DataStreamRequest {
        
        guard let urlObj = URL(string: url) else {
            return AF.streamRequest(url)
        }
        var urlRequest = URLRequest(url: urlObj)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60
        
        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        }
        
        if let params = parameters {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
                urlRequest.httpBody = jsonData
            } catch {
                print("字典转JSON失败: \(error)")
                completion(error)
                return AF.streamRequest(url)
            }
        }
        
        return self.streamSession.streamRequest(urlRequest).responseStreamString { stream in
            switch stream.event{
            case.stream(let result):
                switch result{
                case .success(let data):
                    print("原始数据:\(data)")
                    onReceive(data)
                case.failure(let error):
                    print("Stream chunk error: \(error)")
                }
            case.complete(let completionStatus):
                if let error = completionStatus.error{
                    let result = self.handleError(error)
                    switch result{
                    case .failure(let handledError):
                        completion(handledError)
                    default:
                        completion(error)
                    }
                }else {
                    completion(nil)
                }
            }
        }
    }
    
    private func handleError(_ error:AFError) -> NetWorkRequestResult{
        //如果属于网络问题
        if let underlyingError = error.underlyingError{
            let nserror = underlyingError as NSError//转化为NSError 修改用户友好信息即可
            let code = nserror.code
            if code == NSURLErrorNotConnectedToInternet ||
                code == NSURLErrorTimedOut ||
                code == NSURLErrorInternationalRoamingOff ||
                code == NSURLErrorDataNotAllowed ||
                code == NSURLErrorCannotFindHost ||
                code == NSURLErrorCannotConnectToHost ||
                code == NSURLErrorNetworkConnectionLost
            {
                var userInfo = nserror.userInfo
                userInfo[NSLocalizedDescriptionKey] = "网络连接有问题😯"
                let currentError = NSError(domain: nserror.domain, code: code,userInfo: userInfo)
                return .failure(currentError)
            }
        }
        return .failure(error)
    }
}


