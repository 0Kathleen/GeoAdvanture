//
//  WorldViewController.swift
//  GeoAdvanture
//
//  横版世界页（PR-2）：承载 WorldScene 的 SKView + 顶部 HUD + 底部左右移动按钮。
//  入口：DEBUG 调试台 / 首页「开始下潜」，以 fullScreen 方式 present。
//

import UIKit
import SpriteKit
import SnapKit

final class WorldViewController: UIViewController {

    private let viewModel: WorldViewModel
    private let skView = SKView()
    private var scene: WorldScene?
    private var didPresentScene = false

    // HUD
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let collectionButton = UIButton(type: .system)
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    private let climbUpButton = UIButton(type: .system)
    private let climbDownButton = UIButton(type: .system)
    private let interactButton = UIButton(type: .system)

    /// 当前靠近、可交互的 POI（由场景回调驱动）。
    private var nearbyPOI: POI?

    /// 走到出口且本层已通关、下一层可进入时回调(由选层页装配),参数为当前层 id。
    /// 选层页据此关闭当前世界并打开下一层,形成下潜闭环。
    var onRequestDescend: ((_ fromWorldId: String) -> Void)?

    init?(worldId: String) {
        guard let vm = WorldViewModel(worldId: worldId) else { return nil }
        viewModel = vm
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSKView()
        setupHUD()
        setupMoveControls()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skView.frame = view.bounds
        // 首帧拿到正确尺寸后再呈现场景，保证世界宽度/相机计算正确
        if !didPresentScene, view.bounds.width > 0 {
            didPresentScene = true
            let scene = WorldScene(size: view.bounds.size, viewModel: viewModel)
            scene.onReachExit = { [weak self] in self?.handleReachExit() }
            scene.onNearbyPOIChanged = { [weak self] poi in self?.updateNearbyPOI(poi) }
            skView.presentScene(scene)
            self.scene = scene
        }
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - 构建

    private func setupSKView() {
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        view.addSubview(skView)
    }

    private func setupHUD() {
        // 返回
        backButton.setTitle("‹ 返回", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        backButton.layer.cornerRadius = 16
        backButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(backButton)

        // 层名 + 深度
        titleLabel.text = "\(viewModel.title)   \(viewModel.depthText)"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.5
        titleLabel.layer.shadowRadius = 3
        titleLabel.layer.shadowOffset = .zero
        view.addSubview(titleLabel)

        // 图鉴入口（占位，PR-4 接）
        collectionButton.setTitle("图鉴", for: .normal)
        collectionButton.setTitleColor(.white, for: .normal)
        collectionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        collectionButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        collectionButton.layer.cornerRadius = 16
        collectionButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        collectionButton.addTarget(self, action: #selector(collectionTapped), for: .touchUpInside)
        view.addSubview(collectionButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(34)
        }
        collectionButton.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(collectionButton.snp.leading).offset(-8)
        }
    }

    private func setupMoveControls() {
        configureMoveButton(leftButton, title: "◀")
        configureMoveButton(rightButton, title: "▶")
        view.addSubview(leftButton)
        view.addSubview(rightButton)

        leftButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-28)
            make.width.height.equalTo(76)
        }
        rightButton.snp.makeConstraints { make in
            make.leading.equalTo(leftButton.snp.trailing).offset(20)
            make.centerY.equalTo(leftButton)
            make.width.height.equalTo(76)
        }

        // 按住移动、松开停止
        leftButton.addTarget(self, action: #selector(moveLeftDown), for: .touchDown)
        rightButton.addTarget(self, action: #selector(moveRightDown), for: .touchDown)
        for b in [leftButton, rightButton] {
            b.addTarget(self, action: #selector(moveEnd), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }

        // 攀爬（点按触发，在平台衔接处生效）
        configureMoveButton(climbUpButton, title: "▲")
        configureMoveButton(climbDownButton, title: "▼")
        view.addSubview(climbUpButton)
        view.addSubview(climbDownButton)

        climbDownButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-28)
            make.width.height.equalTo(76)
        }
        climbUpButton.snp.makeConstraints { make in
            make.trailing.equalTo(climbDownButton.snp.leading).offset(-20)
            make.centerY.equalTo(climbDownButton)
            make.width.height.equalTo(76)
        }
        climbUpButton.addTarget(self, action: #selector(climbUpTapped), for: .touchUpInside)
        climbDownButton.addTarget(self, action: #selector(climbDownTapped), for: .touchUpInside)

        // 互动按钮（靠近 POI 时才出现）
        interactButton.setTitle("探索", for: .normal)
        interactButton.setTitleColor(.white, for: .normal)
        interactButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        interactButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        interactButton.layer.cornerRadius = 44
        interactButton.isHidden = true
        view.addSubview(interactButton)
        interactButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.width.height.equalTo(88)
        }
        interactButton.addTarget(self, action: #selector(interactTapped), for: .touchUpInside)
    }

    private func configureMoveButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 30, weight: .bold)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 38
    }

    // MARK: - 交互

    @objc private func moveLeftDown() { scene?.startMoving(-1) }
    @objc private func moveRightDown() { scene?.startMoving(1) }
    @objc private func moveEnd() { scene?.stopMoving() }

    @objc private func climbUpTapped() { scene?.tryClimbUp() }
    @objc private func climbDownTapped() { scene?.tryClimbDown() }

    @objc private func closeTapped() { dismiss(animated: true) }

    @objc private func collectionTapped() {
        let nav = UINavigationController(rootViewController: CollectionViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - POI 交互

    /// 场景回调：靠近/离开可交互 POI 时更新互动按钮。
    private func updateNearbyPOI(_ poi: POI?) {
        nearbyPOI = poi
        interactButton.isHidden = (poi == nil)
    }

    @objc private func interactTapped() {
        guard let poi = nearbyPOI else { return }
        presentDiscoveryCard(for: poi)
    }

    private func presentDiscoveryCard(for poi: POI) {
        // observe/inquiry/collect：打开卡即记为「已发现」；operate：发现在小游戏成功后再记。
        if poi.interactionType != .operate {
            viewModel.markDiscovered(poi)
            scene?.refreshPOIState(poi.id)
        }

        let collected = viewModel.isCollected(poi)
        let card = DiscoveryCardView(
            poi: poi,
            primaryTitle: Self.primaryTitle(for: poi, collected: collected),
            primaryEnabled: Self.primaryEnabled(for: poi, collected: collected))
        card.onClose = {}
        card.onAsk = { [weak self] in
            guard let self = self else { return }
            let ask = POIAskViewController(poi: poi)
            self.present(ask, animated: true)
        }
        card.onPrimary = { [weak self, weak card] in
            guard let self = self else { return }
            switch poi.interactionType {
            case .collect:
                card?.dismiss()
                self.launchCollectGame(poi)
            case .operate:
                card?.dismiss()
                self.launchOperateGame(poi)
            case .observe, .inquiry:
                card?.dismiss()
            }
        }
        card.frame = view.bounds
        card.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(card)
    }

    private static func primaryTitle(for poi: POI, collected: Bool) -> String {
        switch poi.interactionType {
        case .collect: return collected ? "已采集" : "采集"
        case .operate: return OperatePOILauncher.isImplemented(poi) ? "开始挑战 →" : "敬请期待"
        case .observe, .inquiry: return "明白了"
        }
    }

    private static func primaryEnabled(for poi: POI, collected: Bool) -> Bool {
        switch poi.interactionType {
        case .collect: return !collected
        case .operate: return OperatePOILauncher.isImplemented(poi)
        case .observe, .inquiry: return true
        }
    }

    // MARK: - operate 小游戏

    private func launchOperateGame(_ poi: POI) {
        guard let gameVC = OperatePOILauncher.makeViewController(for: poi, delegate: self) else { return }
        present(gameVC, animated: true)
    }

    /// 采集型:先玩「凿击 / 打磨」小操作,成功才收入图鉴。
    private func launchCollectGame(_ poi: POI) {
        let mode: CollectMiniGameViewController.Mode
        if let cid = poi.collectibleId, let c = ContentStore.shared.collectible(id: cid) {
            mode = c.category == "rock" ? .chisel : .polish
        } else {
            mode = .chisel
        }
        let vc = CollectMiniGameViewController(poi: poi, mode: mode) { [weak self] result in
            self?.dismiss(animated: true) {
                guard result != nil, let self = self else { return }
                self.viewModel.collect(poi)
                self.scene?.refreshPOIState(poi.id)
            }
        }
        present(vc, animated: true)
    }

    /// 小游戏结束：成功则记 POI 发现 + 评估本层通关。
    private func handleOperateFinish(poiId: String, success: Bool, stars: Int) {
        guard success, let poi = ContentStore.shared.poi(id: poiId) else { return }
        viewModel.markDiscovered(poi)
        scene?.refreshPOIState(poiId)
        let completed = GameProgressManager.shared.evaluateWorldCompletion(worldId: viewModel.worldId, stars: stars)
        if completed {
            presentWorldClearPanel(stars: stars)
        }
    }

    private func presentWorldClearPanel(stars: Int) {
        let starText = String(repeating: "★", count: max(1, min(3, stars))) + String(repeating: "☆", count: 3 - max(1, min(3, stars)))
        let alert = UIAlertController(
            title: "🎉 通关「\(viewModel.title)」",
            message: "\(starText)\n本层已完成!走到世界最右端「下潜出口」即可前往下一层。",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "太棒了", style: .default))
        present(alert, animated: true)
    }

    private func handleReachExit() {
        let gm = GameProgressManager.shared
        // 1) 本层未通关：出口锁定,提示后允许走回再触发。
        guard gm.isWorldCompleted(id: viewModel.worldId) else {
            presentExitAlert(title: "🔒 下潜出口未开启",
                             message: "先在本层完成关键挑战(带 !\u{FE0F} 的现象点)才能开启下潜出口。")
            return
        }
        // 2) 已是当前可玩的最后一层。
        guard let next = ContentStore.shared.world(at: viewModel.world.index + 1) else {
            presentExitAlert(title: "已抵达最深处", message: "这是当前可玩的最后一层,继续探索敬请期待。")
            return
        }
        // 3) 下一层为二期占位。
        if next.isComingSoon {
            presentExitAlert(title: "敬请期待", message: "「\(next.title)」将在二期开放,先在本层慢慢探索吧。")
            return
        }
        // 4) 正常下潜：播放过场 → 通知选层页切换到下一层。
        let transition = DescendTransitionViewController(fromTitle: viewModel.title, toWorld: next)
        transition.onComplete = { [weak self] in
            guard let self = self else { return }
            self.onRequestDescend?(self.viewModel.worldId)
        }
        present(transition, animated: false)
    }

    /// 出口提示:关闭后重置场景出口标志,便于玩家走回后再次触发。
    private func presentExitAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default) { [weak self] _ in
            self?.scene?.rearmExit()
        })
        present(alert, animated: true)
    }
}

// MARK: - OperateGameDelegate

extension WorldViewController: OperateGameDelegate {
    func operateGameDidFinish(poiId: String, success: Bool, stars: Int) {
        dismiss(animated: true) { [weak self] in
            self?.handleOperateFinish(poiId: poiId, success: success, stars: stars)
        }
    }
}
