//
//  LearningProgressCoordinator.swift
//  GeoAdvanture
//
//  学习进度唯一协调入口：把“完成关卡/理解因果/完成迁移/完成综合任务”
//  转换为单调递进的知识状态。页面和游戏不互相直接修改状态。
//

import Foundation

extension Notification.Name {
    /// userInfo: topicId, oldStage, newStage, sourceId（可选）
    static let didChangeKnowledgeProgress = Notification.Name("didChangeKnowledgeProgress")
    /// userInfo: missionId, layerId
    static let didCompleteIntegratedMission = Notification.Name("didCompleteIntegratedMission")
}

final class LearningProgressCoordinator {

    static let shared = LearningProgressCoordinator()

    private let content = ContentStore.shared
    private let progress = GameProgressManager.shared

    private init() {}

    /// 一个 POI、藏品或关卡任务成为学习证据时调用。
    /// 同一 source 可对应多个专题；重复调用不会让阶段回退或重复发放。
    func recordEvidence(sourceId: String, score: Int = 0) {
        for topic in content.knowledgeTopics(evidenceSourceId: sourceId) {
            recordDiscovery(topicId: topic.id, sourceId: sourceId, score: score)
        }
    }

    /// 成就卡确认后的统一入账入口。结果中的多个来源会自动去重，兼容 POI 与图鉴藏品证据。
    func recordChallengeResult(_ result: ChallengeResult, primaryTopicId: String? = nil) {
        if let primaryTopicId {
            recordDiscovery(topicId: primaryTopicId, sourceId: result.challengeId, score: result.score)
        }
        let sources = Set([result.challengeId] + result.observationIds + result.earnedArtifactIds)
        sources.forEach { recordEvidence(sourceId: $0, score: result.score) }
    }

    func recordDiscovery(topicId: String, sourceId: String? = nil, score: Int = 0) {
        guard content.knowledgeTopic(id: topicId) != nil else {
            assertionFailure("未知知识专题：\(topicId)")
            return
        }
        promote(topicId: topicId, to: .discovered, score: score, sourceId: sourceId)
        // 兼容当前第三页与既有存档；后续 UI 全量切换后可移除此桥接。
        progress.unlockHarvest(id: topicId)
    }

    func recordUnderstanding(topicId: String, score: Int = 0) {
        guard content.knowledgeTopic(id: topicId) != nil else {
            assertionFailure("未知知识专题：\(topicId)")
            return
        }
        promote(topicId: topicId, to: .understood, score: score, sourceId: nil)
    }

    func recordApplication(topicId: String, score: Int = 0) {
        guard content.knowledgeTopic(id: topicId) != nil else {
            assertionFailure("未知知识专题：\(topicId)")
            return
        }
        promote(topicId: topicId, to: .applied, score: score, sourceId: nil)
    }

    /// 综合任务完成是层通关的唯一高层入口；具体门禁在后续 Step 9 接入。
    func recordIntegratedMissionCompleted(missionId: String, score: Int = 0) {
        guard let mission = content.integratedMission(id: missionId) else {
            assertionFailure("未知综合任务：\(missionId)")
            return
        }
        guard mission.requiredTopicIds.allSatisfy({ progress.isKnowledgeApplied(id: $0) }) else {
            print("⚠️ 综合任务 \(missionId) 的必需知识尚未全部达到会应用")
            return
        }
        guard progress.completeIntegratedMission(id: missionId) else { return }
        NotificationCenter.default.post(
            name: .didCompleteIntegratedMission,
            object: nil,
            userInfo: ["missionId": missionId, "layerId": mission.layerId, "score": score])
    }

    private func promote(topicId: String,
                         to stage: KnowledgeMasteryStage,
                         score: Int,
                         sourceId: String?) {
        let oldStage = progress.knowledgeProgress(id: topicId).stage
        guard progress.promoteKnowledge(id: topicId, to: stage, score: score) else { return }
        let newStage = progress.knowledgeProgress(id: topicId).stage
        var info: [String: Any] = [
            "topicId": topicId,
            "oldStage": oldStage.rawValue,
            "newStage": newStage.rawValue
        ]
        if let sourceId { info["sourceId"] = sourceId }
        NotificationCenter.default.post(name: .didChangeKnowledgeProgress, object: nil, userInfo: info)
    }
}
