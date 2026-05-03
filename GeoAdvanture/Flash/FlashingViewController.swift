//
//  Untitled.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/8/11.
//
import UIKit
import SpriteKit

class FlashingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSKSView()
    }
    
    func createSKSView() {
        let skView = SKView(frame: view.bounds)
        view.addSubview(skView)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsDrawCount = false

        DispatchQueue.global(qos: .userInitiated).async {
            let atlas = SKTextureAtlas(named: "FlashingAtlas")
            let start = CFAbsoluteTimeGetCurrent()
            atlas.preload {
                let cost = CFAbsoluteTimeGetCurrent() - start
                print("🟢 Atlas 解码耗时：\(cost)")
                DispatchQueue.main.async {
                    self.loadScene(into: skView)
                }
            }
        }
    }

    func loadScene(into skView: SKView) {
        let sceneStart = CFAbsoluteTimeGetCurrent()
        
        guard let scene = FlashingScene(fileNamed: "FlashingScene") else { return }
        scene.scaleMode = .aspectFill
        scene.onEnterHomeScene = { [weak self] in
            self?.enterHomePage()
        }
        skView.presentScene(scene)

        let end = CFAbsoluteTimeGetCurrent()
        print("🎬 Scene 创建耗时：\(end - sceneStart)")
    }

    private func enterHomePage() {
        let vc = HomePageViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
}
