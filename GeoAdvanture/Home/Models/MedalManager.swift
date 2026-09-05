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

    /// 勋章列表 = 内容层的静态定义（ContentStore）+ 进度层的解锁状态（loadProgress 填充）
    private(set) var medals: [MedalModel] = MedalManager.buildMedals()

    private static func buildMedals() -> [MedalModel] {
        ContentStore.shared.medals.map {
            MedalModel(id: $0.id,
                       name: $0.name,
                       description: $0.description,
                       imageName: $0.imageName,
                       isUnlocked: false)
        }
    }

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
