//
//  NotebookLearningModels.swift
//  GeoAdvanture
//
//  知识本改造后的结构化学习内容。
//  静态内容与用户进度分离：本文件只描述“教什么、如何关联”，掌握状态由 ProgressStore 保存。
//

import Foundation

struct NotebookLearningData: Codable {
    let schemaVersion: Int
    let layers: [LayerLearningContent]
    let challengeHubs: [ChallengeHubDefinition]
    let achievementCards: [AchievementCardDefinition]
    let transferChallenges: [TransferChallengeDefinition]
    let integratedMissions: [IntegratedMissionDefinition]
}

struct LayerLearningContent: Codable {
    let layerId: String
    let heroQuestion: String
    let heroSummary: String
    let inquiries: [InquiryTopic]
    let knowledgeTopics: [KnowledgeTopic]
    let integratedMissionId: String?
}

struct InquiryTopic: Codable {
    let id: String
    let title: String
    let predictionPrompt: String
    let explanation: String
    let misconception: String?
    let visualMode: String
    let linkedPOIIds: [String]
    let knowledgeTopicIds: [String]
}

struct KnowledgeTopic: Codable {
    let id: String
    let layerId: String
    let title: String
    let coreQuestion: String
    let causalSteps: [CausalStep]
    let evidenceSourceIds: [String]
    let misconception: String
    let transferChallengeId: String
    let relatedTopicIds: [String]
    let knowledgeToolId: String?
    /// Step 1 兼容旧第三页的结构化卡片；新第三页将直接使用上述专题字段。
    let summaryCards: [KnowledgeSummaryCardContent]
}

struct CausalStep: Codable {
    let id: String
    let text: String
}

struct KnowledgeSummaryCardContent: Codable {
    let title: String
    let content: String
}

struct ChallengeHubDefinition: Codable {
    let id: String
    let poiId: String
    let title: String
    let sceneKind: String
    let taskIds: [String]
    let modelAsset: String?
    let supportsAR: Bool
    /// 观察类二级页的有效现场任务；采集和 operate 类由各自小游戏负责。
    let fieldTask: FieldTaskDefinition?
}

struct FieldTaskDefinition: Codable {
    let id: String
    let kind: TransferChallengeKind
    let prompt: String
    let options: [TransferChallengeOption]
    let correctOptionIds: [String]
    let explanation: String
    let observationId: String
}

/// 关卡向二级页上报的稳定结果。Step 6 的统一成就卡直接消费此结构。
struct ChallengeResult: Codable, Equatable {
    let challengeId: String
    let completedTaskIds: [String]
    let observationIds: [String]
    let earnedArtifactIds: [String]
    let score: Int
}

/// Step 6 成就卡的只读内容。游戏只上报 ID 与分数，展示文案和美术映射集中维护。
struct AchievementCardDefinition: Codable {
    let id: String
    let challengeId: String
    /// 单项成就对应任务；总成就使用 nil，并由二级页在全部任务完成时指定。
    let taskId: String?
    let title: String
    let subtitle: String
    let actionSummary: String
    let observationSummary: String
    let rewardTitle: String
    let rewardDescription: String
    let artworkAsset: String?
    let symbolName: String
    let knowledgeTopicId: String
}

enum TransferChallengeKind: String, Codable {
    case causalOrder
    case singleChoice
    case hotspot
    case classification
}

struct TransferChallengeDefinition: Codable {
    let id: String
    let topicId: String
    let kind: TransferChallengeKind
    let prompt: String
    let options: [TransferChallengeOption]
    let correctOptionIds: [String]
    let explanation: String
}

struct TransferChallengeOption: Codable {
    let id: String
    let text: String
}

struct IntegratedMissionDefinition: Codable {
    let id: String
    let layerId: String
    let title: String
    let requiredTopicIds: [String]
    let steps: [IntegratedMissionStep]
}

struct IntegratedMissionStep: Codable {
    let id: String
    let prompt: String
    let topicIds: [String]
    let kind: TransferChallengeKind
    let options: [TransferChallengeOption]
    let correctOptionIds: [String]
    let explanation: String
}
