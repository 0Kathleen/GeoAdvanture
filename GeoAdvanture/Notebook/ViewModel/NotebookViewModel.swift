//
//  NotebookViewModel.swift
//  GeoAdvanture
//
//  负责对 NotebookContent 提供的数据进行二次处理与组装，为各个子页面提供渲染所需的干净数据结构。
//

import Foundation

// MARK: - View Data Structs

struct NotebookInquiryViewData {
    let topic: InquiryTopic
    let discoveredCount: Int
    let totalCount: Int
    let nextPOIId: String?

    var isCompleted: Bool { totalCount > 0 && discoveredCount == totalCount }
}

struct LayerOverviewBranchViewData {
    let title: String
    let detail: String
    let systemImage: String
}

struct LayerOverviewViewData {
    let layerName: String
    let position: String
    let definition: String
    let branches: [LayerOverviewBranchViewData]
}

struct NotebookLearningIntroViewData {
    let layerId: String
    let layerName: String
    let profile: LayerProfile?
    let overview: LayerOverviewViewData
    let discoveredCount: Int
    let totalCount: Int
    let inquiries: [NotebookInquiryViewData]
}

// MARK: - ViewModel

class NotebookViewModel {
    
    private let layerIndex: Int
    
    init(layerIndex: Int) {
        self.layerIndex = layerIndex
    }
    
    private var knowledge: EarthLayerKnowledge? {
        NotebookContent.knowledge(forLayer: layerIndex)
    }
    
    var layerName: String {
        knowledge?.title ?? "—"
    }

    var layerId: String {
        knowledge?.layerId ?? "crust"
    }

    /// 当前层的 1 基下标（1=地壳，2=地幔，3=地核）。
    var layerNumber: Int { layerIndex }

    /// 本层是否已有可玩的闯关地图（一期仅地壳）。其余层显示「建设中」占位。
    var hasLevelMap: Bool { layerIndex == 1 }

    /// 本层是否配置了知识点（收获）。地幔/地核一期为空，用占位提示。
    var hasHarvests: Bool { !(knowledge?.harvests?.isEmpty ?? true) }

    var layerOverviewData: LayerOverviewViewData {
        switch layerId {
        case "mantle":
            return LayerOverviewViewData(
                layerName: layerName,
                position: "地壳与地核之间",
                definition: "地幔是地球内部最厚的一层，主要由高温岩石组成，并能在漫长时间里缓慢变形。",
                branches: [
                    .init(title: "组成", detail: "硅酸盐岩石", systemImage: "cube.fill"),
                    .init(title: "变化", detail: "缓慢对流", systemImage: "arrow.triangle.2.circlepath"),
                    .init(title: "影响", detail: "推动板块", systemImage: "mountain.2.fill")
                ])
        case "core", "outer_core", "inner_core":
            return LayerOverviewViewData(
                layerName: layerName,
                position: "地球最中心",
                definition: "地核是以铁、镍为主的金属核心，液态外核与固态内核共同构成地球深处的心脏。",
                branches: [
                    .init(title: "组成", detail: "铁与镍", systemImage: "circle.hexagongrid.fill"),
                    .init(title: "状态", detail: "外液内固", systemImage: "circle.lefthalf.filled"),
                    .init(title: "作用", detail: "产生磁场", systemImage: "shield.lefthalf.filled")
                ])
        default:
            return LayerOverviewViewData(
                layerName: layerName,
                position: "地球最外层",
                definition: "地壳是包裹地球的坚硬岩石外壳，也是我们生活、寻找资源和观察地质变化的地方。",
                branches: [
                    .init(title: "材料", detail: "岩石与矿物", systemImage: "cube.transparent.fill"),
                    .init(title: "运动", detail: "板块移动", systemImage: "arrow.left.and.right"),
                    .init(title: "表现", detail: "地貌与火山", systemImage: "mountain.2.fill")
                ])
        }
    }

    func fetchLearningIntroData() -> NotebookLearningIntroViewData? {
        guard let layer = ContentStore.shared.learningLayer(id: layerId) else { return nil }
        let progress = GameProgressManager.shared
        let inquiryRows = layer.inquiries.map { inquiry -> NotebookInquiryViewData in
            let discovered = inquiry.knowledgeTopicIds.filter {
                progress.isKnowledgeDiscovered(id: $0)
            }
            let nextIndex = inquiry.knowledgeTopicIds.firstIndex {
                !progress.isKnowledgeDiscovered(id: $0)
            }
            let nextPOIId = nextIndex.flatMap { index in
                inquiry.linkedPOIIds.indices.contains(index) ? inquiry.linkedPOIIds[index] : nil
            } ?? inquiry.linkedPOIIds.first

            return NotebookInquiryViewData(
                topic: inquiry,
                discoveredCount: discovered.count,
                totalCount: inquiry.knowledgeTopicIds.count,
                nextPOIId: nextPOIId)
        }
        let allTopicIds = Array(Set(layer.inquiries.flatMap(\.knowledgeTopicIds)))
        let discoveredCount = allTopicIds.filter { progress.isKnowledgeDiscovered(id: $0) }.count
        return NotebookLearningIntroViewData(
            layerId: layer.layerId,
            layerName: layerName,
            profile: knowledge?.profile,
            overview: layerOverviewData,
            discoveredCount: discoveredCount,
            totalCount: allTopicIds.count,
            inquiries: inquiryRows)
    }
}
