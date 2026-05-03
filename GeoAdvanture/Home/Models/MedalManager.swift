//
//  MedalManager.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import Foundation

public struct MedalModel {
    let id: String
    let name: String
    let description: String
    let imageName: String
    var isUnlocked: Bool
}

public class MedalManager {
    public static let shared = MedalManager()
    
    private(set) var medals: [MedalModel] = [
        MedalModel(id: "diligence", name: "初出茅庐", description: "第一次踏上神奇的地质探索之旅。", imageName: "medal_diligence", isUnlocked: false),
        MedalModel(id: "core_explorer", name: "地心探索者", description: "在极端环境下成功将样本送达地心结晶。", imageName: "medal_core", isUnlocked: false),
        MedalModel(id: "crust_master", name: "造物主", description: "在地壳探险中解锁所有板块运动形成的奇妙地形。", imageName: "medal_crust", isUnlocked: false),
        MedalModel(id: "curious_mind", name: "好奇宝宝", description: "勇敢尝试地心实验室的不同参数，虽然失败但积累了经验。", imageName: "medal_curious", isUnlocked: false),
        MedalModel(id: "knowledge_seeker", name: "求知若渴", description: "翻开地质笔记本，主动汲取地球科学知识。", imageName: "medal_knowledge", isUnlocked: false)
    ]
    
    private var currentLevelId: String?
    
    private init() {
        loadProgress()
        
        // 监听学习事件以解锁奖章
        NotificationCenter.default.addObserver(self, selector: #selector(handleAction(_:)), name: LearningEventBus.actionDidOccurNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleContext(_:)), name: LearningEventBus.contextDidChangeNotification, object: nil)
    }
    
    @objc private func handleContext(_ notification: Notification) {
        guard let context = notification.userInfo?["context"] as? LevelContext else { return }
        currentLevelId = context.levelId
    }
    
    private func loadProgress() {
        for i in 0..<medals.count {
            let isUnlocked = GameProgressManager.shared.isMedalUnlocked(id: medals[i].id)
            medals[i].isUnlocked = isUnlocked
        }
    }
    
    public func unlockMedal(withId id: String) {
        guard let index = medals.firstIndex(where: { $0.id == id }), !medals[index].isUnlocked else {
            return
        }
        
        medals[index].isUnlocked = true
        GameProgressManager.shared.unlockMedal(id: id)
        
        // 可以加上一个全局通知来展示获得了新奖章的弹窗
        print("🎉 解锁新奖章: \(medals[index].name)")
    }
    
    @objc private func handleAction(_ notification: Notification) {
        guard let action = notification.userInfo?["action"] as? LearningAction else { return }
        
        switch action.type {
        case .enterPage:
            // 随便进一个页面就解锁初出茅庐
            unlockMedal(withId: "diligence")
            
            // 检查是否进入了笔记本
            if currentLevelId == "notebook" || currentLevelId?.hasPrefix("notebook") == true {
                unlockMedal(withId: "knowledge_seeker")
            }
            
        case .success(let source, let target, _):
            if source == "实验室" && target == "成功抵达地心" {
                unlockMedal(withId: "core_explorer")
            } else if source == "地壳探险" && target == "解锁全场景" {
                unlockMedal(withId: "crust_master")
            }
            
        case .error(let source, _, _):
            if source == "实验室" {
                unlockMedal(withId: "curious_mind")
            }
            
        default:
            break
        }
    }
}
