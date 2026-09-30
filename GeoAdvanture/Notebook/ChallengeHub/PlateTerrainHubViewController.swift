//
//  PlateTerrainHubViewController.swift
//  GeoAdvanture
//
//  地壳运动专属二级页：世界地貌微模型 + 三个独立修复任务。
//

import UIKit
import SnapKit

final class PlateTerrainHubViewController: UIViewController {

    private let definition: ChallengeHubDefinition
    private let poi: POI
    private let progress = GameProgressManager.shared
    weak var delegate: ChallengeHubViewControllerDelegate?

    private let modelView = PlateTerrainModelView()
    private let progressLabel = UILabel()
    private let statusLabel = UILabel()
    private let guidanceLabel = UILabel()
    private let toolButton = UIButton(type: .system)
    private let primaryButton = UIButton(type: .system)
    private var isToolActive = false

    init(definition: ChallengeHubDefinition, poi: POI) {
        self.definition = definition
        self.poi = poi
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        progress.markChallengeHubVisited(id: definition.id)
        migrateLegacyCompletionIfNeeded()
        setupUI()
        render(animated: false)
    }

    private var completedTaskIds: [String] {
        definition.taskIds.filter { progress.isChallengeTaskCompleted(id: $0) }
    }

    private var allTasksCompleted: Bool {
        !definition.taskIds.isEmpty && completedTaskIds.count == definition.taskIds.count
    }

