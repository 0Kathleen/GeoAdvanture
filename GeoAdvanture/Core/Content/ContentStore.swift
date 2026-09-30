//
//  ContentStore.swift
//  GeoAdvanture
//
//  全项目「静态内容」的唯一加载入口（Single Source of Truth）。
//  只负责从 bundle 内的 JSON 读取只读内容；用户进度请走 ProgressStore。
//

import Foundation

final class ContentStore {

    static let shared = ContentStore()

    /// 圈层知识（地壳 / 地幔 / 地核）
    let layers: [LayerKnowledge]
    /// 解锁规则（事件 → 解锁目标）
    let unlockRules: [UnlockRule]
    /// 结构化学习内容：问题、知识专题、关卡二级页、迁移任务与综合任务。
    let learningData: NotebookLearningData

    // MARK: 横版探索世界（新玩法）

    /// 横版世界（按 index 升序，即下潜顺序）
    let worlds: [WorldLayer]
    /// 全部 POI
    let pois: [POI]
    /// 图鉴藏品
    let collectibles: [Collectible]
    /// 探测仪器（一期仅展示）
    let instruments: [Instrument]

    private init() {
        layers = Self.decode(NotebookData.self, from: "NotebookKnowledge")?.layers ?? []
        unlockRules = Self.decode(UnlockRulesData.self, from: "UnlockRules")?.rules ?? []
        learningData = Self.decode(NotebookLearningData.self, from: "NotebookLearning")
            ?? NotebookLearningData(
                schemaVersion: 1,
                layers: [],
                challengeHubs: [],
                achievementCards: [],
                transferChallenges: [],
                integratedMissions: [])

        worlds = (Self.decode([WorldLayer].self, from: "Worlds") ?? []).sorted { $0.index < $1.index }
        pois = Self.decode([POI].self, from: "POIs") ?? []
        collectibles = Self.decode([Collectible].self, from: "Collectibles") ?? []
        instruments = Self.decode([Instrument].self, from: "Instruments") ?? []

        print("✅ ContentStore 加载完成：圈层 \(layers.count) / 学习层 \(learningData.layers.count) / 规则 \(unlockRules.count)")
        print("   └─ 世界 \(worlds.count) / POI \(pois.count) / 藏品 \(collectibles.count) / 仪器 \(instruments.count)")

        #if DEBUG
        validateLearningContent()
        #endif
    }

    // MARK: - 查询便捷方法

    func layer(id: String) -> LayerKnowledge? {
        layers.first { $0.id == id }
    }

    /// 按 0 基下标取圈层
    func layer(at index: Int) -> LayerKnowledge? {
        layers.indices.contains(index) ? layers[index] : nil
    }

    // MARK: - 结构化学习内容

    func learningLayer(id: String) -> LayerLearningContent? {
        learningData.layers.first { $0.layerId == id }
    }

    func inquiry(id: String) -> InquiryTopic? {
        learningData.layers.lazy.flatMap(\.inquiries).first { $0.id == id }
    }

    func knowledgeTopic(id: String) -> KnowledgeTopic? {
        learningData.layers.lazy.flatMap(\.knowledgeTopics).first { $0.id == id }
    }

    func knowledgeTopics(layerId: String) -> [KnowledgeTopic] {
        learningLayer(id: layerId)?.knowledgeTopics ?? []
    }

    func knowledgeTopics(evidenceSourceId: String) -> [KnowledgeTopic] {
        learningData.layers
            .flatMap(\.knowledgeTopics)
            .filter { $0.evidenceSourceIds.contains(evidenceSourceId) }
    }

    func challengeHub(id: String) -> ChallengeHubDefinition? {
        learningData.challengeHubs.first { $0.id == id }
    }

    func challengeHub(poiId: String) -> ChallengeHubDefinition? {
        learningData.challengeHubs.first { $0.poiId == poiId }
    }

    func achievementCard(challengeId: String, taskId: String?) -> AchievementCardDefinition? {
        learningData.achievementCards.first {
            $0.challengeId == challengeId && $0.taskId == taskId
        }
    }

    func transferChallenge(id: String) -> TransferChallengeDefinition? {
        learningData.transferChallenges.first { $0.id == id }
    }

    func transferChallenges(topicId: String, primaryId: String) -> [TransferChallengeDefinition] {
        learningData.transferChallenges
            .filter { $0.topicId == topicId }
            .sorted {
                if $0.id == primaryId { return true }
                if $1.id == primaryId { return false }
                return $0.id < $1.id
            }
    }

    func integratedMission(id: String) -> IntegratedMissionDefinition? {
        learningData.integratedMissions.first { $0.id == id }
    }

    // MARK: - 世界 / POI / 藏品 / 仪器 查询

    func world(id: String) -> WorldLayer? {
        worlds.first { $0.id == id }
    }

    /// 按下潜顺序（index）取世界
    func world(at index: Int) -> WorldLayer? {
        worlds.first { $0.index == index }
    }

    /// 某层世界内的全部 POI（按 x 从左到右排序，便于布置与遍历）
    func pois(worldId: String) -> [POI] {
        pois.filter { $0.worldId == worldId }.sorted { $0.x < $1.x }
    }

    func poi(id: String) -> POI? {
        pois.first { $0.id == id }
    }

