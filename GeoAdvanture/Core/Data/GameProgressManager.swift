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
    
    /// 一次性：按 `NotebookKnowledge.json` 顺序默认解锁前两个「关卡收获」知识点（便于新用户先看到内容）。
    private static let starterNotebookHarvestsKey = "progress_starter_notebook_harvests_v1"
    
    private init() {
        applyStarterNotebookHarvestUnlocksOnce()
    }
    
    private func applyStarterNotebookHarvestUnlocksOnce() {
        guard !defaults.bool(forKey: Self.starterNotebookHarvestsKey) else { return }
        for id in Self.firstNotebookHarvestIds(count: 2) {
            unlockHarvest(id: id)
        }
        defaults.set(true, forKey: Self.starterNotebookHarvestsKey)
    }
    
    /// 按圈层顺序、每个圈层内收获顺序，取前 `count` 个收获 ID。
    private static func firstNotebookHarvestIds(count: Int) -> [String] {
        guard count > 0 else { return [] }
        var ids: [String] = []
        for layer in NotebookKnowledgeManager.shared.layers {
            guard let harvests = layer.harvests else { continue }
            for h in harvests {
                ids.append(h.id)
                if ids.count >= count { return ids }
            }
        }
        return ids
    }
    
    // MARK: - 1. 勋章系统管理 (Medals)
    public func isMedalUnlocked(id: String) -> Bool {
        return defaults.bool(forKey: "progress_medal_\(id)")
    }
    
    public func unlockMedal(id: String) {
        defaults.set(true, forKey: "progress_medal_\(id)")
    }
    
    // MARK: - 2. 地壳探险场景解锁 (Crustal Scenes)
    public func isCrustSceneUnlocked(id: String) -> Bool {
        return defaults.bool(forKey: "progress_crust_\(id)")
    }
    
    public func unlockCrustScene(id: String) {
        defaults.set(true, forKey: "progress_crust_\(id)")
    }
    
    // MARK: - 3. 笔记本知识收获解锁 (Harvests)
    public func isHarvestUnlocked(id: String) -> Bool {
        return defaults.bool(forKey: "progress_harvest_\(id)")
    }
    
    public func unlockHarvest(id: String) {
        defaults.set(true, forKey: "progress_harvest_\(id)")
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
