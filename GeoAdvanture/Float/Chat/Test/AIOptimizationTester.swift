//
//  AIOptimizationTester.swift
//  GeoAdvanture
//
//  Created for A/B Testing Network Optimizations.
//

import Foundation
import Alamofire

/// 测试模式
enum AITestMode: String, CaseIterable {
    case baseline = "1. 传统整包请求 (无流式)"
    case streamingNaive = "2. 纯流式 (无拆包缓冲，直解JSON)"
    case streamingWithParseBuffer = "3. 流式 + 拆包缓冲 (无UI缓冲)"
    case optimal = "4. 最终方案 (流式 + 拆包缓冲 + UI消费缓冲)"
    case optimalWithPrewarm = "5. 终极方案 (网络预热 + 流式 + 拆包 + UI缓冲)"
}

/// 与 `runTest` / `runAllTests` 默认入参相同；聊天首屏可自动用此句发起一次 `requestForUI` / `buildParameters`。
enum AITestDefaultPrompts {
    static let sample = "请详细介绍一下地球的地壳结构，字数不少于200字。"
}

/// 测试结果统计
struct AITestMetrics {
    var mode: AITestMode
    var firstTokenLatency: Double = 0 // 首字延迟 (ms)
    var totalLatency: Double = 0      // 总耗时 (ms)
    var parseErrorCount: Int = 0      // JSON解析失败次数 (证明粘包/断包)
    var uiRefreshCount: Int = 0       // UI刷新次数 (证明UI缓冲有效)
    var receivedTextLength: Int = 0   // 最终接收到的文本长度
}

class AIOptimizationTester {
    static let shared = AIOptimizationTester()
    
    private var currentMetrics: AITestMetrics!
    private var startTime: DispatchTime!
    private var isFirstTokenReceived = false
    
    // UI 缓冲专用
    private var messageBuffer = ""
    private var typingTimer: Timer?
    private var onUIDelta: ((String) -> Void)?
    private var onUIComplete: ((Error?) -> Void)?

    deinit {
        typingTimer?.invalidate()
    }

    /// UI 入口：按指定方案发起一次请求，把增量文本回传给界面层。
    func requestForUI(
        mode: AITestMode,
        prompt: String,
        onDelta: @escaping (String) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        // 清理上一次 UI 消费状态
        typingTimer?.invalidate()
        typingTimer = nil
        messageBuffer = ""
        onUIDelta = onDelta
        onUIComplete = onComplete
        
        // 统一初始化 Metrics，以便 UI 请求也能打印日志
        currentMetrics = AITestMetrics(mode: mode)
        startTime = DispatchTime.now()
        isFirstTokenReceived = false

        let isStream = mode != .baseline
        let para = buildParameters(prompt: prompt, stream: isStream)
        
        switch mode {
        case .baseline:
            requestBaselineForUI(parameters: para)
        case .streamingNaive:
            requestStreamingNaiveForUI(parameters: para)
        case .streamingWithParseBuffer:
            requestStreamingWithBufferForUI(parameters: para)
        case .optimal:
            requestOptimalForUI(parameters: para, prewarm: false)
        case .optimalWithPrewarm:
            requestOptimalForUI(parameters: para, prewarm: true)
        }
    }
    
