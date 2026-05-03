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
        
        let nodeAtPoint = atPoint(location)
        if nodeAtPoint.name == "LaborButtonNode" {
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
            let notify = SKAction.run { [weak self] in
                self?.HomeDelegate?.homeSceneDidTapLaboratory()
            }
            nodeAtPoint.run(SKAction.sequence([scaleDown, scaleUp, notify]))
            return
        } else if nodeAtPoint.name == "MedalButtonNode" {
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
            let notify = SKAction.run { [weak self] in
                self?.HomeDelegate?.homeSceneDidTapMedal()
            }
            nodeAtPoint.run(SKAction.sequence([scaleDown, scaleUp, notify]))
            return
        }
        
        // 进入笔记本
        guard let (node, index) = layerLabelNode(at: location) else { return }
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(by: 1/1.2, duration: 0.2)
        let notify = SKAction.run { [weak self] in
            self?.HomeDelegate?.homeSceneDidSelectLayer(index: index)
        }
        node.run(SKAction.sequence([scaleUp, scaleDown, notify]))
    }

    private func layerLabelNode(at location: CGPoint) -> (SKNode, Int)? {
        var current: SKNode? = atPoint(location)
        while let n = current {
            if let name = n.name, name.hasPrefix("layerLabelNode") {
                let suffix = name.dropFirst("layerLabelNode".count)
                guard let index = Int(suffix), (1...5).contains(index) else {
                    print("layerLabelNode 后缀无效：\(suffix)")
                    return nil
                }
                return (n, index)
            }
            current = n.parent
        }
        return nil
    }
    
    override func didMove(to view: SKView) {
        setupLaborNode()
        setupMedalNode()
    }
    
    private func setupLaborNode() {
        let laborNode = SKSpriteNode(imageNamed: "LaborButton")
        laborNode.name = "LaborButtonNode"
        laborNode.size = CGSize(width: 60, height: 80)
        let xPos = (self.size.width / 2) - 32 - (laborNode.size.width / 2)
        let yPos = -(self.size.height / 2) + 90 + (laborNode.size.height / 2)
        laborNode.position = CGPoint(x: xPos, y: yPos)
        laborNode.zPosition = 100
        
        let scaleUp = SKAction.scale(to: 1.08, duration: 1.2)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 1.2)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        laborNode.run(SKAction.repeatForever(pulse))
        addChild(laborNode)
    }
    
    private func setupMedalNode() {
        let medalNode = SKSpriteNode(imageNamed: "medalButton")
        medalNode.name = "MedalButtonNode"
        medalNode.size = CGSize(width: 60, height: 80)
        // 放在地心实验室按钮上方
        let xPos = (self.size.width / 2) - 32 - (medalNode.size.width / 2)
        let yPos = -(self.size.height / 2) + 190 + (medalNode.size.height / 2)
        medalNode.position = CGPoint(x: xPos, y: yPos)
        medalNode.zPosition = 100
        
        let scaleUp = SKAction.scale(to: 1.1, duration: 1.5)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 1.5)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        medalNode.run(SKAction.repeatForever(pulse))
        addChild(medalNode)
    }
}
