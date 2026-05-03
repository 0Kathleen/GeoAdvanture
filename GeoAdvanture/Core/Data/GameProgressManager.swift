//
//  GameProgressManager.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import Foundation

/// 统一的进度与数据管理中心，负责持久化游戏和学习的进度
public class GameProgressManager {
    public static let shared = GameProgressManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - 1. 勋章系统管理 (Medals)
    public func isMedalUnlocked(id: String) -> Bool {
        return defaults.bool(forKey: "progress_medal_\\(id)")
    }
    
    public func unlockMedal(id: String) {
        defaults.set(true, forKey: "progress_medal_\\(id)")
    }
    
    // MARK: - 2. 地壳探险场景解锁 (Crustal Scenes)
    public func isCrustSceneUnlocked(id: String) -> Bool {
        return defaults.bool(forKey: "progress_crust_\\(id)")
    }
    
    public func unlockCrustScene(id: String) {
        defaults.set(true, forKey: "progress_crust_\\(id)")
    }
    
    // MARK: - 3. 笔记本知识收获解锁 (Harvests)
    public func isHarvestUnlocked(id: String) -> Bool {
        return defaults.bool(forKey: "progress_harvest_\\(id)")
    }
    
    public func unlockHarvest(id: String) {
        defaults.set(true, forKey: "progress_harvest_\\(id)")
    }
    
    // MARK: - 4. 用户设置 (Settings)
    public var isAIVoiceEnabled: Bool {
        get {
            if defaults.object(forKey: "setting_ai_voice") == nil { return true } // 默认开启
            return defaults.bool(forKey: "setting_ai_voice")
        }
        set {
            defaults.set(newValue, forKey: "setting_ai_voice")
        }
    }
}
