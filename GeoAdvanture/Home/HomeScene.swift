//
//  HomeScene.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/8/12.
//

import UIKit
import SpriteKit
import GameplayKit


class HomeScene:SKScene{
    
    weak var HomeDelegate: HomePageSceneDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 进入笔记本
        guard let (node, index) = nodes(at: location).lazy.compactMap(layerLabelNode(from:)).first else { return }
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(by: 1/1.2, duration: 0.2)
        let notify = SKAction.run { [weak self] in
            self?.HomeDelegate?.homeSceneDidSelectLayer(index: index)
        }
        node.run(SKAction.sequence([scaleUp, scaleDown, notify]))
    }

    private func layerLabelNode(from hitNode: SKNode) -> (SKNode, Int)? {
        var current: SKNode? = hitNode
        while let n = current {
            if let name = n.name, name.hasPrefix("layerLabelNode") {
                let suffix = name.dropFirst("layerLabelNode".count)
                guard let visualIndex = Int(suffix), (1...5).contains(visualIndex) else {
                    print("layerLabelNode 无效：\(suffix)")
                    return nil
                }
                let notebookIndex: Int
                switch visualIndex {
                case 1: notebookIndex = 1
                case 2, 3: notebookIndex = 2
                default: notebookIndex = 3
                }
                return (n, notebookIndex)
            }
            current = n.parent
        }
        return nil
    }
    
    override func didMove(to view: SKView) {
        // 旧剖面入口由 UIKit 上层的三维圈层舞台取代；保留 .sks 仅作为首页背景。
        hideLegacyEarthEntry()
    }

    private func hideLegacyEarthEntry() {
        let names = [
            "earthNode", "layerLabelNode1", "layerLabelNode2", "layerLabelNode3",
            "layerLabelNode4", "layerLabelNode5", "homeLabel1",
            "Line1", "Line2", "Line3", "Line4", "Line5", "Line6", "Line7", "Line8"
        ]
        names.forEach { childNode(withName: "//\($0)")?.isHidden = true }
    }

    /// 第三个标签仍叫 homeLabel1，运行时补齐名称；外核和内核入口共同进入地核知识本。
    private func repairLegacyLayerNodes() {
        let legacyFourth = childNode(withName: "//layerLabelNode4")
        let legacyFifth = childNode(withName: "//layerLabelNode5")
        legacyFourth?.isHidden = false
        legacyFifth?.isHidden = false

        guard childNode(withName: "//layerLabelNode3") == nil else {
            return
        }
        guard
              let second = childNode(withName: "//layerLabelNode2") as? SKSpriteNode,
              let parent = second.parent else {
            return
        }

        let candidate = parent.children
            .compactMap { $0 as? SKSpriteNode }
            .filter {
                ($0.name?.isEmpty ?? true)
                    && $0.position.y < second.position.y
                    && abs($0.position.x - second.position.x) < max(30, second.size.width * 0.35)
                    && abs($0.size.width - second.size.width) < max(30, second.size.width * 0.35)
            }
            .max { $0.position.y < $1.position.y }
        if let candidate {
            candidate.name = "layerLabelNode3"
        }
    }
}
