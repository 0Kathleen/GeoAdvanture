//
//  NotebookContent.swift
//  GeoAdvanture
//

import Foundation
import UIKit

// MARK: - Models
struct NoteModel {
    let id: String
    let title: String
    let content: String
    let imageUrl: String
}

struct NotebookCarouselSlide: Equatable {
    let imageURL: String?
    /// 网络图加载失败时的本地占位图名（如 CarouseImage1）。
    let imageName: String?
    let caption: String
}

/// 介绍页右侧「图文知识卡」一行数据。
struct IntroKnowledgeRow {
    enum Kind: String {
        case feature, life, fun, compare
    }
    let id: String
    let title: String
    let content: String
    let glyph: String
    let kind: Kind
}

struct EarthLayerKnowledge {
    let layerId: String
    let layerIndex: Int
    let title: String
    let tagline: String
    let profile: LayerProfile?
    let carouselSlides: [NotebookCarouselSlide]
    let featureContent: String
    let lifeContent: String
    let funContent: String
    let compareContent: String
    let harvests: [HarvestModel]?

    func introRows(bidPrefix: String) -> [IntroKnowledgeRow] {
        [
            IntroKnowledgeRow(id: bidPrefix + "intro_feat", title: "基本特征", content: featureContent, glyph: "🪨", kind: .feature),
            IntroKnowledgeRow(id: bidPrefix + "intro_life", title: "与生活的联系", content: lifeContent, glyph: "🏠", kind: .life),
            IntroKnowledgeRow(id: bidPrefix + "intro_fun", title: "好玩小知识", content: funContent, glyph: "✨", kind: .fun),
            IntroKnowledgeRow(id: bidPrefix + "intro_cmp", title: "和其他圈层比比看", content: compareContent, glyph: "⚖️", kind: .compare)
        ]
    }
}

// MARK: - Data Source
enum NotebookContent {
    static let bookmarkTitles = ["认识", "闯关地图", "知识总结", "拓展"]

    static func knowledge(forLayer index: Int) -> EarthLayerKnowledge? {
        guard let layerData = NotebookKnowledgeManager.shared.getKnowledge(at: index - 1) else { return nil }
        
        let slides = layerData.carouselSlides.enumerated().map { i, s in
            NotebookCarouselSlide(
                imageURL: s.imageURL,
                imageName: "CarouseImage\(min(i + 1, 3))",
                caption: s.caption
            )
        }

        return EarthLayerKnowledge(
            layerId: layerData.id,
            layerIndex: index,
            title: layerData.title,
            tagline: layerData.tagline,
            profile: layerData.profile,
            carouselSlides: slides,
            featureContent: layerData.featureContent,
            lifeContent: layerData.lifeContent,
            funContent: layerData.funContent,
            compareContent: layerData.compareContent,
            harvests: layerData.harvests
        )
    }
    
    static func introKnowledgeRows(forLayer index: Int, bidPrefix: String) -> [IntroKnowledgeRow] {
        guard let knowledge = knowledge(forLayer: index) else { return [] }
        return knowledge.introRows(bidPrefix: bidPrefix)
    }
}