    private func migrateLegacyCompletionIfNeeded() {
        guard progress.isPOIDiscovered(id: poi.id) else { return }
        definition.taskIds.forEach { progress.completeChallengeTask(id: $0) }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.13, green: 0.10, blue: 0.08, alpha: 1)
        let paper = UIView()
        paper.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.79, alpha: 1)
        paper.layer.cornerRadius = 30
        view.addSubview(paper)
        paper.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide).inset(16) }

        let backButton = UIButton(type: .system)
        backButton.setTitle("‹ 返回地图", for: .normal)
        backButton.setTitleColor(UIColor(red: 0.31, green: 0.23, blue: 0.18, alpha: 1), for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        paper.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "世界地貌修复站"
        titleLabel.font = .systemFont(ofSize: 25, weight: .heavy)
        titleLabel.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.14, alpha: 1)
        titleLabel.textAlignment = .center
        paper.addSubview(titleLabel)

        statusLabel.font = .systemFont(ofSize: 12, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 12
        statusLabel.clipsToBounds = true
        paper.addSubview(statusLabel)

        paper.addSubview(modelView)

        let sidePanel = UIView()
        sidePanel.backgroundColor = UIColor.white.withAlphaComponent(0.48)
        sidePanel.layer.cornerRadius = 22
        sidePanel.layer.borderWidth = 1
        sidePanel.layer.borderColor = UIColor(red: 0.49, green: 0.36, blue: 0.25, alpha: 0.22).cgColor
        paper.addSubview(sidePanel)

        let missionTitle = UILabel()
        missionTitle.text = "板块运动"
        missionTitle.font = .systemFont(ofSize: 19, weight: .heavy)
        missionTitle.textColor = UIColor(red: 0.28, green: 0.20, blue: 0.16, alpha: 1)

        progressLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        progressLabel.textColor = UIColor(red: 0.28, green: 0.55, blue: 0.41, alpha: 1)

        guidanceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        guidanceLabel.textColor = UIColor(red: 0.31, green: 0.26, blue: 0.21, alpha: 1)
        guidanceLabel.numberOfLines = 0

        let unlockLabel = UILabel()
        unlockLabel.text = "完成后，将点亮板块运动知识内容，并开放总结页中的解释与应用。"
        unlockLabel.font = .systemFont(ofSize: 12)
        unlockLabel.textColor = UIColor(white: 0.39, alpha: 1)
        unlockLabel.numberOfLines = 0

        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        primaryButton.backgroundColor = UIColor(red: 0.33, green: 0.61, blue: 0.46, alpha: 1)
        primaryButton.layer.cornerRadius = 18
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        primaryButton.snp.makeConstraints { $0.height.equalTo(44) }

        if let tool = KnowledgeToolRegistry.shared.availableTools(evidenceSourceId: poi.id).first {
            toolButton.setTitle("启用：\(tool.title)", for: .normal)
            toolButton.setImage(UIImage(systemName: tool.symbolName), for: .normal)
            toolButton.tintColor = .white
            toolButton.setTitleColor(.white, for: .normal)
            toolButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            toolButton.backgroundColor = UIColor(red: 0.24, green: 0.48, blue: 0.66, alpha: 1)
            toolButton.layer.cornerRadius = 13
            toolButton.addTarget(self, action: #selector(toolTapped), for: .touchUpInside)
            toolButton.snp.makeConstraints { $0.height.equalTo(38) }
        } else {
            toolButton.isHidden = true
        }

        let sideStack = UIStackView(arrangedSubviews: [missionTitle, progressLabel, guidanceLabel, unlockLabel, toolButton, primaryButton])
        sideStack.axis = .vertical
        sideStack.spacing = 10
        sidePanel.addSubview(sideStack)
        sideStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(17)
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(112)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(statusLabel.snp.leading).offset(-12)
        }
        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalTo(backButton)
            make.width.equalTo(82)
            make.height.equalTo(25)
        }
        paper.bringSubviewToFront(backButton)
        modelView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.bottom.equalToSuperview().inset(22)
            make.width.equalToSuperview().multipliedBy(0.64)
        }
        sidePanel.snp.makeConstraints { make in
            make.leading.equalTo(modelView.snp.trailing).offset(20)
            make.trailing.equalToSuperview().inset(24)
            make.top.bottom.equalTo(modelView)
        }
    }

    private func render(animated: Bool) {
        let completed = Set(completedTaskIds)
        let tasks = definition.taskIds.map { id -> PlateTerrainModelView.TaskState in
            let info = taskInfo(id)
            return .init(
                id: id,
                title: info.title,
                symbol: info.symbol,
                completed: completed.contains(id),
                unlocked: true)
        }
        modelView.render(tasks: tasks, animated: animated)
        progressLabel.text = "\(completed.count) / \(definition.taskIds.count)"
        statusLabel.text = allTasksCompleted ? "✓ 已完成" : "修复中"
        statusLabel.textColor = allTasksCompleted ? .white : UIColor(red: 0.38, green: 0.27, blue: 0.18, alpha: 1)
        statusLabel.backgroundColor = allTasksCompleted ? .systemGreen : UIColor.systemOrange.withAlphaComponent(0.22)

        guidanceLabel.text = "\(poi.phenomenon)\n\n你是否好奇，板块靠近或远离时，为什么会形成完全不同的地貌？"
        let nextTitle = nextTaskId.map { taskInfo($0).title }
        primaryButton.setTitle(
            allTasksCompleted ? "重新体验本关" : "开始修复\(nextTitle.map { "：\($0)" } ?? "")",
            for: .normal)
    }

    private var nextTaskId: String? {
        definition.taskIds.first { !progress.isChallengeTaskCompleted(id: $0) }
    }

    @objc private func primaryTapped() {
        launchTask(
            id: nextTaskId ?? definition.taskIds.first ?? "plate_task_mountain",
            allowCompleted: allTasksCompleted)
    }

    private func taskInfo(_ id: String) -> (title: String, symbol: String) {
        switch id {
        case "plate_task_subduction": return ("海沟", "water.waves.and.arrow.down")
        case "plate_task_rift": return ("裂谷", "arrow.left.and.right")
        default: return ("山脉", "mountain.2.fill")
        }
    }

    private func launchTask(id: String, allowCompleted: Bool = false) {
        guard definition.taskIds.contains(id),
              allowCompleted || !progress.isChallengeTaskCompleted(id: id) else { return }
        let controller = PlateWorkshopViewController(poi: poi, taskId: id) { [weak self] result in
            guard let self else { return }
            self.dismiss(animated: true) {
                guard let result else { return }
                self.consume(result)
            }
        }
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    private func consume(_ result: ChallengeResult) {
        let completedAfterResult = Set(completedTaskIds + result.completedTaskIds)
        let reachesMilestone = !definition.taskIds.isEmpty
            && definition.taskIds.allSatisfy { completedAfterResult.contains($0) }
        let taskId = reachesMilestone ? nil : result.completedTaskIds.first

        guard let cardContent = ContentStore.shared.achievementCard(
            challengeId: result.challengeId,
            taskId: taskId) else {
            commit(result)
            return
        }

        let card = AchievementCardViewController(
            result: result,
            content: cardContent,
            isMilestone: reachesMilestone,
            supportsImmersive: reachesMilestone && definition.supportsAR) { [weak self] action in
                guard let self else { return }
                self.dismiss(animated: true) {
                    self.commit(result)
                    guard action == .continueChallenge,
                          !self.allTasksCompleted,
                          let next = self.nextAvailableTaskId() else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.launchTask(id: next)
                    }
                }
            }
        present(card, animated: true)
    }

    private func commit(_ result: ChallengeResult) {
        result.completedTaskIds.forEach { progress.completeChallengeTask(id: $0) }
        if allTasksCompleted, !progress.isPOIDiscovered(id: poi.id) {
            progress.markPOIDiscovered(id: poi.id)
            UnlockRuleEngine.shared.handle("poi.discover.\(poi.id)")
        }
        render(animated: true)
        delegate?.challengeHubViewControllerDidUpdateProgress(poiId: poi.id)
    }

    private func nextAvailableTaskId() -> String? {
        let completed = Set(completedTaskIds)
        let mountainDone = completed.contains("plate_task_mountain")
        return definition.taskIds.first {
            !completed.contains($0) && ($0 == "plate_task_mountain" || mountainDone)
        }
    }

    @objc private func toolTapped() {
        isToolActive.toggle()
        modelView.setKnowledgeOverlayVisible(isToolActive, animated: true)
        toolButton.setTitle(isToolActive ? "关闭：板块方向层" : "启用：板块方向层", for: .normal)
        toolButton.backgroundColor = isToolActive
            ? UIColor(red: 0.72, green: 0.43, blue: 0.15, alpha: 1)
            : UIColor(red: 0.24, green: 0.48, blue: 0.66, alpha: 1)
    }

    @objc private func backTapped() {
        delegate?.challengeHubViewControllerDidUpdateProgress(poiId: poi.id)
        dismiss(animated: true)
    }
}
