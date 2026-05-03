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
    
    var unlockedScenes: [CrustUnlockedScene] = [
        CrustUnlockedScene(id: "mountain_cc", title: "陆陆碰撞", description: "两个大陆板块相撞，谁也不肯让步，地壳向上隆起形成了高大的褶皱山脉。", location: "喜马拉雅山脉", imageName: "scene_mountain_cc", realImageName: "real_mountain_cc", isUnlocked: GameProgressManager.shared.isCrustSceneUnlocked(id: "mountain_cc")),
        CrustUnlockedScene(id: "trench_oc", title: "海陆碰撞", description: "海洋板块较重，俯冲到大陆板块下方，在海底形成海沟，在陆地上挤压出海岸山脉。", location: "安第斯山脉", imageName: "scene_trench_oc", realImageName: "real_trench_oc", isUnlocked: GameProgressManager.shared.isCrustSceneUnlocked(id: "trench_oc")),
        CrustUnlockedScene(id: "rift_cc", title: "陆陆拉伸", description: "大陆板块受拉力断裂开来，形成深深的裂谷。", location: "东非大裂谷", imageName: "scene_rift_cc", realImageName: "real_rift_cc", isUnlocked: GameProgressManager.shared.isCrustSceneUnlocked(id: "rift_cc")),
        CrustUnlockedScene(id: "rift_oo", title: "海海拉伸", description: "海底的板块向两边拉开，地下岩浆涌出冷却，形成新的海底和海底山脉。", location: "大西洋中脊", imageName: "scene_rift_oo", realImageName: "real_rift_oo", isUnlocked: GameProgressManager.shared.isCrustSceneUnlocked(id: "rift_oo"))
    ]
    
    var unlockedCount: Int {
        return unlockedScenes.filter { $0.isUnlocked }.count
    }
    
    func unlockScene(for result: GeologyFormationResult) {
        switch result {
        case .mountain(let location, _):
            if location == "喜马拉雅山脉" { 
                unlockedScenes[0].isUnlocked = true
                GameProgressManager.shared.unlockCrustScene(id: unlockedScenes[0].id)
            }
        case .trench(let location, _):
            if location == "安第斯山脉" { 
                unlockedScenes[1].isUnlocked = true
                GameProgressManager.shared.unlockCrustScene(id: unlockedScenes[1].id)
            }
        case .rift(let location, _):
            if location == "东非大裂谷" { 
                unlockedScenes[2].isUnlocked = true
                GameProgressManager.shared.unlockCrustScene(id: unlockedScenes[2].id)
            }
            else if location == "大西洋中脊" { 
                unlockedScenes[3].isUnlocked = true
                GameProgressManager.shared.unlockCrustScene(id: unlockedScenes[3].id)
            }
        case .none: break
        }
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
