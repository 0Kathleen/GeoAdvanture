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
    let imageURL: URL
    let caption: String
}

struct EarthLayerKnowledge {
    let layerIndex: Int
    let title: String
    let tagline: String
    let carouselSlides: [NotebookCarouselSlide]
    let featureContent: String
    let lifeContent: String
    let funContent: String
    let compareContent: String

    func introRows(bidPrefix: String) -> [NoteModel] {
        return [
            NoteModel(id: bidPrefix + "intro_feat", title: "基本特征", content: featureContent, imageUrl: ""),
            NoteModel(id: bidPrefix + "intro_life", title: "与生活的联系", content: lifeContent, imageUrl: ""),
            NoteModel(id: bidPrefix + "intro_fun", title: "好玩小知识", content: funContent, imageUrl: ""),
            NoteModel(id: bidPrefix + "intro_cmp", title: "和其他圈层比比看", content: compareContent, imageUrl: "")
        ]
    }
}

// MARK: - Data Source
enum NotebookContent {
    static let bookmarkTitles = ["认识地壳", "闯关地图", "关卡收获", "拓展园地"]

    static func knowledge(forLayer index: Int) -> EarthLayerKnowledge? {
        guard let layerData = NotebookKnowledgeManager.shared.getKnowledge(at: index - 1) else { return nil }
        
        let slides = layerData.carouselSlides.compactMap { slide -> NotebookCarouselSlide? in
            guard let url = URL(string: slide.imageURL) else { return nil }
            return NotebookCarouselSlide(imageURL: url, caption: slide.caption)
        }
        
        return EarthLayerKnowledge(
            layerIndex: index,
            title: layerData.title,
            tagline: layerData.tagline,
            carouselSlides: slides,
            featureContent: layerData.featureContent,
            lifeContent: layerData.lifeContent,
            funContent: layerData.funContent,
            compareContent: layerData.compareContent
        )
    }
    
    static func kidIntroRows(forLayer index: Int, bidPrefix: String) -> [NoteModel] {
        guard let knowledge = knowledge(forLayer: index) else { return [] }
        return knowledge.introRows(bidPrefix: bidPrefix)
    }
}
