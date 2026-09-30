//
//  AICompanionViewModel.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/26.
//

import Foundation
import CoreMotion

public class AICompanionViewModel {
    
    
    public static let shared = AICompanionViewModel()
    
    // MARK: - 状态输出
    public var onStateChanged: ((LearningState) -> Void)?
    
    /// 当前状态
    public private(set) var currentState: LearningState = .exploring {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onStateChanged?(self.currentState)
            }
        }
    }
    
    // MARK: - 内部数据记录
    private var currentContext: LevelContext?
    private var errorCount: Int = 0
    private var recentErrors: [String] = []
    
    ///  核心防错乱机制：当前请求大模型的 Task ID
    private var currentAIRequestTaskID: UUID?
    
    ///  核心防打扰机制：用于检测手机是否静置
    private let motionManager = CMMotionManager()
    private var isDeviceStatic = false
    
    /// 上次交互时间，用于计算“停留困惑”时间
    private var lastInteractionTime: TimeInterval = Date().timeIntervalSince1970
    
    /// 检测困惑停留的定时器
    private var hesitationTimer: Timer?
    /// 困惑判定阈值
    private let hesitationThreshold: TimeInterval = 10.0
    
    // MARK: - init
    private init() {
        _ = LearningBehaviorStore.shared // 触发 Store 初始化以开始监听
        setupObservers()
        startMotionUpdates()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        hesitationTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
    }
    
    // MARK: - 订阅事件
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAction(_:)),
            name: LearningEventBus.actionDidOccurNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContextChange(_:)),
            name: LearningEventBus.contextDidChangeNotification,
            object: nil
        )
    }
    
    // MARK: - 运动状态检测
    private func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 // 每秒检测一次即可，不需要太高频
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let motion = motion else { return }
                
                // 计算设备的加速度和旋转角速度，判断是否处于绝对静止状态
                let rotationRate = motion.rotationRate
                let userAcceleration = motion.userAcceleration
                
                let isRotating = abs(rotationRate.x) > 0.1 || abs(rotationRate.y) > 0.1 || abs(rotationRate.z) > 0.1
                let isMoving = abs(userAcceleration.x) > 0.05 || abs(userAcceleration.y) > 0.05 || abs(userAcceleration.z) > 0.05
                
                self?.isDeviceStatic = !isRotating && !isMoving
            }
        }
    }

    // MARK: - 处理上下文变更
    @objc private func handleContextChange(_ notification: Notification) {
        guard let context = notification.userInfo?["context"] as? LevelContext else { return }
        self.currentContext = context
        
        // 同步通知给持久化存储器当前处于哪个模块
        LearningBehaviorStore.shared.updateCurrentLevel(context.levelId)
        
        // 切换关卡时，重置所有内部状态
        self.errorCount = 0
        self.recentErrors.removeAll()
        
        // 特定页面的欢迎语
        if context.levelId == "laboratory" {
            self.currentState = .greeting(message: "欢迎来到地心实验室！在这里你可以调配样本，看看它能不能撑到地心哦！")
        } else if context.levelId == "game_crust" {
            self.currentState = .greeting(message: "欢迎来到地壳探险！试着拖动板块，看看会发生什么奇妙的变化吧！")
        } else {
            self.currentState = .exploring
        }
        
        resetTimer()
    }
    
    // MARK: - 核心状态机演算
    @objc private func handleAction(_ notification: Notification) {
        guard let action = notification.userInfo?["action"] as? LearningAction else { return }
        
        // 任何行为发生时，都重置最后交互时间与定时器
        self.lastInteractionTime = action.timestamp
        resetTimer()
        
        switch action.type {
        case .enterPage:
            if case .greeting = currentState {
                // 如果已经是打招呼状态，保留，气泡会自动消失
            } else {
                self.currentState = .exploring
            }
            
        case .leavePage:
            hesitationTimer?.invalidate()
            
        case .validInteraction(_):
            if currentState != .exploring {
                self.currentState = .exploring
            }
            
        case .invalidInteraction(_):
            if case .confused(_) = currentState {
                // 如果已经是困惑，不要重复弹，防抖
            } else {
                self.currentState = .confused(L1Tip: "找不到线索吗？试试乱拖一下~")
            }
            
        case .error(let source, let target, let details):
            // 错误计数+1
            errorCount += 1
            if let details = details {
                recentErrors.append("将[\(source)]错放到了[\(target)]，因为：\(details)")
            } else {
                recentErrors.append("将[\(source)]错放到了[\(target)]")
            }
            
            if errorCount >= 3 {
                let contextStr = currentContext?.targetGoal ?? "未知任务"
                let errors = Array(recentErrors.suffix(3))
                // 触发真正的网络请求
                self.requestAIHelp(context: contextStr, errors: errors)
                // 触发后，将错误清零重新算
                errorCount = 0
                recentErrors.removeAll()
            } else {
                self.currentState = .confused(L1Tip: "好像放错位置了哦，再想想？")
            }
            
        case .success(_, _, _):
            // 防时序错乱：用户自己蒙对了，立即作废正在进行的大模型请求
            self.currentAIRequestTaskID = nil
            
            self.currentState = .proficient(encouragement: "太棒了，你找对位置啦！")
            // 成功后清除错误记忆
            errorCount = 0
            recentErrors.removeAll()
            
            // 5 秒后自动回退到探索状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let self = self else { return }
                if case .proficient = self.currentState {
                    self.currentState = .exploring
                }
            }
            
        case .stepCompleted:
            break
        }
    }
    
    // MARK: - 停留困惑判定
    private func resetTimer() {
        hesitationTimer?.invalidate()
        hesitationTimer = Timer.scheduledTimer(withTimeInterval: hesitationThreshold, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.checkHesitation()
        }
    }
    
    private func checkHesitation() {
        // 智能防打扰机制：
        // 如果 10 秒后触发此闭包，说明期间用户什么都没做
        // 此时需要判断陀螺仪数据。如果手机完全静止（人可能走开了放桌上），则直接 return，不触发 AI 打扰
        if isDeviceStatic {
            print("📱 手机处于静止状态，AI 进入防打扰模式，不触发困惑提示。")
            // 重新开启下一轮检测
            resetTimer()
            return
        }
        
        // 如果当前是探索中，将其切为犹豫困惑
        if case .exploring = currentState {
            self.currentState = .confused(L1Tip: "是在思考吗？需要我帮忙的话可以点我哦！")
        }
    }
    
    // MARK: - 大模型 L2 深度求助机制
    private func requestAIHelp(context: String, errors: [String]) {
        // 1. 生成唯一 Task ID (防止时序错乱脏数据)
        let taskID = UUID()
        self.currentAIRequestTaskID = taskID
        
        // 先把状态改为挣扎
        self.currentState = .struggling(context: context, recentErrors: errors)
        
        // 2. 组装 Prompt
        let errorDescriptions = errors.joined(separator: "，并且")
        let prompt = """
        当前用户正在进行的任务是：【\(context)】
        但是用户连续犯了以下错误：【\(errorDescriptions)】
        请用一句话（30字以内）亲切地启发他，不要直接告诉他最终答案，最好以疑问句结尾引导他自己思考。
        """
        
        let levelId = currentContext?.levelId ?? "unknown"
        let dynamicSystemPrompt = AIContextManager.shared.getSystemPrompt(for: levelId)
        
        // 3. 构造请求参数
        let parameters: [String: Any] = [
            "model": "qwen-plus-character",
            "stream": true,
            "messages": [
                ["role": "system", "content": dynamicSystemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]
        
        var fullAIResponse = ""
        var isFirstToken = true
        
        // 4. 调用网络流式请求
        AINetworkManager.shared.requestOptimalStream(
            parameters: parameters,
            prewarm: true
        ) { [weak self] delta in
            guard let self = self else { return }
            
            // 【核心防御】拦截迟到的脏数据
            guard self.currentAIRequestTaskID == taskID else {
                print(" 拦截到了迟到的脏数据，用户已离开当前困境，丢弃 AI 回复。")
                AINetworkManager.shared.stop()
                return
            }
            
            if isFirstToken {
                // 收到第一个字时，停止思考状态，准备打字输出
                isFirstToken = false
            }
            
            fullAIResponse += delta
            
            // 将流式吐出的文字更新到状态中，让 UI 气泡产生“打字机”效果
            self.currentState = .confused(L1Tip: fullAIResponse) 
        } onComplete: { [weak self] _ in
            // 请求结束
            guard let self = self, self.currentAIRequestTaskID == taskID else { return }
            // 可以在这里处理结束逻辑
        }
    }
    
    // 解析流式按行 JSON (复用现有逻辑)
    // 已经迁移到 AINetworkManager 中，这里不再需要
}
