//
//  PlateWorkshopViewController.swift
//  GeoAdvanture
//
//  板块工坊：选择板块类型，连续施力观察形成阶段，并用证据判断完成单个地貌任务。
//

import UIKit
import SpriteKit
import SnapKit

final class PlateWorkshopViewController: UIViewController, OperateGameViewController {

    private struct EvidenceOption {
        let text: String
        let isCorrect: Bool
    }

    private struct Goal {
        let taskId: String
        let title: String
        let hint: String
        let leftType: PlateKind
        let rightType: PlateKind
        let kind: LandformKind
        let target: CGFloat
        let tolerance: CGFloat
        let evidenceQuestion: String
        let evidenceOptions: [EvidenceOption]
    }

    private static let allGoals: [Goal] = [
        Goal(
            taskId: "plate_task_mountain",
            title: "修复喜马拉雅山脉",
            hint: "选择两侧板块，再拖动观察。目标是让边界岩层持续增厚并隆起。",
            leftType: .continental,
            rightType: .continental,
            kind: .mountain,
            target: 0.80,
            tolerance: 0.13,
            evidenceQuestion: "哪条观察最能说明山脉是怎样形成的？",
            evidenceOptions: [
                .init(text: "两块大陆板块相向移动，边界岩层挤压、增厚并隆起", isCorrect: true),
                .init(text: "两块板块向两侧分离，中间出现越来越宽的缺口", isCorrect: false)
            ]),
        Goal(
            taskId: "plate_task_subduction",
            title: "修复马里亚纳海沟",
            hint: "比较大陆与海洋板块，寻找会向下弯曲并进入另一块板块下方的组合。",
            leftType: .oceanic,
            rightType: .continental,
            kind: .trench,
            target: 0.75,
            tolerance: 0.13,
            evidenceQuestion: "哪条观察支持这里发生了俯冲？",
            evidenceOptions: [
                .init(text: "较薄、较致密的海洋板块在边界向大陆板块下方弯曲下沉", isCorrect: true),
                .init(text: "两块大陆板块厚度完全不变，只是一起向上平移", isCorrect: false)
            ]),
        Goal(
            taskId: "plate_task_rift",
            title: "修复东非大裂谷",
            hint: "让板块彼此远离，观察中间地壳怎样变薄、断裂和下陷。",
            leftType: .continental,
            rightType: .continental,
            kind: .rift,
            target: 0.70,
            tolerance: 0.13,
            evidenceQuestion: "哪条观察最符合裂谷形成过程？",
            evidenceOptions: [
                .init(text: "板块向两侧分离，中间地壳被拉薄并逐渐下陷", isCorrect: true),
                .init(text: "板块相向挤压，中间岩层不断增厚和隆起", isCorrect: false)
            ])
    ]

    private let poi: POI
    private weak var gameDelegate: OperateGameDelegate?
    private let taskCompletion: ((ChallengeResult?) -> Void)?
    private let goals: [Goal]

    private var goalIndex = 0
    private var penalties = 0
    private var baseInput: CGFloat = 0
    private var didFinish = false

    private let skView = SKView()
    private var scene: PlateWorkshopScene!
    private var didPresent = false

    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let goalCard = UILabel()
    private let hintLabel = UILabel()
    private let stageLabel = UILabel()
    private let typePromptLabel = UILabel()
    private let leftSeg = UISegmentedControl(items: ["大陆", "海洋"])
    private let rightSeg = UISegmentedControl(items: ["大陆", "海洋"])
    private let confirmButton = UIButton(type: .system)

