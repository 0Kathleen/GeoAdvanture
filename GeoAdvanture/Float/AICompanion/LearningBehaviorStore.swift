//
//  LearningBehaviorStore.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import Foundation

/// 学习行为日志模型，用于持久化存储
public struct LearningBehaviorLog: Codable {
    public let timestamp: TimeInterval
    public let levelId: String
    public let source: String
    public let target: String
    public let details: String?
    public let isError: Bool
}

/// 负责将用户的学习行为（尤其是试错记录）持久化存储，便于后续 AI 分析或生成学习报告
public class LearningBehaviorStore {
    
    public static let shared = LearningBehaviorStore()
    
    private let queue = DispatchQueue(label: "com.geoadvanture.behaviorstore")
    private let fileName = "user_behavior_logs.json"
    
    private var logs: [LearningBehaviorLog] = []
    
    private var fileURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(fileName)
    }
    
    private init() {
        loadLogs()
        
        // 监听学习事件，将重要的错误/成功记录持久化
        NotificationCenter.default.addObserver(self, selector: #selector(handleAction(_:)), name: LearningEventBus.actionDidOccurNotification, object: nil)
    }
    
    @objc private func handleAction(_ notification: Notification) {
        guard let action = notification.userInfo?["action"] as? LearningAction else { return }
        
        // 我们需要知道当前是在哪个模块发生的，可以从 AICompanionViewModel 拿，或者独立获取
        // 这里为了解耦，直接获取 AICompanionViewModel 里暴露出来的当前 levelId，或者你可以将 levelId 一并放入 LearningAction
        // 作为快速实现，我们可以根据 source 来粗略推断模块，或者最好是给 LearningAction 添加一个可选项
        
        let currentLevel = getCurrentLevelId()
        
        switch action.type {
        case .error(let source, let target, let details):
            let log = LearningBehaviorLog(timestamp: action.timestamp, levelId: currentLevel, source: source, target: target, details: details, isError: true)
            addLog(log)
            
        case .success(let source, let target, let details):
            let log = LearningBehaviorLog(timestamp: action.timestamp, levelId: currentLevel, source: source, target: target, details: details, isError: false)
            addLog(log)
            
        default:
            break
        }
    }
    
    // 粗略获取当前所在的 Level，可以通过读取UserDefaults或全局状态，此处暂用通知机制在进入页面时记录
    private var _cachedLevelId: String = "unknown"
    public func updateCurrentLevel(_ levelId: String) {
        queue.async {
            self._cachedLevelId = levelId
        }
    }
    
    private func getCurrentLevelId() -> String {
        var level = "unknown"
        queue.sync { level = self._cachedLevelId }
        return level
    }
    
    // MARK: - 数据存取
    
    private func addLog(_ log: LearningBehaviorLog) {
        queue.async {
            self.logs.append(log)
            // 限制最多保存 500 条记录，防止文件过大
            if self.logs.count > 500 {
                self.logs.removeFirst(self.logs.count - 500)
            }
            self.saveLogs()
        }
    }
    
    public func getRecentErrorLogs(for levelId: String, limit: Int = 3) -> [LearningBehaviorLog] {
        var result: [LearningBehaviorLog] = []
        queue.sync {
            result = self.logs.filter { $0.levelId == levelId && $0.isError }
                             .suffix(limit)
        }
        return result
    }
    
    private func loadLogs() {
        queue.async {
            guard let data = try? Data(contentsOf: self.fileURL) else { return }
            do {
                self.logs = try JSONDecoder().decode([LearningBehaviorLog].self, from: data)
            } catch {
                print("加载行为日志失败: \\(error)")
            }
        }
    }
    
    private func saveLogs() {
        do {
            let data = try JSONEncoder().encode(self.logs)
            try data.write(to: self.fileURL, options: .atomic)
        } catch {
            print("保存行为日志失败: \\(error)")
        }
    }
}
