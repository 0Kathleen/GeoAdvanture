//
//  GameProgressManager.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import Foundation

/// 统一的进度门面（Facade）。对外保持稳定的 API，内部委托给 CoreData 的 ProgressStore。
/// 内容定义请走 ContentStore；本类只关心「用户进度」。
public class GameProgressManager {
    public static let shared = GameProgressManager()

    private let store = ProgressStore.shared

    /// 一次性：按 `NotebookKnowledge.json` 顺序默认解锁前两个「关卡收获」知识点（便于新用户先看到内容）。
    private static let starterKey = "starter_notebook_harvests_v1"

    private init() {
        // 先把旧 UserDefaults 数据迁移到 CoreData，再执行 starter 逻辑
        LegacyMigrator.runIfNeeded(into: store)
        applyStarterNotebookHarvestUnlocksOnce()
    }

    private func applyStarterNotebookHarvestUnlocksOnce() {
        guard !store.bool(forKey: Self.starterKey, default: false) else { return }
        for id in Self.firstNotebookHarvestIds(count: 2) {
            unlockHarvest(id: id)
        }
        store.setBool(true, forKey: Self.starterKey)
    }

    /// 按圈层顺序、每个圈层内收获顺序，取前 `count` 个收获 ID。
    private static func firstNotebookHarvestIds(count: Int) -> [String] {
        guard count > 0 else { return [] }
        var ids: [String] = []
        for layer in ContentStore.shared.layers {
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
        store.isUnlocked(.medal, id)
    }

    public func unlockMedal(id: String) {
        store.unlock(.medal, id)
    }

    // MARK: - 2. 地壳探险场景解锁 (Crustal Scenes)
    public func isCrustSceneUnlocked(id: String) -> Bool {
        store.isUnlocked(.crustScene, id)
    }

    public func unlockCrustScene(id: String) {
        store.unlock(.crustScene, id)
    }

    // MARK: - 3. 笔记本知识收获解锁 (Harvests)
    public func isHarvestUnlocked(id: String) -> Bool {
        store.isUnlocked(.harvest, id)
    }

    public func unlockHarvest(id: String) {
        store.unlock(.harvest, id)
    }

    // MARK: - 4. 用户设置 (Settings)
    public var isAIVoiceEnabled: Bool {
        get { store.bool(forKey: "ai_voice", default: true) } // 默认开启
        set { store.setBool(newValue, forKey: "ai_voice") }
    }

    // MARK: - 5. 维护
    public func resetAllProgress() {
        store.resetAllProgress()
    }
}