    func collectible(id: String) -> Collectible? {
        collectibles.first { $0.id == id }
    }

    func collectibles(worldId: String) -> [Collectible] {
        collectibles.filter { $0.worldId == worldId }
    }

    func instrument(id: String) -> Instrument? {
        instruments.first { $0.id == id }
    }

    /// 所有收获 id（用于 starter 解锁、对账、开发期校验）
    var allHarvestIds: [String] {
        layers.flatMap { $0.harvests ?? [] }.map { $0.id }
    }

    var allKnowledgeTopicIds: [String] {
        learningData.layers.flatMap(\.knowledgeTopics).map(\.id)
    }

    /// 所有内容 id 的并集（用于开发期悬空引用校验、进度对账）
    var allContentIds: Set<String> {
        var ids = Set<String>()
        ids.formUnion(layers.map { $0.id })
        ids.formUnion(allHarvestIds)
        ids.formUnion(worlds.map { $0.id })
        ids.formUnion(pois.map { $0.id })
        ids.formUnion(collectibles.map { $0.id })
        ids.formUnion(instruments.map { $0.id })
        ids.formUnion(learningData.layers.flatMap(\.inquiries).map(\.id))
        ids.formUnion(allKnowledgeTopicIds)
        ids.formUnion(learningData.challengeHubs.map(\.id))
        ids.formUnion(learningData.challengeHubs.flatMap(\.taskIds))
        ids.formUnion(learningData.challengeHubs.compactMap { $0.fieldTask?.observationId })
        ids.formUnion(learningData.achievementCards.map(\.id))
        ids.formUnion(learningData.transferChallenges.map(\.id))
        ids.formUnion(learningData.integratedMissions.map(\.id))
        return ids
    }

    #if DEBUG
    private func validateLearningContent() {
        let poiIds = Set(pois.map(\.id))
        let topicIds = Set(allKnowledgeTopicIds)
        let transferIds = Set(learningData.transferChallenges.map(\.id))
        let missionIds = Set(learningData.integratedMissions.map(\.id))

        func duplicates(in values: [String]) -> Set<String> {
            var seen = Set<String>()
            return Set(values.filter { !seen.insert($0).inserted })
        }

        let duplicateTopics = duplicates(in: allKnowledgeTopicIds)
        if !duplicateTopics.isEmpty {
            print("❗️ NotebookLearning 重复知识专题 id：\(duplicateTopics.sorted())")
        }

        for layer in learningData.layers {
            for inquiry in layer.inquiries {
                for id in inquiry.linkedPOIIds where !poiIds.contains(id) {
                    print("❗️ NotebookLearning 问题 \(inquiry.id) 引用了不存在的 POI：\(id)")
                }
                for id in inquiry.knowledgeTopicIds where !topicIds.contains(id) {
                    print("❗️ NotebookLearning 问题 \(inquiry.id) 引用了不存在的知识专题：\(id)")
                }
            }
            for topic in layer.knowledgeTopics {
                if !transferIds.contains(topic.transferChallengeId) {
                    print("❗️ NotebookLearning 专题 \(topic.id) 缺少迁移任务：\(topic.transferChallengeId)")
                }
                for id in topic.relatedTopicIds where !topicIds.contains(id) {
                    print("❗️ NotebookLearning 专题 \(topic.id) 引用了不存在的关联专题：\(id)")
                }
            }
            if let id = layer.integratedMissionId, !missionIds.contains(id) {
                print("❗️ NotebookLearning 圈层 \(layer.layerId) 引用了不存在的综合任务：\(id)")
            }
        }

        for hub in learningData.challengeHubs where !poiIds.contains(hub.poiId) {
            print("❗️ NotebookLearning 二级页 \(hub.id) 引用了不存在的 POI：\(hub.poiId)")
        }
        for hub in learningData.challengeHubs {
            guard let task = hub.fieldTask else { continue }
            if !hub.taskIds.contains(task.id) {
                print("❗️ NotebookLearning 二级页 \(hub.id) 的现场任务未列入 taskIds：\(task.id)")
            }
            let optionIds = Set(task.options.map(\.id))
            for id in task.correctOptionIds where !optionIds.contains(id) {
                print("❗️ NotebookLearning 现场任务 \(task.id) 的答案不存在：\(id)")
            }
        }
        for card in learningData.achievementCards {
            if !poiIds.contains(card.challengeId) {
                print("❗️ NotebookLearning 成就卡 \(card.id) 引用了不存在的挑战：\(card.challengeId)")
            }
            if !topicIds.contains(card.knowledgeTopicId) {
                print("❗️ NotebookLearning 成就卡 \(card.id) 引用了不存在的知识专题：\(card.knowledgeTopicId)")
            }
        }
        for mission in learningData.integratedMissions {
            for id in mission.requiredTopicIds where !topicIds.contains(id) {
                print("❗️ NotebookLearning 综合任务 \(mission.id) 引用了不存在的知识专题：\(id)")
            }
        }
    }
    #endif

    // MARK: - 解码

    private static func decode<T: Decodable>(_ type: T.Type, from resource: String) -> T? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            print("⚠️ ContentStore：找不到资源 \(resource).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ ContentStore：解析 \(resource).json 失败: \(error)")
            return nil
        }
    }
}
