//
//  KnowledgeSummaryViewModel.swift
//  GeoAdvanture
//
//  Step 7：组合静态知识、证据来源与掌握状态，供知识总结页一次性渲染。
//

import Foundation

struct KnowledgeTopicListItemData {
    let id: String
    let title: String
    let stage: KnowledgeMasteryStage
    let hasUnreadContent: Bool
}

struct KnowledgeEvidenceViewData {
    let id: String
    let title: String
    let kindLabel: String
    let isCollected: Bool
}

struct KnowledgeRelationEdge: Hashable {
    let fromId: String
    let toId: String

    init(_ lhs: String, _ rhs: String) {
        if lhs < rhs {
            fromId = lhs
            toId = rhs
        } else {
            fromId = rhs
            toId = lhs
        }
    }
}

struct KnowledgeTopicDetailData {
    let topic: KnowledgeTopic
    let progress: KnowledgeProgressState
    let evidence: [KnowledgeEvidenceViewData]
    let unlockHint: String
    let nextPOIId: String?
    let transferChallenges: [TransferChallengeDefinition]
}

struct IntegratedMissionViewData {
    let mission: IntegratedMissionDefinition
    let canStart: Bool
    let isCompleted: Bool
    let completedPOICount: Int
    let totalPOICount: Int
    let appliedTopicCount: Int
    let requiredTopicCount: Int

    var statusText: String {
        if isCompleted { return "案件已破解 · 地壳学习完成" }
        if canStart { return "线索齐全，可以开始最终调查" }
        return "关卡线索 \(completedPOICount)/\(totalPOICount) · 应用知识 \(appliedTopicCount)/\(requiredTopicCount)"
    }
}

struct KnowledgeSummaryPageData {
    let layerName: String
    let overview: LayerOverviewViewData
    let topics: [KnowledgeTopicListItemData]
    let selected: KnowledgeTopicDetailData
    let relationEdges: [KnowledgeRelationEdge]
    let discoveredCount: Int
    let understoodCount: Int
    let appliedCount: Int
    let integratedMission: IntegratedMissionViewData?
}

final class KnowledgeSummaryViewModel {

    private let notebookViewModel: NotebookViewModel
    private let content = ContentStore.shared
    private let progress = GameProgressManager.shared

    init(notebookViewModel: NotebookViewModel) {
        self.notebookViewModel = notebookViewModel
    }

    func makePageData(selectedTopicId: String?) -> KnowledgeSummaryPageData? {
        let topics = content.knowledgeTopics(layerId: notebookViewModel.layerId)
        guard !topics.isEmpty else { return nil }

        let items = topics.map { topic -> KnowledgeTopicListItemData in
            let state = progress.knowledgeProgress(id: topic.id)
            return .init(
                id: topic.id,
                title: topic.title,
                stage: state.stage,
                hasUnreadContent: state.hasUnreadContent)
        }
        let selectedId = selectedTopicId.flatMap { id in
            topics.contains(where: { $0.id == id }) ? id : nil
        } ?? items.first(where: { $0.stage >= .discovered })?.id ?? topics[0].id
        guard let selectedTopic = topics.first(where: { $0.id == selectedId }) else { return nil }

        let detail = makeDetail(topic: selectedTopic)
        let discoveredIds = Set(items.filter { $0.stage >= .discovered }.map(\.id))
        var edges = Set<KnowledgeRelationEdge>()
        for topic in topics where discoveredIds.contains(topic.id) {
            for related in topic.relatedTopicIds where discoveredIds.contains(related) {
                edges.insert(.init(topic.id, related))
            }
        }

        let readiness = LayerCompletionEvaluator.shared.readiness(layerId: notebookViewModel.layerId)
        let missionData = readiness.map {
            IntegratedMissionViewData(
                mission: $0.mission,
                canStart: $0.canStart,
                isCompleted: $0.isCompleted,
                completedPOICount: $0.requiredPOIIds.count - $0.missingPOIIds.count,
                totalPOICount: $0.requiredPOIIds.count,
                appliedTopicCount: $0.mission.requiredTopicIds.count - $0.missingTopicIds.count,
                requiredTopicCount: $0.mission.requiredTopicIds.count)
        }

        return KnowledgeSummaryPageData(
            layerName: notebookViewModel.layerName,
            overview: notebookViewModel.layerOverviewData,
            topics: items,
            selected: detail,
            relationEdges: edges.sorted { ($0.fromId, $0.toId) < ($1.fromId, $1.toId) },
            discoveredCount: items.filter { $0.stage >= .discovered }.count,
            understoodCount: items.filter { $0.stage >= .understood }.count,
            appliedCount: items.filter { $0.stage >= .applied }.count,
            integratedMission: missionData)
    }

    func markRead(topicId: String) {
        progress.markKnowledgeRead(id: topicId)
    }

    func recordUnderstanding(topicId: String) {
        LearningProgressCoordinator.shared.recordUnderstanding(topicId: topicId, score: 100)
    }

    private func makeDetail(topic: KnowledgeTopic) -> KnowledgeTopicDetailData {
        let evidence = topic.evidenceSourceIds.map { evidenceData(sourceId: $0) }
        let nextPOIId = topic.evidenceSourceIds.lazy.compactMap { self.poiId(forEvidenceSource: $0) }.first
        let hint: String
        if let nextPOIId, let poi = content.poi(id: nextPOIId) {
            hint = "前往闯关地图完成“\(poi.title)”，带回一条现场证据。"
        } else {
            hint = "完成与这个专题关联的探索任务后，知识内容会在这里点亮。"
        }
        return .init(
            topic: topic,
            progress: progress.knowledgeProgress(id: topic.id),
            evidence: evidence,
            unlockHint: hint,
            nextPOIId: nextPOIId,
            transferChallenges: content.transferChallenges(
                topicId: topic.id,
                primaryId: topic.transferChallengeId))
    }

    private func evidenceData(sourceId: String) -> KnowledgeEvidenceViewData {
        if let poi = content.poi(id: sourceId) {
            return .init(
                id: sourceId,
                title: poi.title,
                kindLabel: poi.interactionType == .collect ? "采集" : "关卡证据",
                isCollected: progress.isPOIDiscovered(id: sourceId))
        }
        if let collectible = content.collectible(id: sourceId) {
            return .init(
                id: sourceId,
                title: collectible.name,
                kindLabel: "图鉴样本",
                isCollected: progress.isCollected(id: sourceId))
        }
        return .init(id: sourceId, title: "探索记录", kindLabel: "证据", isCollected: false)
    }

    private func poiId(forEvidenceSource sourceId: String) -> String? {
        if content.poi(id: sourceId) != nil { return sourceId }
        return content.pois.first(where: { $0.collectibleId == sourceId })?.id
    }
}
