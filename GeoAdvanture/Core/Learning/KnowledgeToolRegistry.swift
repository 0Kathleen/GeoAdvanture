//
//  KnowledgeToolRegistry.swift
//  GeoAdvanture
//
//  Step 8：把“会应用”的知识转换成可在后续观察页使用的辅助层。
//

import Foundation

struct KnowledgeToolDefinition: Equatable {
    let id: String
    let topicId: String
    let title: String
    let symbolName: String
    let overlayDescription: String
}

final class KnowledgeToolRegistry {

    static let shared = KnowledgeToolRegistry()

    private let progress = GameProgressManager.shared
    private let content = ContentStore.shared

    private let definitions: [String: KnowledgeToolDefinition] = [
        "tool_plate_boundary_overlay": .init(
            id: "tool_plate_boundary_overlay",
            topicId: "harvest_movement",
            title: "板块方向层",
            symbolName: "arrow.left.and.right.circle.fill",
            overlayDescription: "显示板块靠近、俯冲与分离方向"),
        "tool_rock_composition_overlay": .init(
            id: "tool_rock_composition_overlay",
            topicId: "harvest_rock",
            title: "岩石成因镜",
            symbolName: "circle.hexagongrid.fill",
            overlayDescription: "标出样本与冷却、沉积或变质过程的联系"),
        "tool_fault_overlay": .init(
            id: "tool_fault_overlay",
            topicId: "harvest_crack",
            title: "断层观察层",
            symbolName: "square.split.diagonal.2x2.fill",
            overlayDescription: "标出拉张方向、断层和下陷地块"),
        "tool_mineral_identification": .init(
            id: "tool_mineral_identification",
            topicId: "harvest_diamond",
            title: "矿物鉴定镜",
            symbolName: "diamond.fill",
            overlayDescription: "提示硬度、光泽与条痕等鉴定线索"),
        "tool_volcano_structure_overlay": .init(
            id: "tool_volcano_structure_overlay",
            topicId: "harvest_volcano",
            title: "火山结构层",
            symbolName: "volcano.fill",
            overlayDescription: "标出岩浆房、通道、火山口与喷出物"),
        "tool_magma_cooling_prediction": .init(
            id: "tool_magma_cooling_prediction",
            topicId: "harvest_lava",
            title: "冷却预测器",
            symbolName: "thermometer.medium",
            overlayDescription: "根据位置提示岩浆、熔岩与冷却产物")
    ]

    private init() {}

    func availableTool(topicId: String) -> KnowledgeToolDefinition? {
        guard progress.isKnowledgeApplied(id: topicId),
              let toolId = content.knowledgeTopic(id: topicId)?.knowledgeToolId else { return nil }
        return definitions[toolId]
    }

    func availableTools(evidenceSourceId: String) -> [KnowledgeToolDefinition] {
        content.knowledgeTopics(evidenceSourceId: evidenceSourceId).compactMap { availableTool(topicId: $0.id) }
    }
}
