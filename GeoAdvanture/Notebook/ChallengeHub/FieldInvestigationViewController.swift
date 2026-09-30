//
//  FieldInvestigationViewController.swift
//  GeoAdvanture
//
//  Step 10：观察型二级页的统一现场任务。完成有效判断后才产出 ChallengeResult。
//

import UIKit
import SnapKit

final class FieldInvestigationViewController: UIViewController {

    private let definition: ChallengeHubDefinition
    private let poi: POI
    private let task: FieldTaskDefinition
    private let onFinish: (ChallengeResult?) -> Void
    private let sceneView: FieldInvestigationSceneView
    private let optionStack = UIStackView()
    private let feedbackLabel = UILabel()
    private let finishButton = UIButton(type: .system)
    private var optionButtons: [String: UIButton] = [:]
    private var selectedIds = Set<String>()
    private var orderIndex = 0
    private var mistakes = 0
    private var solved = false
    private var finished = false

    init(definition: ChallengeHubDefinition,
         poi: POI,
         task: FieldTaskDefinition,
         onFinish: @escaping (ChallengeResult?) -> Void) {
        self.definition = definition
        self.poi = poi
        self.task = task
        self.onFinish = onFinish
        self.sceneView = FieldInvestigationSceneView(sceneKind: definition.sceneKind, options: task.options)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        buildInteraction()
    }

