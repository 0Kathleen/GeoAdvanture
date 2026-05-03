//
//  HomePageViewConttroller.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/8/11.
//
import UIKit
import SnapKit
import SpriteKit

protocol HomePageSceneDelegate: AnyObject {
    // 点击进入不同地层笔记本
    func homeSceneDidSelectLayer(index: Int)
    /// 点击进入地心实验室
    func homeSceneDidTapLaboratory()
}

class HomePageViewController:UIViewController{
    private var skView: SKView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        loadHomeScene()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skView?.frame = view.bounds
    }
    
    private func configUI(){
        view.backgroundColor = .black

        let skView = SKView(frame: view.bounds)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        view.addSubview(skView)
        self.skView = skView
    }

    private func loadHomeScene() {
        guard let skView,
              let scene = HomeScene(fileNamed: "HomeScene") else {
            return
        }
        scene.scaleMode = .aspectFill
        scene.HomeDelegate = self
        skView.presentScene(scene, transition: .fade(withDuration: 0.25))
    }
}

extension HomePageViewController: HomePageSceneDelegate {
    func homeSceneDidSelectLayer(index: Int) {
        let vc = NotebookViewController()
        vc.initialEarthLayerIndex = index

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }

        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: vc,
            action: #selector(NotebookViewController.closeTapped)
        )

        present(nav, animated: true)
    }
    
    func homeSceneDidTapLaboratory() {
        let labVC = LaboratoryViewController()
        labVC.modalPresentationStyle = .fullScreen
        labVC.modalTransitionStyle = .crossDissolve
        present(labVC, animated: true)
    }
}