    /// 运行所有测试（串行执行，避免网络并发影响准确性）
    func runAllTests(prompt: String = AITestDefaultPrompts.sample) {
        print("\n🚀🚀🚀 开始执行 AI 网络优化 A/B 测试 🚀🚀🚀")
        print("测试 Prompt: \(prompt)\n")
        
        runTest(mode: .baseline, prompt: prompt) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.runTest(mode: .streamingNaive, prompt: prompt) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.runTest(mode: .streamingWithParseBuffer, prompt: prompt) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                self.runTest(mode: .optimal, prompt: prompt) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        self.runTest(mode: .optimalWithPrewarm, prompt: prompt) {
                                            print("\n✅✅✅ 所有测试执行完毕 ✅✅✅\n")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 运行单组测试
    func runTest(mode: AITestMode, prompt: String, completion: @escaping () -> Void) {
        print("==================================================")
        print("▶️ 正在测试: \(mode.rawValue)")
        
        currentMetrics = AITestMetrics(mode: mode)
        startTime = DispatchTime.now()
        isFirstTokenReceived = false
        
        let isStream = mode != .baseline
        let para = buildParameters(prompt: prompt, stream: isStream)
        
        switch mode {
        case .baseline:
            testBaseline(parameters: para, completion: completion)
        case .streamingNaive:
            testStreamingNaive(parameters: para, completion: completion)
        case .streamingWithParseBuffer:
            testStreamingWithParseBuffer(parameters: para, completion: completion)
        case .optimal:
            testOptimal(parameters: para, completion: completion)
        case .optimalWithPrewarm:
            testOptimalWithPrewarm(parameters: para, completion: completion)
        }
    }
    
    // MARK: - 1. 传统整包请求 (Baseline)
    private func testBaseline(parameters: Parameters, completion: @escaping () -> Void) {
        NetWorkManager.shared.requestpost(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            self.recordTotalTime()
            self.currentMetrics.firstTokenLatency = self.currentMetrics.totalLatency
            
            switch result {
            case .success(let data):
                self.currentMetrics.uiRefreshCount = 1
                if let text = self.decodeTextFromData(data) {
                    self.currentMetrics.receivedTextLength = text.count
                }
            case .failure:
                self.currentMetrics.parseErrorCount += 1
            }
            self.printMetricsAndFinish(completion: completion)
        }
    }
    
    // MARK: - 2. 纯流式 (无拆包缓冲，直解JSON)
    private func testStreamingNaive(parameters: Parameters, completion: @escaping () -> Void) {
        NetWorkManager.shared.requestSteam(parameters: parameters) { [weak self] rawString in
            guard let self = self else { return }
            
            // ⚠️ 错误示范：不使用 tempBuffer 拆包，直接尝试解析网络层回调的 rawString
            let lines = rawString.components(separatedBy: "\n")
            for line in lines {
                guard let delta = self.processStreamLine(line) else { continue }
                if !delta.isEmpty {
                    self.recordFirstToken()
                    self.currentMetrics.uiRefreshCount += 1 // 每次成功解析都刷新UI
                    self.currentMetrics.receivedTextLength += delta.count
                }
            }
        } completion: { [weak self] _ in
            self?.recordTotalTime()
            self?.printMetricsAndFinish(completion: completion)
        }
    }
    
    // MARK: - 3. 流式 + 拆包缓冲 (无UI缓冲)
    private func testStreamingWithParseBuffer(parameters: Parameters, completion: @escaping () -> Void) {
        var tempBuffer = ""
        NetWorkManager.shared.requestSteam(parameters: parameters) { [weak self] rawString in
            guard let self = self else { return }
            
            // ✅ 正确示范：使用 tempBuffer 解决粘包断包
            tempBuffer.append(rawString)
            while let range = tempBuffer.range(of: "\n") {
                let line = String(tempBuffer[..<range.lowerBound])
                tempBuffer.removeSubrange(..<range.upperBound)
                
                guard let delta = self.processStreamLine(line) else { continue }
                if !delta.isEmpty {
                    self.recordFirstToken()
                    self.currentMetrics.uiRefreshCount += 1 // ⚠️ 每次收到字就刷新UI，会导致刷新频率极高
                    self.currentMetrics.receivedTextLength += delta.count
                }
            }
        } completion: { [weak self] _ in
            self?.recordTotalTime()
            self?.printMetricsAndFinish(completion: completion)
        }
    }
    
    // MARK: - 4. 最终方案 (流式 + 拆包缓冲 + UI缓冲)
    private func testOptimal(parameters: Parameters, completion: @escaping () -> Void) {
        runOptimalLogic(parameters: parameters, completion: completion)
    }
    
    // MARK: - 5. 终极方案 (网络预热 + 流式 + 拆包缓冲 + UI缓冲)
    private func testOptimalWithPrewarm(parameters: Parameters, completion: @escaping () -> Void) {
        print("   [预热中...] 正在向大模型网关发送 OPTIONS 请求，提前建立 TCP/TLS 连接...")
        
        guard let prewarmUrl = URL(string: "https://nlp.aliyuncs.com") else {
            completion()
            return
        }
        var request = URLRequest(url: prewarmUrl)
        request.httpMethod = "OPTIONS"
        
        AF.request(request).response { [weak self] _ in
            guard let self = self else { return }
            print("   [预热完成] 底层高速公路已修好！现在模拟用户点击发送...")
            self.startTime = DispatchTime.now() // 重置计时
            self.runOptimalLogic(parameters: parameters, completion: completion)
        }
    }
    
    // MARK: - 核心逻辑 (供 4 和 5 复用)
    private func runOptimalLogic(parameters: Parameters, completion: @escaping () -> Void) {
        var tempBuffer = ""
        self.messageBuffer = ""
        
        // 开启 UI 消费定时器 (0.05s)
        self.typingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.messageBuffer.isEmpty {
                _ = self.messageBuffer.removeFirst()
                self.currentMetrics.uiRefreshCount += 1 // ✅ 只有定时器触发且有字时才刷新UI
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
                    self.recordFirstToken()
                    self.messageBuffer += delta // 放入 UI 缓冲池
                    self.currentMetrics.receivedTextLength += delta.count
                }
            }
        } completion: { [weak self] _ in
            self?.recordTotalTime()
            self?.typingTimer?.invalidate()
            self?.typingTimer = nil
            self?.printMetricsAndFinish(completion: completion)
        }
    }
    
