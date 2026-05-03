import Foundation

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

class NotebookKnowledgeManager {
    static let shared = NotebookKnowledgeManager()
    
    private(set) var layers: [LayerKnowledge] = []
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        guard let url = Bundle.main.url(forResource: "NotebookKnowledge", withExtension: "json") else {
            print("找不到 NotebookKnowledge.json 文件")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let notebookData = try decoder.decode(NotebookData.self, from: data)
            self.layers = notebookData.layers
            print("✅ 知识点加载成功，共 \(layers.count) 条数据")
        } catch {
            print("❌ JSON 解析失败: \(error)")
        }
    }
    
    func getKnowledge(by id: String) -> LayerKnowledge? {
        return layers.first { $0.id == id }
    }
    
    func getKnowledge(at index: Int) -> LayerKnowledge? {
        guard index >= 0 && index < layers.count else { return nil }
        return layers[index]
    }
}
