//
//  WorldViewModel.swift
//  GeoAdvanture
//
//  横版世界的 ViewModel：从 ContentStore 读取该层的静态定义，向 View 提供渲染所需数据。
//  不持有任何 UIKit/SpriteKit 对象，保持 View 与数据解耦。
//

import CoreGraphics

final class WorldViewModel {

    let world: WorldLayer

    init?(worldId: String) {
        guard let w = ContentStore.shared.world(id: worldId) else {
            print("⚠️ WorldViewModel：找不到世界 \(worldId)")
            return nil
        }
        world = w
    }

    var worldId: String { world.id }
    var title: String { world.title }

    /// 世界宽度占多少屏。
    var widthScreens: CGFloat { CGFloat(world.widthScreens) }

    /// 顶部 HUD 展示的深度文案（占位，可后续按真实深度映射）。
    var depthText: String {
        switch world.id {
        case "crust": return "0–35 km"
        case "mantle": return "35–2900 km"
        case "outer_core": return "2900–5100 km"
        case "inner_core": return "5100–6371 km"
        default: return ""
        }
    }

    /// 占位配色。
    var palette: WorldPalette { WorldPalette.forWorld(world.id) }

    /// 本层 POI（按 x 从左到右）。
    var pois: [POI] { ContentStore.shared.pois(worldId: world.id) }

    /// 本层「当前可见」的 POI：需要仪器且尚未获得者隐藏（一期地壳/地幔均无仪器门槛，全部可见；为二期回访预留）。
    var visiblePOIs: [POI] {
        let gm = GameProgressManager.shared
        return pois.filter { poi in
            guard let req = poi.requiresInstrument else { return true }
            return gm.hasInstrument(id: req)
        }
    }

    // MARK: - 发现 / 采集（写进度 → CoreData，冷启动保留）

    private var gm: GameProgressManager { .shared }

    func isDiscovered(_ poi: POI) -> Bool { gm.isPOIDiscovered(id: poi.id) }

    func isCollected(_ poi: POI) -> Bool {
        guard let cid = poi.collectibleId else { return false }
        return gm.isCollected(id: cid)
    }

    /// 打开发现卡即视为「已发现」：记录 POI 发现态并派发事件（供 UnlockRuleEngine 点亮关联收获）。
    func markDiscovered(_ poi: POI) {
        guard !gm.isPOIDiscovered(id: poi.id) else { return }
        gm.markPOIDiscovered(id: poi.id)
        UnlockRuleEngine.shared.handle("poi.discover.\(poi.id)")
    }

    /// 采集 collect 型 POI 的藏品：写图鉴 + 派发事件。
    func collect(_ poi: POI) {
        guard let cid = poi.collectibleId else { return }
        gm.collect(id: cid)
        UnlockRuleEngine.shared.handle("collectible.get.\(cid)")
    }
}