    private func setupUI() {
        view.backgroundColor = GeoTheme.Color.darkSurface
        let paper = UIView()
        paper.backgroundColor = GeoTheme.Color.paper
        paper.layer.cornerRadius = GeoTheme.Radius.modal
        view.addSubview(paper)
        paper.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide).inset(12) }

        let close = UIButton(type: .system)
        close.setTitle("‹ 返回探索站", for: .normal)
        close.setTitleColor(GeoTheme.Color.ink, for: .normal)
        close.titleLabel?.font = GeoTheme.Typography.control(size: 15)
        close.addAction(UIAction { [weak self] _ in self?.finish(nil) }, for: .touchUpInside)

        let title = UILabel()
        title.text = definition.title
        title.font = GeoTheme.Typography.heading(size: 20)
        title.textColor = GeoTheme.Color.ink
        title.textAlignment = .center

        let tag = UILabel()
        tag.text = "现场观察"
        tag.font = GeoTheme.Typography.caption(size: 10)
        tag.textColor = .white
        tag.textAlignment = .center
        tag.backgroundColor = GeoTheme.Color.teal
        tag.layer.cornerRadius = 10
        tag.clipsToBounds = true

        paper.addSubview(close)
        paper.addSubview(title)
        paper.addSubview(tag)
        close.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(34)
        }
        title.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(close)
        }
        tag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalTo(close)
            make.width.equalTo(82)
            make.height.equalTo(22)
        }

        let taskPanel = UIView()
        GeoTheme.applyPaperCard(to: taskPanel, radius: GeoTheme.Radius.card)
        paper.addSubview(sceneView)
        paper.addSubview(taskPanel)
        sceneView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalTo(close.snp.bottom).offset(8)
            make.bottom.equalToSuperview().inset(16)
            make.width.equalToSuperview().multipliedBy(0.52)
        }
        taskPanel.snp.makeConstraints { make in
            make.leading.equalTo(sceneView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().inset(18)
            make.top.bottom.equalTo(sceneView)
        }

        let type = UILabel()
        type.text = interactionTitle
        type.font = GeoTheme.Typography.caption(size: 11)
        type.textColor = GeoTheme.Color.warning
        let prompt = UILabel()
        prompt.text = task.prompt
        prompt.font = GeoTheme.Typography.heading(size: 16)
        prompt.textColor = GeoTheme.Color.ink
        prompt.numberOfLines = 0

        optionStack.axis = .vertical
        optionStack.spacing = 6
        feedbackLabel.text = nil
        feedbackLabel.font = GeoTheme.Typography.caption(size: 11)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0
        feedbackLabel.isHidden = true

        finishButton.setTitle("记录证据", for: .normal)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.titleLabel?.font = GeoTheme.Typography.control(size: 14)
        finishButton.backgroundColor = GeoTheme.Color.teal
        finishButton.layer.cornerRadius = GeoTheme.Radius.control
        finishButton.isHidden = task.kind != .classification
        finishButton.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        finishButton.snp.makeConstraints { $0.height.equalTo(40) }

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = false
        scroll.contentInsetAdjustmentBehavior = .never
        let contentView = UIView()
        let stack = UIStackView(arrangedSubviews: [type, prompt, optionStack, feedbackLabel, finishButton])
        stack.axis = .vertical
        stack.spacing = 7
        taskPanel.addSubview(scroll)
        scroll.addSubview(contentView)
        contentView.addSubview(stack)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scroll.contentLayoutGuide)
            make.width.equalTo(scroll.frameLayoutGuide)
            make.height.greaterThanOrEqualTo(scroll.frameLayoutGuide)
        }
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(14)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
        contentView.snp.makeConstraints { make in
            make.height.equalTo(stack.snp.height).offset(28).priority(.high)
        }
    }

    private var interactionTitle: String {
        switch task.kind {
        case .hotspot: return "在剖面中定位关键观察点"
        case .classification: return "筛选真正相关的监测记录"
        case .causalOrder: return "按发生顺序连接过程"
        case .singleChoice: return "根据现场现象作出判断"
        }
    }

    private func buildInteraction() {
        if task.kind == .hotspot {
            sceneView.onHotspot = { [weak self] id in self?.evaluateImmediate(id) }
            return
        }
        let displayed = task.kind == .causalOrder
            ? Array(task.options.dropFirst()) + Array(task.options.prefix(1))
            : task.options
        for option in displayed {
            let button = makeOptionButton(option)
            optionButtons[option.id] = button
            optionStack.addArrangedSubview(button)
        }
    }

    private func makeOptionButton(_ option: TransferChallengeOption) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = option.text
        configuration.baseForegroundColor = GeoTheme.Color.ink
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 14, bottom: 5, trailing: 14)
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = GeoTheme.Typography.control(size: 12)
            return updated
        }
        button.configuration = configuration
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.backgroundColor = GeoTheme.Color.paperControl
        button.layer.cornerRadius = GeoTheme.Radius.control
        button.layer.borderWidth = 1
        button.layer.borderColor = GeoTheme.Color.separator.cgColor
        button.accessibilityIdentifier = option.id
        button.addAction(UIAction { [weak self, weak button] _ in
            guard let id = button?.accessibilityIdentifier else { return }
            self?.optionTapped(id)
        }, for: .touchUpInside)
        button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(40) }
        return button
    }

    private func optionTapped(_ id: String) {
        guard !solved else { return }
        switch task.kind {
        case .singleChoice, .hotspot:
            evaluateImmediate(id)
        case .causalOrder:
            evaluateOrder(id)
        case .classification:
            if selectedIds.contains(id) { selectedIds.remove(id) } else { selectedIds.insert(id) }
            for (optionId, button) in optionButtons {
                let selected = selectedIds.contains(optionId)
                button.backgroundColor = selected ? GeoTheme.Color.blue.withAlphaComponent(0.16) : GeoTheme.Color.paperControl
                button.layer.borderColor = selected ? GeoTheme.Color.blue.cgColor : GeoTheme.Color.separator.cgColor
            }
        }
    }

    private func evaluateImmediate(_ id: String) {
        guard !solved else { return }
        if task.correctOptionIds.contains(id) {
            solve()
        } else {
            mistakes += 1
            showError("这个位置不能解释关键现象。继续比较模型中的结构。")
            sceneView.markHotspot(id: id, correct: false)
        }
    }

    private func evaluateOrder(_ id: String) {
        guard task.correctOptionIds.indices.contains(orderIndex) else { return }
        if task.correctOptionIds[orderIndex] == id {
            orderIndex += 1
            if let button = optionButtons[id] {
                button.isEnabled = false
                button.backgroundColor = GeoTheme.Color.success.withAlphaComponent(0.18)
                let originalTitle = button.configuration?.title ?? ""
                var configuration = button.configuration
                configuration?.title = "\(orderIndex). \(originalTitle)"
                configuration?.baseForegroundColor = GeoTheme.Color.success
                button.configuration = configuration
            }
            if orderIndex == task.correctOptionIds.count { solve() }
            else {
                feedbackLabel.isHidden = false
                feedbackLabel.text = "已连接第 \(orderIndex) 步，继续寻找下一段过程。"
                feedbackLabel.textColor = .systemGreen
                sceneView.advanceProcess(to: orderIndex)
            }
        } else {
            mistakes += 1
            showError("顺序还不对。想一想哪一个变化会直接引起下一步。")
            shake(optionButtons[id])
        }
    }

    private func checkClassification() {
        guard !selectedIds.isEmpty else {
            feedbackLabel.isHidden = false
            feedbackLabel.text = "请先选择至少一条监测记录。"
            feedbackLabel.textColor = .systemOrange
            return
        }
        if selectedIds == Set(task.correctOptionIds) { solve() }
        else {
            mistakes += 1
            showError("证据中还混入了无关记录，或漏掉了真正的岩浆活动信号。")
        }
    }

    private func solve() {
        guard !solved else { return }
        solved = true
        optionButtons.values.forEach { $0.isEnabled = false }
        task.correctOptionIds.forEach { sceneView.markHotspot(id: $0, correct: true) }
        sceneView.setSolved(true)
        feedbackLabel.isHidden = false
        feedbackLabel.text = "观察成立：\(task.explanation)"
        feedbackLabel.textColor = GeoTheme.Color.success
        finishButton.isHidden = false
        finishButton.setTitle("完成观察并获得成果", for: .normal)
    }

    private func showError(_ text: String) {
        feedbackLabel.isHidden = false
        feedbackLabel.text = text
        feedbackLabel.textColor = .systemRed
    }

    private func shake(_ view: UIView?) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-6, 6, -4, 4, 0]
        animation.duration = 0.25
        view?.layer.add(animation, forKey: "wrongFieldOption")
    }

    @objc private func finishButtonTapped() {
        if solved {
            let score = mistakes == 0 ? 3 : (mistakes <= 2 ? 2 : 1)
            finish(ChallengeResult(
                challengeId: poi.id,
                completedTaskIds: [task.id],
                observationIds: [task.observationId],
                earnedArtifactIds: [],
                score: score))
        } else if task.kind == .classification {
            checkClassification()
        }
    }

    private func finish(_ result: ChallengeResult?) {
        guard !finished else { return }
        finished = true
        onFinish(result)
    }
}

