//
//  LearningEventBus.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/26.
//

import Foundation

/// 跨模块事件总线，用于收集用户的学习行为日志
public class LearningEventBus {
    
    public static let shared = LearningEventBus()
    
    private init() {}
    
    /// 通知常量
    public static let actionDidOccurNotification = Notification.Name("LearningEventBus.actionDidOccur")
    public static let contextDidChangeNotification = Notification.Name("LearningEventBus.contextDidChange")
    
    /// 上报用户的原子行为
    public func post(action: LearningAction) {
        NotificationCenter.default.post(
            name: LearningEventBus.actionDidOccurNotification,
            object: nil,
            userInfo: ["action": action]
        )
    }
    
    /// 上报上下文变更 (如进入新关卡，切换知识点)
    public func updateContext(_ context: LevelContext) {
        NotificationCenter.default.post(
            name: LearningEventBus.contextDidChangeNotification,
            object: nil,
            userInfo: ["context": context]
        )
    }
}
