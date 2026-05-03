//
//  LearningAction.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/26.
//

import Foundation


/// 学习场景上下文
public struct LevelContext {
    public let levelId: String
    public let levelName: String
    public let targetGoal: String
    
    public init(levelId: String, levelName: String, targetGoal: String) {
        self.levelId = levelId
        self.levelName = levelName
        self.targetGoal = targetGoal
    }
}

/// 用户行为枚举 (埋点类型)
public enum ActionType {
    /// 页面进入 (开始计时)
    case enterPage
    /// 页面离开 (重置状态机)
    case leavePage
    /// 发生有效交互 (正常操作)
    case validInteraction(target: String)
    /// 发生无效点击 (反复乱点)
    case invalidInteraction(target: String)
    /// 拖拽/答题错误
    case error(source: String, target: String)
    /// 拖拽/答题成功
    case success(source: String, target: String)
    /// 关卡/环节完成
    case stepCompleted
}

/// 用户行为模型
public struct LearningAction {
    public let type: ActionType
    public let timestamp: TimeInterval
    
    public init(type: ActionType, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.type = type
        self.timestamp = timestamp
    }
}
