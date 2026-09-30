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
    // 点击进入不同地层笔记本（地壳 / 地幔 / 地核）
    func homeSceneDidSelectLayer(index: Int)
}

class HomePageViewController:UIViewController{
    private var skView: SKView?
    private let earthLayerStage = HomeEarthLayerStageView()
    private let resetModelsButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "arrow.counterclockwise")
        configuration.baseForegroundColor = GeoTheme.Color.mauve
        configuration.baseBackgroundColor = GeoTheme.Color.paper.withAlphaComponent(0.92)
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 9, bottom: 9, trailing: 9)
        button.configuration = configuration
        GeoTheme.applyFloatingShadow(to: button)
        button.alpha = 0
        button.isEnabled = false
        button.accessibilityLabel = "让地球圈层归位"
        return button
    }()
    private let atlasButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = GeoTheme.buttonConfiguration(
            title: "地质博物馆",
            systemImage: "building.columns.fill",
            style: .paper)
        GeoTheme.applyFloatingShadow(to: button)
        button.accessibilityLabel = "打开地质博物馆"
        return button
    }()
    private let aiButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = GeoTheme.buttonConfiguration(
            title: "问岩小探",
            systemImage: "sparkles",
            style: .paper)
        configuration.baseForegroundColor = GeoTheme.Color.mauve
        configuration.baseBackgroundColor = GeoTheme.Color.blushControl
        configuration.background.strokeColor = GeoTheme.Color.mauve.withAlphaComponent(0.20)
        configuration.background.strokeWidth = 1
        button.configuration = configuration
        GeoTheme.applyFloatingShadow(to: button)
        button.accessibilityLabel = "向岩小探提问"
        return button
    }()
    
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
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsDrawCount = false
        view.addSubview(skView)
        self.skView = skView

        view.addSubview(earthLayerStage)
        earthLayerStage.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        earthLayerStage.onOpenLayer = { [weak self] index in
            self?.homeSceneDidSelectLayer(index: index)
        }
        earthLayerStage.onExpandedChanged = { [weak self] expanded in
            guard let self else { return }
            self.resetModelsButton.isEnabled = expanded
            UIView.animate(withDuration: 0.22) {
                self.resetModelsButton.alpha = expanded ? 1 : 0
            }
        }

        view.addSubview(atlasButton)
        view.addSubview(aiButton)
        view.addSubview(resetModelsButton)
        atlasButton.addTarget(self, action: #selector(openAtlas), for: .touchUpInside)
        aiButton.addTarget(self, action: #selector(openAI), for: .touchUpInside)
        resetModelsButton.addTarget(self, action: #selector(resetModels), for: .touchUpInside)
        atlasButton.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.equalTo(150)
            make.height.equalTo(46)
        }
        aiButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.bottom.equalTo(atlasButton)
            make.width.equalTo(132)
            make.height.equalTo(atlasButton)
        }
        resetModelsButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(22)
            make.width.height.equalTo(40)
        }
    }

    @objc private func resetModels() {
        earthLayerStage.reset()
    }

    @objc private func openAtlas() {
        let atlas = NotebookAtlasViewController()
        atlas.view.backgroundColor = UIColor(red: 0.94, green: 0.89, blue: 0.79, alpha: 1)
        atlas.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: atlas,
            action: #selector(NotebookAtlasViewController.closeTapped))
        let navigation = UINavigationController(rootViewController: atlas)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }

    @objc private func openAI() {
        let chat = ChatViewController()
        chat.contextPrompt = "当前在《地心奇境》首页。请先询问孩子想了解地壳、地幔、地核，还是刚刚获得的地质收藏。"
        chat.modalPresentationStyle = .fullScreen
        chat.modalTransitionStyle = .crossDissolve
        present(chat, animated: true)
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
        guard LayerCompletionEvaluator.shared.canOpenNotebook(layerNumber: index) else {
            let alert = UIAlertController(
                title: "这一层还没有解锁",
                message: LayerCompletionEvaluator.shared.notebookUnlockHint(layerNumber: index),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            present(alert, animated: true)
            return
        }
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
}