    init(poi: POI, delegate: OperateGameDelegate) {
        self.poi = poi
        self.gameDelegate = delegate
        self.taskCompletion = nil
        self.goals = Self.allGoals
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    init(poi: POI, taskId: String, completion: @escaping (ChallengeResult?) -> Void) {
        self.poi = poi
        self.gameDelegate = nil
        self.taskCompletion = completion
        self.goals = Self.allGoals.filter { $0.taskId == taskId }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSKView()
        setupHUD()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skView.frame = view.bounds
        if !didPresent, view.bounds.width > 0, !goals.isEmpty {
            didPresent = true
            scene = PlateWorkshopScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            scene.onFormationStageChanged = { [weak self] _ in self?.updateStage() }
            skView.presentScene(scene)
            loadGoal(0)
            showTipCard()
        }
    }

    private func showTipCard() {
        let card = GameInfoCardView(
            style: .tip,
            title: "修复缺失地貌",
            lines: [
                "选择两侧板块类型，再左右拖动改变运动方向。",
                "让地貌达到目标后，选出你观察到的结果。"
            ],
            buttonTitle: "开始修复")
        card.present(in: view)
    }

    private func setupSKView() {
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)
        skView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    private func setupHUD() {
        closeButton.configuration = GeoTheme.buttonConfiguration(
            title: "返回探索站",
            systemImage: "chevron.left",
            style: .overlay)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        titleLabel.text = "板块工坊"
        titleLabel.font = GeoTheme.Typography.heading(size: 20)
        titleLabel.textColor = GeoTheme.Color.lightText
        GeoTheme.applyReadableShadow(to: titleLabel)

        goalCard.font = GeoTheme.Typography.heading(size: 22)
        goalCard.textColor = UIColor(red: 1.0, green: 0.90, blue: 0.62, alpha: 1)
        goalCard.numberOfLines = 0
        goalCard.textAlignment = .center
        GeoTheme.applyReadableShadow(to: goalCard)

        stageLabel.font = GeoTheme.Typography.control(size: 16)
        stageLabel.textColor = .white
        stageLabel.textAlignment = .center
        stageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        stageLabel.layer.cornerRadius = 14
        stageLabel.clipsToBounds = true

        typePromptLabel.text = "选择左、右板块类型"
        typePromptLabel.font = GeoTheme.Typography.caption(size: 12)
        typePromptLabel.textColor = UIColor(white: 0.90, alpha: 1)
        typePromptLabel.textAlignment = .center

        [leftSeg, rightSeg].forEach { segment in
            segment.selectedSegmentIndex = UISegmentedControl.noSegment
            segment.backgroundColor = UIColor.black.withAlphaComponent(0.45)
            segment.selectedSegmentTintColor = GeoTheme.Color.teal
            segment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
            segment.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        }

        confirmButton.setTitle("检查观察结果", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = GeoTheme.Typography.control(size: 15)
        confirmButton.backgroundColor = UIColor(white: 0.3, alpha: 1)
        confirmButton.layer.cornerRadius = GeoTheme.Radius.control
        confirmButton.isEnabled = false
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        [closeButton, titleLabel, goalCard, stageLabel, typePromptLabel,
         leftSeg, rightSeg, confirmButton].forEach(view.addSubview)
        layoutHUD()
    }

    private func layoutHUD() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.height.equalTo(38)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
        }
        goalCard.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        stageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(22)
            make.width.equalTo(300)
            make.height.equalTo(36)
        }
        typePromptLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(stageLabel.snp.top).offset(-7)
        }
        leftSeg.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.centerY.equalTo(stageLabel)
            make.width.equalTo(150)
        }
        rightSeg.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.centerY.equalTo(stageLabel)
            make.width.equalTo(150)
        }
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.width.equalTo(176)
            make.height.equalTo(38)
        }
    }

    private func loadGoal(_ index: Int) {
        goalIndex = index
        let goal = goals[index]
        goalCard.text = goals.count > 1
            ? "修复 \(index + 1)/\(goals.count)：\(goal.title)"
            : goal.title
        hintLabel.text = goal.hint

        leftSeg.selectedSegmentIndex = UISegmentedControl.noSegment
        rightSeg.selectedSegmentIndex = UISegmentedControl.noSegment
        scene.setTypes(left: .continental, right: .continental)
        scene.setInput(0)
        baseInput = 0
        updateStage()
    }

    private var hasChosenBothTypes: Bool {
        leftSeg.selectedSegmentIndex != UISegmentedControl.noSegment &&
            rightSeg.selectedSegmentIndex != UISegmentedControl.noSegment
    }

    private func applyTypes() {
        guard hasChosenBothTypes else { return }
        let (left, right) = selectedPlateKinds
        scene.setTypes(left: left, right: right)
    }

    private var selectedPlateKinds: (PlateKind, PlateKind) {
        let left: PlateKind = leftSeg.selectedSegmentIndex == 0 ? .continental : .oceanic
        let right: PlateKind = rightSeg.selectedSegmentIndex == 0 ? .continental : .oceanic
        return (left, right)
    }

    private func updateStage() {
        guard scene != nil, !goals.isEmpty else { return }
        let goal = goals[goalIndex]
        let selected = selectedPlateKinds
        let matchedTypes = hasChosenBothTypes &&
            selected.0 == goal.leftType && selected.1 == goal.rightType
        let matchedKind = matchedTypes && scene.producedLandform == goal.kind
        let magnitude = matchedKind ? scene.magnitude : 0
        let within = matchedKind && abs(magnitude - goal.target) <= goal.tolerance

        if !hasChosenBothTypes {
            stageLabel.text = "阶段：等待选择板块"
            stageLabel.textColor = GeoTheme.Color.gold
        } else if scene.producedLandform != .none && !matchedKind {
            stageLabel.text = "形成了别的地貌，检查板块类型和方向"
            stageLabel.textColor = GeoTheme.Color.warning
        } else {
            stageLabel.text = stageText(for: scene.formationStage, goal: goal)
            stageLabel.textColor = within ? GeoTheme.Color.success : .white
        }

        confirmButton.isEnabled = within
        confirmButton.backgroundColor = within ? GeoTheme.Color.teal : UIColor(white: 0.3, alpha: 1)
    }

    private func stageText(for stage: PlateFormationStage, goal: Goal) -> String {
        switch stage {
        case .resting: return "阶段：等待施力"
        case .moving:
            return scene.input > 0 ? "阶段：板块正在靠近" : "阶段：板块正在分离"
        case .contact:
            switch goal.kind {
            case .mountain: return "阶段：大陆边界已经接触"
            case .trench: return "阶段：海洋板块开始弯曲"
            case .rift: return "阶段：地壳开始受到拉张"
            case .none: return "阶段：边界开始变化"
            }
        case .deforming:
            switch goal.kind {
            case .mountain: return "阶段：岩层挤压、增厚、隆起"
            case .trench: return "阶段：海洋板块向下俯冲"
            case .rift: return "阶段：地壳变薄、断裂、下陷"
            case .none: return "阶段：地貌正在形成"
            }
        case .formed: return "阶段：目标地貌已经稳定形成"
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard hasChosenBothTypes else {
            typePromptLabel.text = "请先选择两侧板块类型"
            typePromptLabel.textColor = .systemYellow
            return
        }
        let translation = gesture.translation(in: skView).x
        switch gesture.state {
        case .began:
            baseInput = scene.input
        case .changed:
            var newInput = baseInput + translation / (view.bounds.width * 0.6)
            if abs(gesture.velocity(in: skView).x) > 1600 {
                penalties += 1
                scene.flashFracture()
                newInput = scene.input * 0.6
                baseInput = newInput - translation / (view.bounds.width * 0.6)
            }
            scene.setInput(newInput)
            updateStage()
        default:
            break
        }
    }

    @objc private func typeChanged() {
        typePromptLabel.text = hasChosenBothTypes ? "拖动场景，让板块开始运动" : "还需要选择另一侧板块"
        typePromptLabel.textColor = hasChosenBothTypes
            ? GeoTheme.Color.lightText.withAlphaComponent(0.90)
            : GeoTheme.Color.gold
        applyTypes()
        scene.setInput(0)
        baseInput = 0
        updateStage()
    }

    @objc private func confirmTapped() {
        showEvidenceCheck(for: goals[goalIndex])
    }

    private func showEvidenceCheck(for goal: Goal) {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = GeoTheme.Color.paper
        card.layer.cornerRadius = GeoTheme.Radius.modal
        overlay.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.68)
        }

        let title = UILabel()
        title.text = "选择观察证据"
        title.font = GeoTheme.Typography.heading(size: 22)
        title.textColor = GeoTheme.Color.ink
        title.textAlignment = .center

        let question = UILabel()
        question.text = goal.evidenceQuestion
        question.font = GeoTheme.Typography.body(size: 15)
        question.textColor = GeoTheme.Color.ink
        question.textAlignment = .center
        question.numberOfLines = 0

        let feedback = UILabel()
        feedback.font = GeoTheme.Typography.caption(size: 13)
        feedback.textAlignment = .center
        feedback.numberOfLines = 0
        feedback.text = nil
        feedback.isHidden = true
        feedback.textColor = UIColor(white: 0.42, alpha: 1)

        let choices = UIStackView()
        choices.axis = .vertical
        choices.spacing = 10
        goal.evidenceOptions.shuffled().forEach { option in
            let button = UIButton(type: .system)
            button.setTitle(option.text, for: .normal)
            button.setTitleColor(GeoTheme.Color.ink, for: .normal)
            button.titleLabel?.font = GeoTheme.Typography.control(size: 14)
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.backgroundColor = GeoTheme.Color.paperControl
            button.layer.cornerRadius = GeoTheme.Radius.control
            button.layer.borderWidth = 1
            button.layer.borderColor = GeoTheme.Color.separator.cgColor
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(50) }
            button.addAction(UIAction { [weak self, weak overlay, weak feedback, weak button] _ in
                guard let self else { return }
                if option.isCorrect {
                    choices.isUserInteractionEnabled = false
                    feedback?.isHidden = false
                    feedback?.text = "判断正确：这条变化链能够解释形成结果。"
                    feedback?.textColor = GeoTheme.Color.success
                    button?.backgroundColor = GeoTheme.Color.success.withAlphaComponent(0.18)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        overlay?.removeFromSuperview()
                        self.completeCurrentGoal(goal)
                    }
                } else {
                    self.penalties += 1
                    feedback?.isHidden = false
                    feedback?.text = "再看一次模型：这条描述对应的是另一种板块运动。"
                    feedback?.textColor = .systemRed
                    let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
                    shake.values = [-7, 7, -5, 5, 0]
                    shake.duration = 0.28
                    button?.layer.add(shake, forKey: "wrongEvidence")
                }
            }, for: .touchUpInside)
            choices.addArrangedSubview(button)
        }

        let stack = UIStackView(arrangedSubviews: [title, question, choices, feedback])
        stack.axis = .vertical
        stack.spacing = 14
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(22) }
    }

    private func completeCurrentGoal(_ goal: Goal) {
        if taskCompletion != nil {
            reportTaskSuccess(goal)
        } else if goalIndex < goals.count - 1 {
            loadGoal(goalIndex + 1)
        } else {
            reportLegacySuccess()
        }
    }

    private func reportTaskSuccess(_ goal: Goal) {
        guard !didFinish else { return }
        didFinish = true
        taskCompletion?(ChallengeResult(
            challengeId: poi.id,
            completedTaskIds: [goal.taskId],
            observationIds: ["evidence_\(goal.taskId)"],
            earnedArtifactIds: [],
            score: starScore))
    }

    private func reportLegacySuccess() {
        guard !didFinish else { return }
        didFinish = true
        gameDelegate?.operateGameDidFinish(poiId: poi.id, success: true, stars: starScore)
    }

    private var starScore: Int {
        penalties == 0 ? 3 : (penalties <= 2 ? 2 : 1)
    }

    @objc private func closeTapped() {
        guard !didFinish else { return }
        didFinish = true
        if let taskCompletion {
            taskCompletion(nil)
        } else {
            gameDelegate?.operateGameDidFinish(poiId: poi.id, success: false, stars: 0)
        }
    }
}
