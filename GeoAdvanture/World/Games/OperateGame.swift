//
//  OperateGame.swift
//  GeoAdvanture
//
//  operate 型 POI 的小游戏「契约 + 启动器」。
//  设计：POI.interactionRef 是数据里的游戏标识，启动器据此产出对应游戏 VC，
//  游戏结束用统一回调把 (成功/星级) 报回世界层，由世界层判定 POI 完成与层通关。
//  拓展：二期新增游戏，只在这里加一个 case + 一个新 VC，World 其余代码不动。
//

import UIKit

/// 小游戏结束回调。
protocol OperateGameDelegate: AnyObject {
    /// - Parameters:
    ///   - poiId: 关联的 POI id
    ///   - success: 是否达成目标
    ///   - stars: 0...3 星（成功时有效）
    func operateGameDidFinish(poiId: String, success: Bool, stars: Int)
}

/// 所有 operate 小游戏 VC 的统一入口。
protocol OperateGameViewController: UIViewController {
    init(poi: POI, delegate: OperateGameDelegate)
}

enum OperatePOILauncher {

    /// 按 POI.interactionRef 产出对应游戏；未实现（二期）返回 nil。
    static func makeViewController(for poi: POI, delegate: OperateGameDelegate) -> UIViewController? {
        switch poi.interactionRef {
        case "game_crust_movement":
            return PlateWorkshopViewController(poi: poi, delegate: delegate)
        case "lab_experiment":
            return DeepDiveLabViewController(poi: poi, delegate: delegate)
        // 二期：game_geodynamo / game_magstorm / game_seismic_scan
        default:
            return nil
        }
    }

    /// 该 operate POI 的小游戏是否已在本期实现（用于 UI 文案/禁用）。
    static func isImplemented(_ poi: POI) -> Bool {
        makeInteractionRefImplemented(poi.interactionRef)
    }

    private static func makeInteractionRefImplemented(_ ref: String?) -> Bool {
        switch ref {
        case "game_crust_movement", "lab_experiment": return true
        default: return false
        }
    }
}
