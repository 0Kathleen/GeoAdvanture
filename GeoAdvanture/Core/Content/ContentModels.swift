//
//  ContentModels.swift
//  GeoAdvanture
//
//  统一的「静态内容」数据模型（只读，随 App 版本发布）。
//  这些模型对应 bundle 内的 JSON 资源，由 ContentStore 统一加载。
//  约定：所有 id 一经发布不可修改、不可复用（内容/进度通过 id 关联）。
//

import Foundation

// MARK: - 圈层知识（对应 NotebookKnowledge.json）

struct NotebookData: Codable {
    let layers: [LayerKnowledge]
}

struct LayerKnowledge: Codable {
    let id: String
    let title: String
    let tagline: String
    let carouselSlides: [CarouselSlideModel]
    let featureContent: String
    let lifeContent: String
    let funContent: String
    let compareContent: String
    let harvests: [HarvestModel]?
}

struct CarouselSlideModel: Codable {
    let imageURL: String
    let caption: String
}

struct HarvestModel: Codable {
    let id: String
    let title: String
    let content: String
    let imageUrl: String
}

// MARK: - 勋章定义（对应 Medals.json）

/// 勋章的静态定义（不含解锁状态；解锁状态由 ProgressStore 管理）
struct MedalDef: Codable {
    let id: String
    let name: String
    let description: String
    let imageName: String
}

// MARK: - 地壳探险场景定义（对应 CrustScenes.json）

/// 地壳场景的静态定义（不含解锁状态；解锁状态由 ProgressStore 管理）
struct CrustSceneDef: Codable {
    let id: String
    let title: String
    let description: String
    let location: String
    let imageName: String
    let realImageName: String
}
