//
//  GeologyDetectiveViewController.swift
//  GeoAdvanture
//
//  Step 9：跨专题连续综合任务。线索在同一座小岛上逐步汇合，结案后才完成圈层学习。
//

import UIKit
import SnapKit

final class GeologyDetectiveViewController: UIViewController {

    private let mission: IntegratedMissionDefinition
    private let onFinish: () -> Void
    private let sceneView = DetectiveIslandSceneView()
    private let contentStack = UIStackView()
    private let stepLabel = UILabel()
    private let feedbackLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private var optionButtons: [UIButton] = []
    private var currentIndex = 0
    private var firstTryCorrectCount = 0
    private var madeMistakeOnCurrentStep = false
    private var isCurrentStepSolved = false
    private var didFinish = false

    init(mission: IntegratedMissionDefinition, onFinish: @escaping () -> Void) {
        self.mission = mission
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderCurrentStep()
    }

    private func setupUI() {
        view.backgroundColor = GeoTheme.Color.darkSurface

        let close = UIButton(type: .system)
        close.configuration = GeoTheme.buttonConfiguration(
            title: "返回知识总结",
            systemImage: "chevron.left",
            style: .overlay)
        close.addAction(UIAction { [weak self] _ in self?.finish() }, for: .touchUpInside)

        let title = UILabel()
        title.text = mission.title
        title.font = GeoTheme.Typography.heading(size: 20)
        title.textColor = GeoTheme.Color.lightText
        title.textAlignment = .center

        let tag = UILabel()
        tag.text = "  最终综合任务  "
        tag.font = GeoTheme.Typography.caption(size: 10)
        tag.textColor = GeoTheme.Color.ink
        tag.backgroundColor = UIColor(red: 0.72, green: 0.89, blue: 0.82, alpha: 1)
        tag.layer.cornerRadius = 10
        tag.clipsToBounds = true
        tag.textAlignment = .center

        let header = UIView()
        header.addSubview(close)
        header.addSubview(title)
        header.addSubview(tag)
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(48)
        }
        close.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
        }
        title.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.42)
        }
        tag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(18)
            make.centerY.equalToSuperview()
            make.height.equalTo(21)
        }

        let panel = UIView()
        panel.backgroundColor = GeoTheme.Color.paper
        panel.layer.cornerRadius = GeoTheme.Radius.modal
        view.addSubview(sceneView)
        view.addSubview(panel)
        sceneView.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.top.equalTo(header.snp.bottom).offset(5)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(14)
            make.width.equalToSuperview().multipliedBy(0.48)
        }
        panel.snp.makeConstraints { make in
            make.leading.equalTo(sceneView.snp.trailing).offset(14)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.top.bottom.equalTo(sceneView)
        }

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        contentStack.axis = .vertical
        contentStack.spacing = 10
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        panel.addSubview(scroll)
        scroll.addSubview(contentStack)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview().inset(5) }
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(15)
            make.width.equalToSuperview().offset(-30)
        }
    }

    private func renderCurrentStep() {
        clearContent()
        guard mission.steps.indices.contains(currentIndex) else {
            renderCaseSummary()
            return
        }

        isCurrentStepSolved = false
        madeMistakeOnCurrentStep = false
        let step = mission.steps[currentIndex]
        sceneView.configure(stepIndex: currentIndex, total: mission.steps.count, solved: false)

        stepLabel.text = "线索 \(currentIndex + 1) / \(mission.steps.count)"
        stepLabel.font = GeoTheme.Typography.heading(size: 12)
        stepLabel.textColor = GeoTheme.Color.clay
        contentStack.addArrangedSubview(stepLabel)

        let prompt = makeLabel(step.prompt, size: 20, weight: .heavy)
        contentStack.addArrangedSubview(prompt)

        let topics = step.topicIds.compactMap { ContentStore.shared.knowledgeTopic(id: $0)?.title }
        let clue = makeLabel("需要联结：" + topics.joined(separator: " × "), size: 11, weight: .semibold)
        clue.textColor = GeoTheme.Color.teal
        contentStack.addArrangedSubview(clue)

        optionButtons = step.options.map { option in
            let button = makeOptionButton(option)
            contentStack.addArrangedSubview(button)
            return button
        }

        feedbackLabel.text = "观察左侧同一座小岛的新变化，再判断这条线索。"
        feedbackLabel.font = GeoTheme.Typography.caption(size: 11)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0
        contentStack.addArrangedSubview(feedbackLabel)

        configureNextButton(title: "下一条线索", hidden: true)
        contentStack.addArrangedSubview(nextButton)
    }

    private func makeOptionButton(_ option: TransferChallengeOption) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(option.text, for: .normal)
        button.setTitleColor(GeoTheme.Color.ink, for: .normal)
        button.titleLabel?.font = GeoTheme.Typography.control(size: 13)
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .left
        button.backgroundColor = GeoTheme.Color.paperControl
        button.layer.cornerRadius = GeoTheme.Radius.control
        button.layer.borderWidth = 1
        button.layer.borderColor = GeoTheme.Color.separator.cgColor
        button.accessibilityIdentifier = option.id
        button.addAction(UIAction { [weak self, weak button] _ in
            guard let id = button?.accessibilityIdentifier else { return }
            self?.chooseOption(id)
        }, for: .touchUpInside)
        button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(42) }
        return button
    }

    private func chooseOption(_ id: String) {
        guard !isCurrentStepSolved, mission.steps.indices.contains(currentIndex) else { return }
        let step = mission.steps[currentIndex]
        guard step.correctOptionIds.contains(id) else {
            madeMistakeOnCurrentStep = true
            feedbackLabel.text = "这条判断还不能解释全部现象。把地貌变化和形成过程连起来再试一次。"
            feedbackLabel.textColor = .systemRed
            optionButtons.first(where: { $0.accessibilityIdentifier == id })?.layer.add(shakeAnimation(), forKey: "wrongClue")
            return
        }

        isCurrentStepSolved = true
        if !madeMistakeOnCurrentStep { firstTryCorrectCount += 1 }
        optionButtons.forEach { button in
            button.isEnabled = false
            if button.accessibilityIdentifier == id {
                button.backgroundColor = GeoTheme.Color.success.withAlphaComponent(0.18)
                button.layer.borderColor = GeoTheme.Color.success.cgColor
            }
        }
        feedbackLabel.text = "线索成立：\(step.explanation)"
        feedbackLabel.textColor = GeoTheme.Color.success
        sceneView.configure(stepIndex: currentIndex, total: mission.steps.count, solved: true)
        nextButton.isHidden = false
        nextButton.setTitle(currentIndex == mission.steps.count - 1 ? "整理线索并结案" : "下一条线索", for: .normal)
    }

    private func advance() {
        guard isCurrentStepSolved else { return }
        currentIndex += 1
        renderCurrentStep()
    }

    private func renderCaseSummary() {
        clearContent()
        let score = mission.steps.isEmpty ? 100 : Int((Double(firstTryCorrectCount) / Double(mission.steps.count)) * 100)
        let saved = LayerCompletionEvaluator.shared.completeMission(id: mission.id, score: max(60, score))
        sceneView.configure(stepIndex: mission.steps.count, total: mission.steps.count, solved: true)

        let seal = UIImageView(image: UIImage(systemName: saved ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"))
        seal.tintColor = saved ? GeoTheme.Color.warning : .systemOrange
        seal.contentMode = .scaleAspectFit
        seal.snp.makeConstraints { $0.height.equalTo(52) }
        contentStack.addArrangedSubview(seal)

        let title = makeLabel(saved ? "神秘小岛调查完成" : "还缺少结案条件", size: 23, weight: .heavy, alignment: .center)
        contentStack.addArrangedSubview(title)
        let subtitle = makeLabel(
            saved ? "你没有孤立地背答案，而是用多个知识解释了同一座小岛的形成。" : "返回地图补齐热点与知识应用后，再来完成调查。",
            size: 12,
            weight: .semibold,
            alignment: .center)
        subtitle.textColor = .secondaryLabel
        contentStack.addArrangedSubview(subtitle)

        if saved {
            for (index, step) in mission.steps.enumerated() {
                let line = makeLabel("\(index + 1). \(step.explanation)", size: 11, weight: .medium)
                line.backgroundColor = UIColor.white.withAlphaComponent(0.46)
                line.layer.cornerRadius = 9
                line.clipsToBounds = true
                contentStack.addArrangedSubview(line)
            }
            let unlocked = makeLabel("地壳学习已完成 · 地幔笔记本已解锁", size: 12, weight: .heavy, alignment: .center)
            unlocked.textColor = GeoTheme.Color.teal
            contentStack.addArrangedSubview(unlocked)
        }

        configureNextButton(title: "返回知识总结", hidden: false)
        contentStack.addArrangedSubview(nextButton)
    }

    private func clearContent() {
        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        optionButtons.removeAll()
    }

    private func configureNextButton(title: String, hidden: Bool) {
        nextButton.setTitle(title, for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = GeoTheme.Typography.control(size: 14)
        nextButton.backgroundColor = GeoTheme.Color.teal
        nextButton.layer.cornerRadius = GeoTheme.Radius.control
        nextButton.isHidden = hidden
        nextButton.snp.makeConstraints { $0.height.equalTo(42) }
    }

    @objc private func nextTapped() {
        currentIndex >= mission.steps.count ? finish() : advance()
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight,
                           alignment: NSTextAlignment = .left) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = size >= 16
            ? GeoTheme.Typography.heading(size: size)
            : GeoTheme.Typography.body(size: size)
        label.textColor = GeoTheme.Color.ink
        label.textAlignment = alignment
        label.numberOfLines = 0
        return label
    }

    private func shakeAnimation() -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-7, 7, -4, 4, 0]
        animation.duration = 0.25
        return animation
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinish()
    }
}

