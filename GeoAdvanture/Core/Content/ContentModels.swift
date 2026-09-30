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

/// 「本层小档案」：介绍页顶部的 4 项关键数值（深度/温度/成分/状态）。
struct LayerProfile: Codable {
    let depthRange: String
    let temperature: String
    let composition: String
    let state: String
}

struct LayerKnowledge: Codable {
    let id: String
    let title: String
    let tagline: String
    /// 介绍页「本层小档案」；缺省(nil)时不显示档案卡。
    let profile: LayerProfile?
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

// MARK: - 解锁规则（对应 UnlockRules.json）

/// 单条解锁目标：把「游戏事件」映射到要解锁的内容
struct UnlockTarget: Codable {
    let kind: String   // 对应 UnlockKind: harvest / poi / collectible
    let id: String
}

struct UnlockRule: Codable {
    let event: String
    let unlock: [UnlockTarget]
}

struct UnlockRulesData: Codable {
    let rules: [UnlockRule]
}

// MARK: - 横版探索世界（对应 Worlds.json）

/// 一层「横版世界」的静态定义。世界是容器，POI 是其中的内容。
/// 拓展方式：新增一层只需在 Worlds.json 追加一条 + 在 POIs.json 追加它的 POI，无需改代码。
public struct WorldLayer: Codable {
    let id: String
    /// 下潜顺序（0 基）。层门禁按此顺序派生：index==0 恒开，其余看上一层是否通关。
    let index: Int
    let title: String
    /// 氛围提示词（对应美术色板，见《美术风格与AIGC提示词》），也可给场景做主色。
    let mood: String
    /// 背景资源名前缀（如 bg_crust，实际使用 _far/_mid/_near 三层）。
    let backgroundAsset: String
    /// 世界宽度 = widthScreens × 屏宽，决定横向可走多远。
    let widthScreens: Double
    /// 通关奖励的仪器 id（一期不驱动回访，仅占位；可空）。
    let rewardInstrumentId: String?
    /// 通关条件（可拓展的判定方式）。
    let completionRequirement: CompletionRequirement
    /// 二期占位标记：true 表示该层内容尚未实现，选层页应显示为「敬请期待」并禁止进入。
    /// 可选字段，缺省(nil)视为 false（即一期已实现、可玩）。
    let comingSoon: Bool?
}

extension WorldLayer {
    /// 是否为「敬请期待」的二期占位层。
    var isComingSoon: Bool { comingSoon ?? false }
}

/// 通关条件。用「种类 + 参数」结构，后续可无痛新增判定方式。
struct CompletionRequirement: Codable {
    enum Kind: String, Codable {
        case completePOIs    // 需完成 poiIds 中列出的（operate/关键）POI
        case discoverAllPOIs // 需发现本层所有 POI
    }
    let kind: Kind
    /// completePOIs 用：需要完成的 POI id 列表。
    let poiIds: [String]?
}

// MARK: - 现象点 POI（对应 POIs.json）

/// POI 的交互类型。新增玩法类型时在此扩充即可。
enum POIInteractionType: String, Codable {
    case observe   // 走近即播放现象 + 发现卡
    case inquiry   // 预测→揭晓
    case collect   // 采集入图鉴
    case operate   // 专属小游戏（一期复用现有地壳游戏 / 实验室）
}

/// 散布在世界里的现象点。内容与「解锁/发现状态」分离：状态在 ProgressStore。
struct POI: Codable {
    let id: String
    let worldId: String
    /// 世界内水平位置，取 0...1 的比例（分辨率无关），渲染时 × 世界总宽。
    let x: Double
    let title: String
    let phenomenon: String   // 「发生了什么」
    let explanation: String  // 「为什么」
    let interactionType: POIInteractionType
    /// operate: 子游戏标识；inquiry: 题目 id；其余可空。
    let interactionRef: String?
    /// 需要的仪器 id（拥有前该 POI 隐藏）。一期恒为 null，二期启用回访。
    let requiresInstrument: String?
    /// 采集掉落的图鉴 id（collect 型用）。
    let collectibleId: String?
    /// 发现后要点亮的 harvest id（交给 UnlockRuleEngine 处理）。
    let unlockOnDiscover: [String]?
    let iconAsset: String?
    let illustrationAsset: String?
}

// MARK: - 图鉴藏品（对应 Collectibles.json）

struct Collectible: Codable {
    let id: String
    let name: String
    /// 分类：rock / mineral / fossil / phenomenon …（用字符串，便于新增分类）。
    let category: String
    let image: String
    let worldId: String
    let funFact: String
}

// MARK: - 探测仪器（对应 Instruments.json）

/// 一期仅加载/展示，不驱动回访；二期用 perceptionTag 控制 POI 显隐。
struct Instrument: Codable {
    let id: String
    let name: String
    let icon: String
    let perceptionTag: String
    let funFact: String
}
