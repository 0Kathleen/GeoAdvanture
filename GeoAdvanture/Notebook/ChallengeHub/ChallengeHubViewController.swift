//
//  ChallengeHubViewController.swift
//  GeoAdvanture
//
//  六个地壳热点共用的二级主题页外壳：主题视觉、现场任务、玩法启动与结果回流。
//

import UIKit
import SnapKit

protocol ChallengeHubViewControllerDelegate: AnyObject {
    func challengeHubViewControllerDidUpdateProgress(poiId: String)
}

final class ChallengeHubViewController: UIViewController {

    private let definition: ChallengeHubDefinition
    private let poi: POI
    private let progress = GameProgressManager.shared
    weak var delegate: ChallengeHubViewControllerDelegate?

    private let sceneView: ChallengeHubSceneView
    private let statusLabel = UILabel()
    private let primaryButton = UIButton(type: .system)
    private let toolButton = UIButton(type: .system)
    private var isToolActive = false

    private var availableTool: KnowledgeToolDefinition? {
        guard definition.sceneKind != "plateTerrain" else { return nil }
        return KnowledgeToolRegistry.shared.availableTools(evidenceSourceId: poi.id).first
    }

    init(definition: ChallengeHubDefinition, poi: POI) {
        self.definition = definition
        self.poi = poi
        self.sceneView = ChallengeHubSceneView(definition: definition, poi: poi)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        progress.markChallengeHubVisited(id: definition.id)
        render(animated: false)
    }

    private var isCompleted: Bool {
        !definition.taskIds.isEmpty && definition.taskIds.allSatisfy {
            progress.isChallengeTaskCompleted(id: $0)
        }
    }

