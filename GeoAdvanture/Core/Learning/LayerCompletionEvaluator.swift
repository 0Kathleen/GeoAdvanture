//
//  LayerCompletionEvaluator.swift
//  GeoAdvanture
//
//  Step 9：统一“综合任务开放 → 圈层通关 → 下一层解锁”的判定。
//

import Foundation

extension Notification.Name {
    /// userInfo: layerId, missionId, score, stars
    static let didCompleteLayerLearning = Notification.Name("didCompleteLayerLearning")
}

struct IntegratedMissionReadiness {
    let mission: IntegratedMissionDefinition
    let requiredPOIIds: [String]
    let missingPOIIds: [String]
    let missingTopicIds: [String]
    let isCompleted: Bool

    var canStart: Bool { missingPOIIds.isEmpty && missingTopicIds.isEmpty }
}

final class LayerCompletionEvaluator {

    static let shared = LayerCompletionEvaluator()

    private let content = ContentStore.shared
    private let progress = GameProgressManager.shared

    private init() {}

    func readiness(layerId: String) -> IntegratedMissionReadiness? {
        guard let missionId = content.learningLayer(id: layerId)?.integratedMissionId,
              let mission = content.integratedMission(id: missionId) else { return nil }

        let requiredHubs = content.learningData.challengeHubs.compactMap { hub -> ChallengeHubDefinition? in
            guard let poi = content.poi(id: hub.poiId), poi.worldId == layerId else { return nil }
            return hub
        }
        let requiredPOIIds = requiredHubs.map(\.poiId)
        let missingPOIIds = requiredHubs.filter { hub in
            hub.taskIds.isEmpty || !hub.taskIds.allSatisfy { progress.isChallengeTaskCompleted(id: $0) }
        }.map(\.poiId)
        let missingTopicIds = mission.requiredTopicIds.filter { !progress.isKnowledgeApplied(id: $0) }
        return .init(
            mission: mission,
            requiredPOIIds: requiredPOIIds,
            missingPOIIds: missingPOIIds,
            missingTopicIds: missingTopicIds,
            isCompleted: progress.isIntegratedMissionCompleted(id: mission.id))
    }

    func canOpenNotebook(layerNumber: Int) -> Bool {
        switch layerNumber {
        case ...1: return true
        case 2: return progress.isWorldCompleted(id: "crust")
        default: return progress.isWorldCompleted(id: "mantle")
        }
    }

    func notebookUnlockHint(layerNumber: Int) -> String {
        switch layerNumber {
        case 2: return "完成地壳的“地质侦探：神秘小岛”，就能解锁地幔笔记本。"
        case 3: return "完成地幔学习后，就能解锁地核笔记本。"
        default: return ""
        }
    }

    /// 综合任务是圈层通关的唯一高层入口。重复挑战只会提高最佳星级，不会回退进度。
    @discardableResult
    func completeMission(id missionId: String, score: Int) -> Bool {
        guard let mission = content.integratedMission(id: missionId),
              let status = readiness(layerId: mission.layerId),
              status.canStart else { return false }

        LearningProgressCoordinator.shared.recordIntegratedMissionCompleted(
            missionId: missionId,
            score: score)
        guard progress.isIntegratedMissionCompleted(id: missionId) else { return false }

        let stars = score >= 90 ? 3 : (score >= 70 ? 2 : 1)
        progress.completeWorld(id: mission.layerId, stars: stars)
        NotificationCenter.default.post(
            name: .didCompleteLayerLearning,
            object: nil,
            userInfo: [
                "layerId": mission.layerId,
                "missionId": missionId,
                "score": score,
                "stars": stars
            ])
        return true
    }
}