/// 同一场景随调查推进逐步补齐：裂谷 → 岩浆通道与火山 → 熔岩冷却岩石。
private final class DetectiveIslandSceneView: UIView {

    private var stepIndex = 0
    private var total = 3
    private var solved = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.26, green: 0.60, blue: 0.70, alpha: 1)
        layer.cornerRadius = 24
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(stepIndex: Int, total: Int, solved: Bool) {
        self.stepIndex = stepIndex
        self.total = max(1, total)
        self.solved = solved
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let w = rect.width
        let h = rect.height

        UIColor(red: 0.15, green: 0.47, blue: 0.62, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.38))

        UIColor(red: 0.34, green: 0.48, blue: 0.25, alpha: 1).setFill()
        context.move(to: CGPoint(x: w * 0.08, y: h * 0.68))
        context.addCurve(to: CGPoint(x: w * 0.92, y: h * 0.68),
                         control1: CGPoint(x: w * 0.23, y: h * 0.49),
                         control2: CGPoint(x: w * 0.72, y: h * 0.47))
        context.addLine(to: CGPoint(x: w * 0.84, y: h * 0.82))
        context.addLine(to: CGPoint(x: w * 0.16, y: h * 0.82))
        context.closePath()
        context.fillPath()

        drawRift(context, w: w, h: h)
        if stepIndex >= 1 { drawVolcano(context, w: w, h: h) }
        if stepIndex >= 2 { drawRock(context, w: w, h: h) }
        drawProgress(context, rect: rect)
    }

    private func drawRift(_ context: CGContext, w: CGFloat, h: CGFloat) {
        context.setStrokeColor(UIColor(red: 0.30, green: 0.19, blue: 0.12, alpha: 1).cgColor)
        context.setLineWidth(solved && stepIndex == 0 ? 7 : 4)
        context.move(to: CGPoint(x: w * 0.43, y: h * 0.52))
        context.addLine(to: CGPoint(x: w * 0.48, y: h * 0.68))
        context.addLine(to: CGPoint(x: w * 0.45, y: h * 0.79))
        context.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .heavy), .foregroundColor: UIColor.white]
        NSString(string: "裂谷线索").draw(at: CGPoint(x: w * 0.29, y: h * 0.84), withAttributes: attrs)
    }

    private func drawVolcano(_ context: CGContext, w: CGFloat, h: CGFloat) {
        UIColor(red: 0.31, green: 0.24, blue: 0.20, alpha: 1).setFill()
        context.move(to: CGPoint(x: w * 0.55, y: h * 0.64))
        context.addLine(to: CGPoint(x: w * 0.69, y: h * 0.31))
        context.addLine(to: CGPoint(x: w * 0.84, y: h * 0.64))
        context.closePath()
        context.fillPath()
        context.setStrokeColor(UIColor(red: 0.91, green: 0.29, blue: 0.12, alpha: 1).cgColor)
        context.setLineWidth(solved && stepIndex == 1 ? 9 : 6)
        context.move(to: CGPoint(x: w * 0.70, y: h * 0.69))
        context.addLine(to: CGPoint(x: w * 0.70, y: h * 0.37))
        context.strokePath()
    }

    private func drawRock(_ context: CGContext, w: CGFloat, h: CGFloat) {
        let rockRect = CGRect(x: w * 0.67, y: h * 0.70, width: w * 0.14, height: h * 0.10)
        context.setFillColor(UIColor(red: 0.15, green: 0.16, blue: 0.18, alpha: 1).cgColor)
        context.fillEllipse(in: rockRect)
        if solved && stepIndex >= 2 {
            context.setStrokeColor(UIColor(red: 0.98, green: 0.75, blue: 0.27, alpha: 1).cgColor)
            context.setLineWidth(4)
            context.strokeEllipse(in: rockRect.insetBy(dx: -4, dy: -4))
        }
    }

    private func drawProgress(_ context: CGContext, rect: CGRect) {
        let count = total
        let gap: CGFloat = 12
        let diameter: CGFloat = 10
        let fullWidth = CGFloat(count) * diameter + CGFloat(count - 1) * gap
        let startX = (rect.width - fullWidth) / 2
        for index in 0..<count {
            let active = index < stepIndex || (index == stepIndex && solved) || stepIndex >= total
            context.setFillColor((active ? UIColor.systemYellow : UIColor.white.withAlphaComponent(0.35)).cgColor)
            context.fillEllipse(in: CGRect(x: startX + CGFloat(index) * (diameter + gap), y: 18, width: diameter, height: diameter))
        }
    }
}
