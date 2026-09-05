//
//  ContentStore.swift
//  GeoAdvanture
//
//  全项目「静态内容」的唯一加载入口（Single Source of Truth）。
//  只负责从 bundle 内的 JSON 读取只读内容；用户进度请走 ProgressStore。
//

import Foundation

final class ContentStore {

    static let shared = ContentStore()

    /// 圈层知识（地壳 / 地幔 / 地核）
    let layers: [LayerKnowledge]
    /// 勋章定义
    let medals: [MedalDef]
    /// 地壳探险场景定义
    let crustScenes: [CrustSceneDef]

    private init() {
        layers = Self.decode(NotebookData.self, from: "NotebookKnowledge")?.layers ?? []
        medals = Self.decode([MedalDef].self, from: "Medals") ?? []
        crustScenes = Self.decode([CrustSceneDef].self, from: "CrustScenes") ?? []
        print("✅ ContentStore 加载完成：圈层 \(layers.count) / 勋章 \(medals.count) / 地壳场景 \(crustScenes.count)")
    }

    // MARK: - 查询便捷方法

    func layer(id: String) -> LayerKnowledge? {
        layers.first { $0.id == id }
    }

    /// 按 0 基下标取圈层
    func layer(at index: Int) -> LayerKnowledge? {
        layers.indices.contains(index) ? layers[index] : nil
    }

    func medal(id: String) -> MedalDef? {
        medals.first { $0.id == id }
    }

    func crustScene(id: String) -> CrustSceneDef? {
        crustScenes.first { $0.id == id }
    }

    /// 所有收获 id（用于 starter 解锁、对账、开发期校验）
    var allHarvestIds: [String] {
        layers.flatMap { $0.harvests ?? [] }.map { $0.id }
    }

    /// 所有内容 id 的并集（用于开发期悬空引用校验、进度对账）
    var allContentIds: Set<String> {
        var ids = Set<String>()
        ids.formUnion(layers.map { $0.id })
        ids.formUnion(allHarvestIds)
        ids.formUnion(medals.map { $0.id })
        ids.formUnion(crustScenes.map { $0.id })
        return ids
    }

    // MARK: - 解码

    private static func decode<T: Decodable>(_ type: T.Type, from resource: String) -> T? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            print("⚠️ ContentStore：找不到资源 \(resource).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ ContentStore：解析 \(resource).json 失败: \(error)")
            return nil
        }
    }
}
