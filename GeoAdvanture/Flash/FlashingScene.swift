//
//  FlashingViewController.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/8/11.
//

import UIKit
import SpriteKit
import GameplayKit

class FlashingScene:SKScene{

    var startNode: SKSpriteNode?
    var onEnterHomeScene: (() -> Void)?
    
    private lazy var pulseAction: SKAction = {
        let fadeOut = SKAction.fadeAlpha(to: 0.8, duration: 1.2)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        return SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
    }()
        
    private lazy var diamondAction: SKAction = {
        let fadeOut = SKAction.fadeAlpha(to: 0.8, duration: 1.0)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        let scaleUp = SKAction.scale(to: 0.24, duration: 0.4)
        let scaleDown = SKAction.scale(to: 0.23, duration: 0.4)
        let group1 = SKAction.group([fadeOut, scaleUp])
        let group2 = SKAction.group([fadeIn, scaleDown])
        return SKAction.repeatForever(SKAction.sequence([group1, group2]))
    }()
        
    override func didMove(to view: SKView) {
        setupCurrentScene()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let node = nodes(at: location).lazy.compactMap(startExploreNode(from:)).first else { return }
        node.removeAction(forKey: "fadeLoop")
        node.alpha = 1.0
        onEnterHomeScene?()
    }

    /// `.sks` 按钮可能包含图片、文字等子节点；点到任一子节点都应视为点击整个按钮。
    private func startExploreNode(from hitNode: SKNode) -> SKNode? {
        var current: SKNode? = hitNode
        while let node = current {
            if node.name == "startExploreNode" { return node }
            current = node.parent
        }
        return nil
    }
    
    private func setupCurrentScene() {
        if let node = self.childNode(withName: "startExploreNode") {
            startNode = node as? SKSpriteNode
            if !UIAccessibility.isReduceMotionEnabled {
                addFadeAnimation(to: node)
            }
        }
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        // 延迟执行动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.addDimondFadeAnimation()
        }
    }
    
    private func addDimondFadeAnimation() {
        enumerateChildNodes(withName: "//*") { [weak self] node, _ in
            guard let self = self,
                  let nodeName = node.name,
                  nodeName.contains("Dimond") else { return }
            
            let randomDelay = Double.random(in: 0...1.0)
            let delayAction = SKAction.wait(forDuration: randomDelay)
            let sequence = SKAction.sequence([delayAction, self.diamondAction])
            node.run(sequence)
        }
    }
    
    private func addFadeAnimation(to node: SKNode) {
        node.run(pulseAction, withKey: "fadeLoop")
    }
}
