import Foundation

/// 圈层知识的访问入口。
/// 说明：数据模型（LayerKnowledge / HarvestModel / CarouselSlideModel）与实际加载
/// 已统一收敛到 `ContentModels.swift` 与 `ContentStore`；此类仅作为兼容旧调用点的薄壳。
class NotebookKnowledgeManager {
    static let shared = NotebookKnowledgeManager()

    private init() {}

    var layers: [LayerKnowledge] {
        ContentStore.shared.layers
    }

    func getKnowledge(by id: String) -> LayerKnowledge? {
        ContentStore.shared.layer(id: id)
    }

    func getKnowledge(at index: Int) -> LayerKnowledge? {
        ContentStore.shared.layer(at: index)
    }
}
