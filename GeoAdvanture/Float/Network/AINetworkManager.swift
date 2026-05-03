//
//  AINetworkManager.swift
//  GeoAdvanture
//
//  Created by AI on 2026/5/2.
//

import Foundation
import Alamofire

/// 封装了最优网络请求方案的 Manager
/// 包含：网络预热 + 流式请求 + 拆包缓冲 + UI消费缓冲
public class AINetworkManager {
    
    public static let shared = AINetworkManager()
    
    private var typingTimer: Timer?
    private var messageBuffer = ""
    
    private init() {}
    
    /// 发起最优的流式对话请求
    /// - Parameters:
    ///   - parameters: 请求参数
    ///   - prewarm: 是否需要网络预热 (发送 OPTIONS 请求提前建联)
    ///   - onDelta: 每次吐出一个字的回调 (主线程，频率稳定)
    ///   - onComplete: 请求结束的回调 (主线程)
    public func requestOptimalStream(
        parameters: Parameters,
        prewarm: Bool = true,
        onDelta: @escaping (String) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        if prewarm {
            // 网络预热：提前进行 DNS 解析、TCP 三次握手、TLS 握手
            guard let prewarmUrl = URL(string: "https://nlp.aliyuncs.com") else {
                startOptimalRequest(parameters: parameters, onDelta: onDelta, onComplete: onComplete)
                return
            }
            var request = URLRequest(url: prewarmUrl)
            request.httpMethod = "OPTIONS"
            
            AF.request(request).response { [weak self] _ in
                self?.startOptimalRequest(parameters: parameters, onDelta: onDelta, onComplete: onComplete)
            }
        } else {
            startOptimalRequest(parameters: parameters, onDelta: onDelta, onComplete: onComplete)
        }
    }
    
    /// 核心请求逻辑：流式 + 拆包缓冲 + UI消费缓冲
    private func startOptimalRequest(
        parameters: Parameters,
        onDelta: @escaping (String) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        var tempBuffer = ""
        self.messageBuffer = ""
        self.typingTimer?.invalidate()
        
        var isNetworkFinished = false
        var finalError: Error? = nil
        
        // 启动打字机定时器，稳定控制 UI 刷新频率 (0.05s)
        self.typingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if !self.messageBuffer.isEmpty {
                // 每次只拿一个字渲染
                let char = String(self.messageBuffer.removeFirst())
                DispatchQueue.main.async {
                    onDelta(char)
                }
            } else if isNetworkFinished {
                // 网络接收结束且缓冲区完全吐干净后，才停止定时器并结束聊天
                timer.invalidate()
                self.typingTimer = nil
                DispatchQueue.main.async {
                    onComplete(finalError)
                }
            }
        }
        
        NetWorkManager.shared.requestSteam(parameters: parameters) { [weak self] rawString in
            guard let self = self else { return }
            
            tempBuffer.append(rawString)
            while let range = tempBuffer.range(of: "\n") {
                let line = String(tempBuffer[..<range.lowerBound])
                tempBuffer.removeSubrange(..<range.upperBound)
                
                guard let delta = self.processStreamLine(line) else { continue }
                if !delta.isEmpty {
                    // 解析出文字后，不直接操作 UI，而是放进缓冲池排队
                    self.messageBuffer += delta
                }
            }
        } completion: { [weak self] error in
            guard let self = self else { return }
            
            // 处理结尾可能没有换行符的残余缓冲数据
            if !tempBuffer.isEmpty {
                if let delta = self.processStreamLine(tempBuffer), !delta.isEmpty {
                    self.messageBuffer += delta
                }
                tempBuffer = ""
            }
            
            // 标记网络已结束，让定时器把池子里的字吐完即可收尾
            finalError = error
            isNetworkFinished = true
        }
    }
    
    /// 通用流式按行解析
    private func processStreamLine(_ line: String) -> String? {
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
        var jsonStr = line
        if jsonStr.hasPrefix("data:") { jsonStr = String(jsonStr.dropFirst(5)) }
        else if jsonStr.hasPrefix("data") { jsonStr = String(jsonStr.dropFirst(4)) }
        
        jsonStr = jsonStr.trimmingCharacters(in: .whitespaces)
        if jsonStr == "[DONE]" { return nil }
        
        guard let data = jsonStr.data(using: .utf8) else { return nil }
        
        do {
            let response = try JSONDecoder().decode(StreamResponse.self, from: data)
            return response.choices?.first?.message?.content
                ?? response.choices?.first?.delta?.content
                ?? response.choices?.first?.messages?.first?.content
                ?? response.data?.choices?.first?.messages?.first?.content
        } catch {
            return nil
        }
    }
    
    /// 停止当前正在进行的 UI 消费和网络请求
    public func stop() {
        typingTimer?.invalidate()
        typingTimer = nil
        messageBuffer = ""
    }
}
