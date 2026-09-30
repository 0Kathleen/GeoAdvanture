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
    private init() {
        // 旧 UserDefaults 数据迁移到 CoreData（老用户）。
        // R-3 起：知识卡不再默认解锁，全部通过「闯关地图」完成关键点后点亮。
        LegacyMigrator.runIfNeeded(into: store)
        // Step 1：兼容已存在的 harvest 解锁，将其映射为新知识专题的“已发现”。
        store.migrateKnowledgeFromHarvests(topicIds: ContentStore.shared.allKnowledgeTopicIds)
    }

    // MARK: - 笔记本知识收获解锁 (Harvests)
    public func isHarvestUnlocked(id: String) -> Bool {
        store.isUnlocked(.harvest, id)
    }

    public func unlockHarvest(id: String) {
        store.unlock(.harvest, id)
    }

    // MARK: - 1.1 结构化知识专题进度

    func knowledgeProgress(id: String) -> KnowledgeProgressState {
        store.knowledgeProgress(topicId: id)
    }

    func knowledgeProgresses(ids: [String]) -> [KnowledgeProgressState] {
        store.knowledgeProgresses(topicIds: ids)
    }

    func isKnowledgeDiscovered(id: String) -> Bool {
        knowledgeProgress(id: id).stage >= .discovered
    }

    func isKnowledgeUnderstood(id: String) -> Bool {
        knowledgeProgress(id: id).stage >= .understood
    }

    func isKnowledgeApplied(id: String) -> Bool {
        knowledgeProgress(id: id).stage >= .applied
    }

    @discardableResult
    func promoteKnowledge(id: String,
                          to stage: KnowledgeMasteryStage,
                          score: Int = 0,
                          markUnread: Bool = true) -> Bool {
        store.promoteKnowledge(topicId: id, to: stage, score: score, markUnread: markUnread)
    }

    func markKnowledgeRead(id: String) {
        store.markKnowledgeRead(topicId: id)
    }

    // MARK: - 3.1 横版世界 · POI 发现 (POIs)
    public func isPOIDiscovered(id: String) -> Bool {
        store.isUnlocked(.poi, id)
    }

    public func markPOIDiscovered(id: String) {
        store.unlock(.poi, id)
    }

    // MARK: - 3.2 横版世界 · 图鉴采集 (Collectibles)
    public func isCollected(id: String) -> Bool {
        store.isUnlocked(.collectible, id)
    }

    public func collect(id: String) {
        store.unlock(.collectible, id)
    }

    // MARK: - 3.2.1 关卡二级页访问状态

    /// 二级主题页是否至少进入过一次。仅用于区分地图上的“未探索 / 进行中”，
    /// 不代表完成，也不会点亮知识专题。
    func isChallengeHubVisited(id: String) -> Bool {
        store.bool(forKey: "challenge_hub_visited.\(id)", default: false)
    }

    @discardableResult
    func markChallengeHubVisited(id: String) -> Bool {
        guard !isChallengeHubVisited(id: id) else { return false }
        store.setBool(true, forKey: "challenge_hub_visited.\(id)")
        return true
    }

    func isChallengeTaskCompleted(id: String) -> Bool {
        store.bool(forKey: "challenge_task_completed.\(id)", default: false)
    }

    @discardableResult
    func completeChallengeTask(id: String) -> Bool {
        guard !isChallengeTaskCompleted(id: id) else { return false }
        store.setBool(true, forKey: "challenge_task_completed.\(id)")
        return true
    }

    // MARK: - 3.3 横版世界 · 仪器 (Instruments，一期占位)
    public func hasInstrument(id: String) -> Bool {
        store.isUnlocked(.instrument, id)
    }

    public func grantInstrument(id: String) {
        store.unlock(.instrument, id)
    }

    // MARK: - 3.4 综合学习任务

    func isIntegratedMissionCompleted(id: String) -> Bool {
        store.isUnlocked(.integratedMission, id)
    }

    @discardableResult
    func completeIntegratedMission(id: String) -> Bool {
        store.unlock(.integratedMission, id)
    }

    // MARK: - 3.5 横版世界 · 层进度与门禁 (Worlds)
    public func isWorldCompleted(id: String) -> Bool {
        store.isWorldCompleted(worldId: id)
    }

    /// 标记某层通关（置 WorldProgress.isCompleted）。下一层能否进入由此派生。
    public func completeWorld(id: String, stars: Int = 0) {
        store.setWorldProgress(worldId: id, stars: stars, completed: true)
    }

    /// 层门禁：首层恒开；其余层看「上一层是否通关」。仪器等从不参与此判定。
    /// 二期占位层（comingSoon）始终不可进入。
    public func canEnterWorld(_ world: WorldLayer) -> Bool {
        if world.isComingSoon { return false }
        if world.index == 0 { return true }
        guard let prev = ContentStore.shared.world(at: world.index - 1) else { return true }
        return isWorldCompleted(id: prev.id)
    }

    /// 便捷重载：按世界 id 判断可进入性。
    public func canEnterWorld(id: String) -> Bool {
        guard let world = ContentStore.shared.world(id: id) else { return false }
        return canEnterWorld(world)
    }

    /// 按 `WorldLayer.completionRequirement` 评估某层是否已满足通关条件；满足则置 `WorldProgress.isCompleted`。
    /// operate 型 POI「完成」= 已发现（其小游戏成功时标记发现）。返回是否通关。
    @discardableResult
    public func evaluateWorldCompletion(worldId: String, stars: Int = 0) -> Bool {
        guard let world = ContentStore.shared.world(id: worldId) else { return false }
        // 采用知识闭环的圈层不再由旧世界中的单个 POI 提前通关。
        // 必须先完成综合任务，再由 LayerCompletionEvaluator 统一入账。
        if let missionId = ContentStore.shared.learningLayer(id: worldId)?.integratedMissionId {
            let done = isIntegratedMissionCompleted(id: missionId)
            if done { completeWorld(id: worldId, stars: stars) }
            return done
        }
        let req = world.completionRequirement
        let done: Bool
        switch req.kind {
        case .completePOIs:
            done = (req.poiIds ?? []).allSatisfy { isPOIDiscovered(id: $0) }
        case .discoverAllPOIs:
            done = ContentStore.shared.pois(worldId: worldId).allSatisfy { isPOIDiscovered(id: $0.id) }
        }
        if done { completeWorld(id: worldId, stars: stars) }
        return done
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

    public func resetProgress(worldId: String) {
        let content = ContentStore.shared
        let pois = content.pois(worldId: worldId)
        let poiIds = Set(pois.map(\.id))
        let collectibleIds = Set(
            content.collectibles(worldId: worldId).map(\.id)
                + pois.compactMap(\.collectibleId))
        let topicIds = Set(content.knowledgeTopics(layerId: worldId).map(\.id))
        let hubs = content.learningData.challengeHubs.filter { poiIds.contains($0.poiId) }
        let missionIds = Set(content.learningData.integratedMissions
            .filter { $0.layerId == worldId }
            .map(\.id))
        let settingKeys = Set(
            hubs.map { "challenge_hub_visited.\($0.id)" }
                + hubs.flatMap(\.taskIds).map { "challenge_task_completed.\($0)" })

        store.resetLayerProgress(
            worldId: worldId,
            poiIds: poiIds,
            collectibleIds: collectibleIds,
            harvestIds: topicIds,
            knowledgeTopicIds: topicIds,
            missionIds: missionIds,
            settingKeys: settingKeys)
    }
}
