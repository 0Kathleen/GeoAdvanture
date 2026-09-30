//
//  Untitled.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/8/11.
//
import UIKit
import SpriteKit

class FlashingViewController: UIViewController {

    private var skView: SKView?
    private let startHitButton = UIButton(type: .custom)
    private var didEnterHome = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSKSView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skView?.frame = view.bounds
        // 启动页只有“开始探索”一个动作，整页使用真正的 UIKit Button
        // 承接触摸，彻底避开 SpriteKit 坐标、模拟器缩放和手势竞争问题。
        startHitButton.frame = view.bounds
        view.bringSubviewToFront(startHitButton)
    }
    
    func createSKSView() {
        let skView = SKView(frame: view.bounds)
        view.addSubview(skView)
        self.skView = skView

        startHitButton.backgroundColor = .clear
        startHitButton.accessibilityLabel = "开始探索"
        startHitButton.accessibilityIdentifier = "startExploreButton"
        startHitButton.addTarget(self, action: #selector(startExploreTapped), for: .touchUpInside)
        view.addSubview(startHitButton)
        
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
        guard !didEnterHome else { return }
        didEnterHome = true
        startHitButton.isEnabled = false
        let vc = HomePageViewController()

        if let navigationController {
            // 启动页不是业务页面，进入首页后直接从导航栈移除，避免在视图
            // 尚未完成展示时调用 present 导致跳转被系统忽略。
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.setViewControllers([vc], animated: false)
        } else {
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        }

        // AI 改为首页固定入口与知识页情境入口，不再全局悬浮遮挡关卡操作。
        AIAvatarWindowManager.shared.hide()
    }

    @objc private func startExploreTapped() {
        enterHomePage()
    }
}
