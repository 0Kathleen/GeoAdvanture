//
//  CrustMovementViewModel.swift
//  GeoAdvanture
//

import Foundation
import CoreGraphics

/// 板块类型
enum CrustPlateType {
    case oceanic      // 海洋板块：较薄、较重
    case continental  // 大陆板块：较厚、较轻
    
    var displayName: String {
        switch self {
        case .oceanic: return "海洋板块"
        case .continental: return "大陆板块"
        }
    }
}

/// 板块运动方向
enum CrustMovementAction {
    case push   // 挤压（汇聚边界）
    case pull   // 拉伸（离散边界）
    case none
}

/// 演变形成的地貌结果
enum GeologyFormationResult: Equatable {
    case mountain(location: String, description: String)  // 褶皱山脉
    case trench(location: String, description: String)    // 海沟/火山弧
    case rift(location: String, description: String)      // 裂谷/大洋中脊
    case none
}

struct CrustUnlockedScene {
    let id: String
    let title: String
    let description: String
    let location: String
    let imageName: String
    let realImageName: String
    var isUnlocked: Bool = false
}

final class CrustMovementViewModel {
    
    // MARK: - State
    var leftPlateType: CrustPlateType = .continental
    var rightPlateType: CrustPlateType = .oceanic
    
    private let thresholdOffset: CGFloat = 80.0
    
    /// 场景列表 = 内容层的静态定义（ContentStore）+ 进度层的解锁状态（GameProgressManager）
    var unlockedScenes: [CrustUnlockedScene] = CrustMovementViewModel.buildScenes()

    private static func buildScenes() -> [CrustUnlockedScene] {
        ContentStore.shared.crustScenes.map {
            CrustUnlockedScene(id: $0.id,
                               title: $0.title,
                               description: $0.description,
                               location: $0.location,
                               imageName: $0.imageName,
                               realImageName: $0.realImageName,
                               isUnlocked: GameProgressManager.shared.isCrustSceneUnlocked(id: $0.id))
        }
    }
    
    var unlockedCount: Int {
        return unlockedScenes.filter { $0.isUnlocked }.count
    }
    
    func unlockScene(for result: GeologyFormationResult) {
        switch result {
        case .mountain(let location, _):
            if location == "喜马拉雅山脉" { unlockScene(id: "mountain_cc") }
        case .trench(let location, _):
            if location == "安第斯山脉" { unlockScene(id: "trench_oc") }
        case .rift(let location, _):
            if location == "东非大裂谷" { unlockScene(id: "rift_cc") }
            else if location == "大西洋中脊" { unlockScene(id: "rift_oo") }
        case .none: break
        }
    }

    /// 按 id 解锁地壳场景：更新内存状态 + 持久化进度 + 触发解锁规则（连带解锁对应收获）
    private func unlockScene(id: String) {
        if let index = unlockedScenes.firstIndex(where: { $0.id == id }) {
            unlockedScenes[index].isUnlocked = true
        }
        GameProgressManager.shared.unlockCrustScene(id: id)
        UnlockRuleEngine.shared.handle("crust.scene.\(id)")
    }
    
    // MARK: - Logic
    func evaluateMovement(offset: CGFloat) -> GeologyFormationResult {
        let action: CrustMovementAction
        
        if offset <= -thresholdOffset {
            action = .push
        } else if offset >= thresholdOffset {
            action = .pull
        } else {
            action = .none
        }
        
        guard action != .none else { return .none }
        
        // 组合推断
        let plates = [leftPlateType, rightPlateType]
        let hasOceanic = plates.contains(.oceanic)
        let hasContinental = plates.contains(.continental)
        let twoOceanic = (leftPlateType == .oceanic && rightPlateType == .oceanic)
        let twoContinental = (leftPlateType == .continental && rightPlateType == .continental)
        
        switch action {
        case .push:
            if twoContinental {
                // 陆-陆 挤压 -> 褶皱山脉
                return .mountain(location: "喜马拉雅山脉", description: "两个大陆板块相撞，谁也不肯让步，地壳向上隆起形成了高大的褶皱山脉。就像现实中的喜马拉雅山脉！")
            } else if twoOceanic {
                // 海-海 挤压 -> 岛弧/海沟
                return .trench(location: "马里亚纳海沟", description: "两个海洋板块相撞，其中较老、较重的板块俯冲到另一个板块下方，形成了深邃的海沟和岛弧。就像马里亚纳海沟！")
            } else if hasOceanic && hasContinental {
                // 海-陆 挤压 -> 海沟、海岸山脉、火山
                return .trench(location: "安第斯山脉", description: "海洋板块较重，俯冲到大陆板块下方，在海底形成海沟，在陆地上挤压出海岸山脉，还常引发火山喷发。就像南美的安第斯山脉！")
            }
        case .pull:
            if twoContinental {
                // 陆-陆 拉伸 -> 裂谷
                return .rift(location: "东非大裂谷", description: "大陆板块受拉力断裂开来，形成深深的裂谷。就像现实中的东非大裂谷！")
            } else {
                // 海-海 或 含有海洋的拉伸 -> 大洋中脊
                return .rift(location: "大西洋中脊", description: "海底的板块向两边拉开，地下岩浆涌出冷却，形成新的海底和海底山脉（大洋中脊）。")
            }
        case .none:
            return .none
        }
        
        return .none
    }
}