private final class FieldInvestigationSceneView: UIView {

    var onHotspot: ((String) -> Void)?
    private let sceneKind: String
    private let options: [TransferChallengeOption]
    private var hotspotButtons: [String: UIButton] = [:]
    private var solved = false
    private var processStep = 0

    init(sceneKind: String, options: [TransferChallengeOption]) {
        self.sceneKind = sceneKind
        self.options = options
        super.init(frame: .zero)
        backgroundColor = backgroundColorForScene
        layer.cornerRadius = 20
        clipsToBounds = true
        if sceneKind == "riftSection" { installHotspots() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func markHotspot(id: String, correct: Bool) {
        guard let button = hotspotButtons[id] else { return }
        button.backgroundColor = correct ? .systemGreen : .systemRed
        if correct { button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal) }
    }

    func setSolved(_ solved: Bool) {
        self.solved = solved
        setNeedsDisplay()
    }

    func advanceProcess(to step: Int) {
        processStep = step
        setNeedsDisplay()
    }

    private var backgroundColorForScene: UIColor {
        switch sceneKind {
        case "riftSection": return UIColor(red: 0.62, green: 0.82, blue: 0.83, alpha: 1)
        case "volcanoObservatory": return UIColor(red: 0.28, green: 0.31, blue: 0.34, alpha: 1)
        default: return UIColor(red: 0.31, green: 0.21, blue: 0.19, alpha: 1)
        }
    }

    private func installHotspots() {
        let positions: [(CGFloat, CGFloat)] = [(0.50, 0.58), (0.18, 0.47), (0.78, 0.18)]
        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            button.backgroundColor = UIColor(red: 0.18, green: 0.39, blue: 0.50, alpha: 0.92)
            button.tintColor = .white
            button.setImage(UIImage(systemName: "scope"), for: .normal)
            button.layer.cornerRadius = 18
            button.accessibilityIdentifier = option.id
            button.accessibilityLabel = option.text
            button.addAction(UIAction { [weak self, weak button] _ in
                guard let id = button?.accessibilityIdentifier else { return }
                self?.onHotspot?(id)
            }, for: .touchUpInside)
            addSubview(button)
            hotspotButtons[option.id] = button
            let p = positions[index % positions.count]
            button.snp.makeConstraints { make in
                make.centerX.equalToSuperview().multipliedBy(p.0 * 2)
                make.centerY.equalToSuperview().multipliedBy(p.1 * 2)
                make.width.height.equalTo(36)
            }
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        switch sceneKind {
        case "riftSection": drawRift(context, rect)
        case "volcanoObservatory": drawVolcano(context, rect)
        default: drawMagma(context, rect)
        }
    }

    private func drawRift(_ context: CGContext, _ rect: CGRect) {
        let w = rect.width, h = rect.height
        context.setFillColor(UIColor(red: 0.48, green: 0.31, blue: 0.20, alpha: 1).cgColor)
        context.move(to: CGPoint(x: 0, y: h * 0.42))
        context.addLine(to: CGPoint(x: w * 0.38, y: h * 0.50))
        context.addLine(to: CGPoint(x: w * 0.46, y: h * 0.72))
        context.addLine(to: CGPoint(x: w * 0.58, y: h * 0.72))
        context.addLine(to: CGPoint(x: w * 0.66, y: h * 0.50))
        context.addLine(to: CGPoint(x: w, y: h * 0.40))
        context.addLine(to: CGPoint(x: w, y: h))
        context.addLine(to: CGPoint(x: 0, y: h))
        context.closePath()
        context.fillPath()
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
        context.setLineWidth(solved ? 6 : 3)
        context.move(to: CGPoint(x: w * 0.38, y: h * 0.50))
        context.addLine(to: CGPoint(x: w * 0.46, y: h * 0.84))
        context.move(to: CGPoint(x: w * 0.66, y: h * 0.50))
        context.addLine(to: CGPoint(x: w * 0.58, y: h * 0.84))
        context.strokePath()
    }

    private func drawVolcano(_ context: CGContext, _ rect: CGRect) {
        let w = rect.width, h = rect.height
        context.setFillColor(UIColor(red: 0.34, green: 0.22, blue: 0.18, alpha: 1).cgColor)
        context.move(to: CGPoint(x: w * 0.15, y: h * 0.78))
        context.addLine(to: CGPoint(x: w * 0.48, y: h * 0.24))
        context.addLine(to: CGPoint(x: w * 0.82, y: h * 0.78))
        context.closePath()
        context.fillPath()
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineWidth(solved ? 12 : 7)
        context.move(to: CGPoint(x: w * 0.49, y: h * 0.72))
        context.addLine(to: CGPoint(x: w * 0.49, y: h * 0.29))
        context.strokePath()
        UIColor.white.withAlphaComponent(0.58).setFill()
        context.fillEllipse(in: CGRect(x: w * 0.38, y: h * 0.08, width: w * 0.22, height: h * 0.15))
    }

    private func drawMagma(_ context: CGContext, _ rect: CGRect) {
        let w = rect.width, h = rect.height
        let colors = [UIColor.systemYellow.cgColor, UIColor.systemOrange.cgColor, UIColor.systemRed.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.5, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0), options: [])
        }
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.78).cgColor)
        context.setLineWidth(8)
        context.move(to: CGPoint(x: w * 0.30, y: h * 0.82))
        context.addCurve(to: CGPoint(x: w * 0.66, y: h * 0.18),
                         control1: CGPoint(x: w * 0.52, y: h * 0.68),
                         control2: CGPoint(x: w * 0.45, y: h * 0.38))
        context.strokePath()
        let visibleSteps = solved ? 4 : max(1, processStep)
        for index in 0..<visibleSteps {
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(x: w * (0.26 + CGFloat(index) * 0.12), y: h * (0.78 - CGFloat(index) * 0.18), width: 16, height: 16))
        }
    }
}
