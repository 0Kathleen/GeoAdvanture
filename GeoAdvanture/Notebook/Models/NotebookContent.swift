//
//  NotebookContent.swift
//  GeoAdvanture
//

import Foundation

// MARK: - Models
struct EarthLayerKnowledge {
    let layerId: String
    let title: String
    let profile: LayerProfile?
    let harvests: [HarvestModel]?
}

// MARK: - Data Source
enum NotebookContent {
    static let bookmarkTitles = ["认识", "闯关地图", "知识总结", "拓展"]

    static func knowledge(forLayer index: Int) -> EarthLayerKnowledge? {
        guard let layerData = NotebookKnowledgeManager.shared.getKnowledge(at: index - 1) else { return nil }
        
        return EarthLayerKnowledge(
            layerId: layerData.id,
            title: layerData.title,
            profile: layerData.profile,
            harvests: layerData.harvests
        )
    }
}