    // MARK: - Helpers
    private func recordFirstToken() {
        if !isFirstTokenReceived {
            let endTime = DispatchTime.now()
            currentMetrics.firstTokenLatency = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            isFirstTokenReceived = true
        }
    }
    
    private func recordTotalTime() {
        let endTime = DispatchTime.now()
        currentMetrics.totalLatency = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
    }
    
    private func printMetricsAndFinish(completion: @escaping () -> Void) {
        let m = currentMetrics!
        print("📊 测试结果 (\(m.mode.rawValue)):")
        print("   - 首字延迟: \(String(format: "%.2f", m.firstTokenLatency)) ms")
        print("   - 总耗时:   \(String(format: "%.2f", m.totalLatency)) ms")
        print("   - 解析错误: \(m.parseErrorCount) 次 (代表断包/粘包发生)")
        print("   - UI刷新:   \(m.uiRefreshCount) 次")
        print("   - 接收字数: \(m.receivedTextLength) 字")
        print("==================================================\n")
        completion()
    }
    
    private func buildParameters(prompt: String, stream: Bool = true) -> Parameters {
        return [
            "model": "qwen-plus-character",
            "stream": stream,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]
    }

    /// 通用流式按行解析 (含指标错误统计)
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
            // qwen-plus-character 的 delta 结构直接返回增量文本，并非全量文本
            return response.choices?.first?.message?.content
                ?? response.choices?.first?.delta?.content
                ?? response.choices?.first?.messages?.first?.content
                ?? response.data?.choices?.first?.messages?.first?.content
        } catch {
            self.currentMetrics.parseErrorCount += 1
            return nil
        }
    }

    private func decodeTextFromData(_ data: Data) -> String? {
        guard let response = try? JSONDecoder().decode(StreamResponse.self, from: data) else { return nil }
        return response.choices?.first?.message?.content
            ?? response.choices?.first?.delta?.content
            ?? response.choices?.first?.messages?.first?.content
            ?? response.data?.choices?.first?.messages?.first?.content
    }

    // MARK: - UI Oriented Requests
    
    /// 方案1：传统整包请求 (无流式)
    /// 解释：发起普通的 HTTP POST 请求，等待大模型把所有话都生成完毕后，一次性返回整个大 JSON。
    /// 缺点：首字延迟极高（等同于总耗时），用户在等待期间只能看转圈动画，体验最差。
    /// 优点：UI 只需要刷新 1 次，没有任何粘包、断包解析的烦恼。
    private func requestBaselineForUI(parameters: Parameters) {
        NetWorkManager.shared.requestpost(parameters: parameters) { [weak self] result in
            guard let self else { return }
            self.recordTotalTime()
            self.currentMetrics.firstTokenLatency = self.currentMetrics.totalLatency
            
            switch result {
            case .success(let data):
                self.currentMetrics.uiRefreshCount = 1
                let text = self.decodeTextFromData(data) ?? ""
                self.currentMetrics.receivedTextLength = text.count
                // 拿到完整的文本后，一次性扔给 UI 显示
                DispatchQueue.main.async {
                    self.onUIDelta?(text)
                    self.printMetricsAndFinish {
                        self.onUIComplete?(nil)
                    }
                }
            case .failure(let error):
                self.currentMetrics.parseErrorCount += 1
                DispatchQueue.main.async {
                    self.printMetricsAndFinish {
                        self.onUIComplete?(error)
                    }
                }
            }
        }
    }

    /// 方案2：纯流式 (无拆包缓冲，直解JSON)
    /// 解释：使用流式请求 (SSE)，网络层一旦收到数据就立刻回调 rawString。
    /// 缺点：由于底层网络传输 TCP/IP 的特性，数据块可能会被任意截断（断包）或者多个包连在一起（粘包）。
    ///       这里直接按 "\n" 分割并尝试解析 JSON，如果刚好从 JSON 中间断开，解析必定失败，丢失文字。
    /// 优点：比方案1的首字延迟大幅降低。
    private func requestStreamingNaiveForUI(parameters: Parameters) {
        NetWorkManager.shared.requestSteam(parameters: parameters) { [weak self] rawString in
            guard let self else { return }
            // ⚠️ 错误示范：没有对未完整接收的报文做缓存处理，直接按行切割
            let lines = rawString.components(separatedBy: "\n")
            for line in lines {
                guard let delta = self.processStreamLine(line) else { continue }
                if !delta.isEmpty {
                    self.recordFirstToken()
                    self.currentMetrics.receivedTextLength += delta.count
                    self.currentMetrics.uiRefreshCount += 1
                    // 每解析成功一次增量，就立刻让主线程刷新 UI (频率过高会导致主线程卡顿)
                    DispatchQueue.main.async { self.onUIDelta?(delta) }
                }
            }
        } completion: { [weak self] error in
            self?.recordTotalTime()
            DispatchQueue.main.async {
                self?.printMetricsAndFinish {
                    self?.onUIComplete?(error)
                }
            }
        }
    }

    /// 方案3：流式 + 拆包缓冲 (无UI缓冲)
    /// 解释：在方案2的基础上，增加了一个 `tempBuffer` 来解决网络层的“粘包断包”问题。
    ///       只有读到完整的换行符 "\n" 时，才把完整的一行截取出来去解析。
    /// 缺点：虽然解决了数据丢失问题，但是大模型吐字速度极快（尤其是网络好的时候），
    ///       会导致 UI 刷新频率过高（一秒可能刷新几十次），造成明显的掉帧卡顿。
    private func requestStreamingWithBufferForUI(parameters: Parameters) {
        var tempBuffer = ""
        NetWorkManager.shared.requestSteam(parameters: parameters) { [weak self] rawString in
            guard let self else { return }
            // ✅ 拆包缓冲池：收到网络数据先存起来
            tempBuffer.append(rawString)
            // 只有发现有换行符时，才认为是一条完整的 SSE 消息
            while let range = tempBuffer.range(of: "\n") {
                let line = String(tempBuffer[..<range.lowerBound])
                tempBuffer.removeSubrange(..<range.upperBound)
                
                guard let delta = self.processStreamLine(line) else { continue }
                if !delta.isEmpty {
                    self.recordFirstToken()
                    self.currentMetrics.receivedTextLength += delta.count
                    self.currentMetrics.uiRefreshCount += 1
                    // ⚠️ 依然是拿到多少就立马刷新多少，主线程压力极大
                    DispatchQueue.main.async { self.onUIDelta?(delta) }
                }
            }
        } completion: { [weak self] error in
            self?.recordTotalTime()
            
            // ⚠️ 处理结尾可能没有换行符的残余缓冲数据，防止最后一部分字被丢弃
            if !tempBuffer.isEmpty {
                if let delta = self?.processStreamLine(tempBuffer), !delta.isEmpty {
                    self?.currentMetrics.receivedTextLength += delta.count
                    self?.currentMetrics.uiRefreshCount += 1
                    DispatchQueue.main.async { self?.onUIDelta?(delta) }
                }
                tempBuffer = ""
            }
            
            DispatchQueue.main.async {
                self?.printMetricsAndFinish {
                    self?.onUIComplete?(error)
                }
            }
        }
    }

    /// 方案4 & 5：终极方案 (流式 + 拆包缓冲 + UI消费缓冲 + [可选的预热])
    /// 解释：集成了前3个方案的优点并解决了所有痛点。
    ///       引入 `messageBuffer` (UI缓冲池) 和 `typingTimer` (定时器)。
    ///       网络收到的文字先安全拆包，然后放进 `messageBuffer` 里。
    ///       定时器固定每 0.05 秒从池子里拿一个字给 UI。
    /// 优点：1. 首字秒出。2. 数据不丢。3. UI 刷新频率稳定 (20帧/秒)，绝对不卡。4. 实现平滑的“打字机”动画效果。
    private func requestOptimalForUI(parameters: Parameters, prewarm: Bool) {
        let start: () -> Void = { [weak self] in
            guard let self else { return }
            var tempBuffer = ""
            self.messageBuffer = ""
            self.typingTimer?.invalidate()
            
            var isNetworkFinished = false
            var finalError: Error? = nil
            
            // ✅ 启动打字机定时器，稳定控制 UI 刷新频率
            self.typingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
                guard let self else { 
                    timer.invalidate()
                    return 
                }
                
                if !self.messageBuffer.isEmpty {
                    // 每次只拿一个字渲染
                    let char = String(self.messageBuffer.removeFirst())
                    self.currentMetrics.uiRefreshCount += 1
                    DispatchQueue.main.async {
                        self.onUIDelta?(char)
                    }
                } else if isNetworkFinished {
                    // ✅ 修复：网络接收结束且缓冲区完全吐干净后，才停止定时器并结束聊天
                    timer.invalidate()
                    self.typingTimer = nil
                    DispatchQueue.main.async {
                        self.printMetricsAndFinish {
                            self.onUIComplete?(finalError)
                        }
                    }
                }
            }

            NetWorkManager.shared.requestSteam(parameters: parameters) { [weak self] rawString in
                guard let self else { return }
                tempBuffer.append(rawString)
                while let range = tempBuffer.range(of: "\n") {
                    let line = String(tempBuffer[..<range.lowerBound])
                    tempBuffer.removeSubrange(..<range.upperBound)
                    guard let delta = self.processStreamLine(line) else { continue }
                    if !delta.isEmpty {
                        self.recordFirstToken()
                        self.currentMetrics.receivedTextLength += delta.count
                        // ✅ 解析出文字后，不直接操作 UI，而是放进缓冲池排队
                        self.messageBuffer += delta
                    }
                }
            } completion: { [weak self] error in
                guard let self else { return }
                self.recordTotalTime()
                
                // ⚠️ 处理结尾可能没有换行符的残余缓冲数据
                if !tempBuffer.isEmpty {
                    if let delta = self.processStreamLine(tempBuffer), !delta.isEmpty {
                        self.currentMetrics.receivedTextLength += delta.count
                        self.messageBuffer += delta
                    }
                    tempBuffer = ""
                }
                
                // 标记网络已结束，让定时器把池子里的字吐完即可收尾
                finalError = error
                isNetworkFinished = true
            }
        }

        if prewarm {
            // ✅ 方案5独有：网络预热
            // 解释：在发真正的流式请求前，先发一个体积最小的 OPTIONS 请求。
            // 目的：提前进行 DNS 解析、TCP 三次握手、TLS 握手。
            // 效果：真实请求发送时，高速公路已经建好，省去了 100~300ms 的建联时间，首字延迟达到极致。
            guard let prewarmUrl = URL(string: "https://nlp.aliyuncs.com") else {
                start()
                return
            }
            var request = URLRequest(url: prewarmUrl)
            request.httpMethod = "OPTIONS"
            AF.request(request).response { [weak self] _ in
                self?.startTime = DispatchTime.now() // 扣除预热时间，重新开始纯净计时
                start()
            }
        } else {
            start()
        }
    }
}