    private func setupUI() {
        view.backgroundColor = GeoTheme.Color.darkSurface

        let paper = UIView()
        paper.backgroundColor = GeoTheme.Color.paper
        paper.layer.cornerRadius = GeoTheme.Radius.modal
        view.addSubview(paper)
        paper.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        let backButton = UIButton(type: .system)
        backButton.setTitle("‹ 返回地图", for: .normal)
        backButton.setTitleColor(GeoTheme.Color.ink, for: .normal)
        backButton.titleLabel?.font = GeoTheme.Typography.control(size: 15)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        paper.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = poi.title
        titleLabel.font = GeoTheme.Typography.heading(size: 25)
        titleLabel.textColor = GeoTheme.Color.ink
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        paper.addSubview(titleLabel)

        statusLabel.font = GeoTheme.Typography.caption(size: 12)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 12
        statusLabel.clipsToBounds = true
        paper.addSubview(statusLabel)

        let content = UIStackView()
        content.axis = .horizontal
        content.spacing = 22
        content.distribution = .fill
        paper.addSubview(content)

        let taskPanel = UIView()
        GeoTheme.applyPaperCard(to: taskPanel, radius: GeoTheme.Radius.modal)
        content.addArrangedSubview(sceneView)
        content.addArrangedSubview(taskPanel)

        let taskTitle = UILabel()
        taskTitle.text = "现场任务"
        taskTitle.font = GeoTheme.Typography.heading(size: 19)
        taskTitle.textColor = GeoTheme.Color.ink

        let phenomenonLabel = UILabel()
        phenomenonLabel.text = "\(poi.phenomenon)\n\n\(curiosityQuestion)"
        phenomenonLabel.font = GeoTheme.Typography.body(size: 14)
        phenomenonLabel.textColor = GeoTheme.Color.ink
        phenomenonLabel.numberOfLines = 0

        let unlockLabel = UILabel()
        unlockLabel.text = unlockMessage
        unlockLabel.font = GeoTheme.Typography.body(size: 12)
        unlockLabel.textColor = GeoTheme.Color.inkMuted
        unlockLabel.numberOfLines = 0

        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = GeoTheme.Typography.control(size: 15)
        primaryButton.backgroundColor = GeoTheme.Color.teal
        primaryButton.layer.cornerRadius = GeoTheme.Radius.control
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        if let tool = availableTool {
            toolButton.setTitle("启用：\(tool.title)", for: .normal)
            toolButton.setImage(UIImage(systemName: tool.symbolName), for: .normal)
            toolButton.tintColor = .white
            toolButton.setTitleColor(.white, for: .normal)
            toolButton.titleLabel?.font = GeoTheme.Typography.control(size: 12)
            toolButton.backgroundColor = GeoTheme.Color.blue
            toolButton.layer.cornerRadius = GeoTheme.Radius.control
            toolButton.addTarget(self, action: #selector(toolTapped), for: .touchUpInside)
            toolButton.snp.makeConstraints { $0.height.equalTo(36) }
        } else {
            toolButton.isHidden = true
        }

        let panelScroll = UIScrollView()
        panelScroll.showsVerticalScrollIndicator = false
        let panelStack = UIStackView(arrangedSubviews: [taskTitle, phenomenonLabel, unlockLabel, toolButton, primaryButton])
        panelStack.axis = .vertical
        panelStack.spacing = 9
        panelStack.setCustomSpacing(7, after: taskTitle)
        taskPanel.addSubview(panelScroll)
        panelScroll.addSubview(panelStack)
        panelScroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        panelStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }
        primaryButton.snp.makeConstraints { $0.height.equalTo(44) }

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.top.equalToSuperview().offset(15)
            make.height.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(80)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
        }
        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalTo(backButton)
            make.width.equalTo(76)
            make.height.equalTo(25)
        }
        content.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(22)
        }
        sceneView.snp.makeConstraints { make in
            make.width.equalTo(content.snp.width).multipliedBy(0.61)
            make.height.equalTo(taskPanel)
        }
    }

    private func render(animated: Bool) {
        let completed = isCompleted
        statusLabel.text = completed ? "✓ 已完成" : "进行中"
        statusLabel.textColor = completed ? .white : GeoTheme.Color.ink
        statusLabel.backgroundColor = completed
            ? GeoTheme.Color.success
            : GeoTheme.Color.warning.withAlphaComponent(0.22)
        sceneView.setCompleted(completed, animated: animated)

        switch poi.interactionType {
        case .operate:
            primaryButton.setTitle(completed ? "再次操作" : "开始挑战", for: .normal)
            primaryButton.isEnabled = OperatePOILauncher.isImplemented(poi)
        case .collect:
            primaryButton.setTitle(completed ? "再次采集" : "开始采集", for: .normal)
            primaryButton.isEnabled = true
        case .observe, .inquiry:
            primaryButton.setTitle(completed ? "重新体验本关" : "开始现场调查", for: .normal)
            primaryButton.isEnabled = definition.fieldTask != nil
        }
        primaryButton.alpha = primaryButton.isEnabled ? 1 : 0.45
    }

    private var curiosityQuestion: String {
        switch poi.id {
        case "poi_crust_rock":
            return "你能从纹理和结构中判断，它经历过怎样的形成过程吗？"
        case "poi_crust_crack":
            return "大地为什么会被拉开，并慢慢形成一条长长的裂谷？"
        case "poi_crust_diamond":
            return "你有没有好奇过，钻石怎样形成，又为什么如此坚硬？"
        case "poi_crust_volcano":
            return "火山喷发前会留下哪些可以被观察到的变化？"
        case "poi_crust_lava":
            return "同一团炽热物质来到地表后，为什么会换一个名字？"
        default:
            return "这里发生了什么，又能从哪些现象中找到答案？"
        }
    }

    private var unlockMessage: String {
        if let collectibleId = poi.collectibleId,
           let collectible = ContentStore.shared.collectible(id: collectibleId) {
            return "完成后：收藏「\(collectible.name)」，点亮对应知识。"
        }
        return "完成后：点亮知识总结与应用题。"
    }

    @objc private func backTapped() {
        delegate?.challengeHubViewControllerDidUpdateProgress(poiId: poi.id)
        dismiss(animated: true)
    }

    @objc private func primaryTapped() {
        switch poi.interactionType {
        case .operate:
            launchOperateGame()
        case .collect:
            launchCollectGame()
        case .observe, .inquiry:
            launchFieldTask()
        }
    }

    @objc private func toolTapped() {
        guard let tool = availableTool else { return }
        isToolActive.toggle()
        sceneView.setKnowledgeTool(tool, active: isToolActive)
        toolButton.setTitle(isToolActive ? "关闭：\(tool.title)" : "启用：\(tool.title)", for: .normal)
        toolButton.backgroundColor = isToolActive
            ? GeoTheme.Color.warning
            : GeoTheme.Color.blue
    }

    private func launchOperateGame() {
        guard let controller = OperatePOILauncher.makeViewController(for: poi, delegate: self) else { return }
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    private func launchCollectGame() {
        let mode: CollectMiniGameViewController.Mode
        if let id = poi.collectibleId, let collectible = ContentStore.shared.collectible(id: id) {
            mode = collectible.category == "rock" ? .chisel : .polish
        } else {
            mode = .chisel
        }
        let controller = CollectMiniGameViewController(poi: poi, mode: mode) { [weak self] result in
            guard let self else { return }
            self.dismiss(animated: true) {
                guard let result else { return }
                self.presentAchievement(for: result)
            }
        }
        present(controller, animated: true)
    }

    private func launchFieldTask() {
        guard let task = definition.fieldTask else { return }
        sceneView.revealObservation()
        let controller = FieldInvestigationViewController(
            definition: definition,
            poi: poi,
            task: task) { [weak self] result in
                guard let self else { return }
                self.dismiss(animated: true) {
                    guard let result else { return }
                    self.presentAchievement(for: result)
                }
            }
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    private func presentAchievement(for result: ChallengeResult) {
        let isMilestone = !definition.taskIds.isEmpty
            && Set(result.completedTaskIds).isSuperset(of: Set(definition.taskIds))
        let taskId = isMilestone ? nil : result.completedTaskIds.first
        guard let content = ContentStore.shared.achievementCard(
            challengeId: result.challengeId,
            taskId: taskId) else {
            LearningProgressCoordinator.shared.recordChallengeResult(result)
            commit(result: result)
            return
        }
        let card = AchievementCardViewController(
            result: result,
            content: content,
            isMilestone: isMilestone,
            supportsImmersive: isMilestone && definition.supportsAR) { [weak self] _ in
                guard let self else { return }
                self.dismiss(animated: true) {
                    self.commit(result: result)
                }
            }
        present(card, animated: true)
    }

    private func commit(result: ChallengeResult) {
        result.completedTaskIds.forEach { progress.completeChallengeTask(id: $0) }
        for collectibleId in result.earnedArtifactIds where !progress.isCollected(id: collectibleId) {
            progress.collect(id: collectibleId)
            UnlockRuleEngine.shared.handle("collectible.get.\(collectibleId)")
        }
        if !progress.isPOIDiscovered(id: poi.id) {
            progress.markPOIDiscovered(id: poi.id)
            UnlockRuleEngine.shared.handle("poi.discover.\(poi.id)")
        }
        finishProgressUpdate()
    }

    private func markPOICompleted() {
        if let taskId = definition.taskIds.first {
            progress.completeChallengeTask(id: taskId)
        }
        guard !progress.isPOIDiscovered(id: poi.id) else {
            render(animated: true)
            return
        }
        progress.markPOIDiscovered(id: poi.id)
        UnlockRuleEngine.shared.handle("poi.discover.\(poi.id)")
        finishProgressUpdate()
    }

    private func finishProgressUpdate() {
        render(animated: true)
        delegate?.challengeHubViewControllerDidUpdateProgress(poiId: poi.id)
    }
}

extension ChallengeHubViewController: OperateGameDelegate {
    func operateGameDidFinish(poiId: String, success: Bool, stars: Int) {
        dismiss(animated: true) { [weak self] in
            guard let self, success, poiId == self.poi.id else { return }
            let result = ChallengeResult(
                challengeId: self.poi.id,
                completedTaskIds: self.definition.taskIds,
                observationIds: [],
                earnedArtifactIds: [],
                score: max(60, min(100, stars * 34)))
            self.presentAchievement(for: result)
        }
    }
}
