//
//  TransferChallengeViewController.swift
//  GeoAdvanture
//
//  Step 8：把已经理解的知识迁移到新情境。支持单选、因果排序、热点与分类。
//

import UIKit
import SnapKit

final class TransferChallengeViewController: UIViewController {

    private let challenge: TransferChallengeDefinition
    private let onFinish: () -> Void
    private let feedbackLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let optionsContainer = UIStackView()
    private var optionButtons: [String: UIButton] = [:]
    private var selectedIds = Set<String>()
    private var orderIndex = 0
    private var mistakes = 0
    private var isSolved = false
    private var didFinish = false

    init(challenge: TransferChallengeDefinition, onFinish: @escaping () -> Void) {
        self.challenge = challenge
        self.onFinish = onFinish
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
        view.backgroundColor = UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
        let paper = UIView()
        paper.backgroundColor = UIColor(red: 0.97, green: 0.92, blue: 0.81, alpha: 1)
        paper.layer.cornerRadius = 28
        view.addSubview(paper)
        paper.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide).inset(12) }

        let close = UIButton(type: .system)
        close.setTitle("‹ 返回知识总结", for: .normal)
        close.setTitleColor(UIColor(red: 0.31, green: 0.23, blue: 0.18, alpha: 1), for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        close.addAction(UIAction { [weak self] _ in self?.finish() }, for: .touchUpInside)

        let tag = UILabel()
        tag.text = "  知识应用 · 约 30 秒  "
        tag.font = .systemFont(ofSize: 11, weight: .heavy)
        tag.textColor = .white
        tag.textAlignment = .center
        tag.backgroundColor = UIColor(red: 0.34, green: 0.57, blue: 0.43, alpha: 1)
        tag.layer.cornerRadius = 10
        tag.clipsToBounds = true

        paper.addSubview(close)
        paper.addSubview(tag)
        close.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(30)
        }
        tag.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(close)
            make.height.equalTo(22)
        }

        let visual = makeScenarioVisual()
        let taskPanel = UIView()
        taskPanel.backgroundColor = UIColor.white.withAlphaComponent(0.48)
        taskPanel.layer.cornerRadius = 20
        taskPanel.layer.borderWidth = 1
        taskPanel.layer.borderColor = UIColor(red: 0.49, green: 0.36, blue: 0.25, alpha: 0.18).cgColor
        paper.addSubview(visual)
        paper.addSubview(taskPanel)
        visual.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalTo(close.snp.bottom).offset(8)
            make.bottom.equalToSuperview().inset(16)
            make.width.equalToSuperview().multipliedBy(0.38)
        }
        taskPanel.snp.makeConstraints { make in
            make.leading.equalTo(visual.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(18)
            make.top.bottom.equalTo(visual)
        }

        let typeLabel = UILabel()
        typeLabel.text = interactionTitle
        typeLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        typeLabel.textColor = UIColor(red: 0.48, green: 0.34, blue: 0.22, alpha: 1)

        let prompt = UILabel()
        prompt.text = challenge.prompt
        prompt.font = .systemFont(ofSize: 19, weight: .heavy)
        prompt.textColor = UIColor(red: 0.27, green: 0.20, blue: 0.16, alpha: 1)
        prompt.numberOfLines = 0

        optionsContainer.axis = .vertical
        optionsContainer.spacing = 8
        optionsContainer.distribution = .fillEqually

        feedbackLabel.text = initialHint
        feedbackLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0

        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        actionButton.backgroundColor = UIColor(red: 0.33, green: 0.58, blue: 0.43, alpha: 1)
        actionButton.layer.cornerRadius = 14
        actionButton.addAction(UIAction { [weak self] _ in self?.primaryTapped() }, for: .touchUpInside)
        actionButton.snp.makeConstraints { $0.height.equalTo(40) }

        let taskScroll = UIScrollView()
        taskScroll.showsVerticalScrollIndicator = false
        taskPanel.addSubview(taskScroll)
        taskScroll.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }

        let stack = UIStackView(arrangedSubviews: [typeLabel, prompt, optionsContainer, feedbackLabel, actionButton])
        stack.axis = .vertical
        stack.spacing = 9
        stack.setCustomSpacing(3, after: typeLabel)
        taskScroll.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
            make.width.equalToSuperview().offset(-24)
        }
    }

    private var interactionTitle: String {
        switch challenge.kind {
        case .singleChoice: return "情境判断"
        case .causalOrder: return "现场记录排序"
        case .hotspot: return "剖面热点定位"
        case .classification: return "样本与线索分类"
        }
    }

    private var initialHint: String {
        switch challenge.kind {
        case .singleChoice: return "选择最符合因果关系的结果。"
        case .causalOrder: return "从最先发生的记录开始依次点击。"
        case .hotspot: return "根据构造环境轻点最合理的位置。"
        case .classification: return "可以选择多项，选好后检查答案。"
        }
    }

    private func makeScenarioVisual() -> UIView {
        let visual = UIView()
        visual.backgroundColor = UIColor(red: 0.25, green: 0.43, blue: 0.46, alpha: 1)
        visual.layer.cornerRadius = 20
        visual.clipsToBounds = true

        let circle = UIView()
        circle.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        circle.layer.cornerRadius = 86
        let icon = UIImageView(image: UIImage(systemName: scenarioSymbol))
        icon.tintColor = UIColor(red: 0.96, green: 0.79, blue: 0.38, alpha: 1)
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = "陌生地点勘察任务\n不能照搬原关卡答案"
        label.font = .systemFont(ofSize: 14, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        visual.addSubview(circle)
        visual.addSubview(icon)
        visual.addSubview(label)
        circle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-25)
            make.width.height.equalTo(172)
        }
        icon.snp.makeConstraints { make in
            make.center.equalTo(circle)
            make.width.height.equalTo(92)
        }
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(22)
        }
        return visual
    }

    private var scenarioSymbol: String {
        switch challenge.topicId {
        case "harvest_movement": return "mountain.2.fill"
        case "harvest_rock": return "circle.hexagongrid.fill"
        case "harvest_crack": return "arrow.left.and.right"
        case "harvest_diamond": return "diamond.fill"
        case "harvest_volcano": return "volcano.fill"
        default: return "drop.triangle.fill"
        }
    }

    private func buildInteraction() {
        optionButtons.removeAll()
        if challenge.kind == .hotspot {
            let board = TransferHotspotBoardView(options: challenge.options) { [weak self] id in
                self?.evaluateImmediate(optionId: id)
            }
            optionsContainer.addArrangedSubview(board)
            board.snp.makeConstraints { $0.height.equalTo(155) }
        } else {
            let displayed = challenge.kind == .causalOrder
                ? Array(challenge.options.dropFirst()) + Array(challenge.options.prefix(1))
                : challenge.options
            for option in displayed {
                let button = makeOptionButton(option)
                optionButtons[option.id] = button
                optionsContainer.addArrangedSubview(button)
            }
        }

        actionButton.isHidden = challenge.kind != .classification
        actionButton.setTitle("检查分类", for: .normal)
    }

    private func makeOptionButton(_ option: TransferChallengeOption) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(option.text, for: .normal)
        button.setTitleColor(UIColor(red: 0.28, green: 0.22, blue: 0.18, alpha: 1), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .left
        button.backgroundColor = UIColor.white.withAlphaComponent(0.66)
        button.layer.cornerRadius = 11
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.48, green: 0.35, blue: 0.24, alpha: 0.20).cgColor
        button.accessibilityIdentifier = option.id
        button.addAction(UIAction { [weak self, weak button] _ in
            guard let self, let id = button?.accessibilityIdentifier else { return }
            self.optionTapped(id: id)
        }, for: .touchUpInside)
        button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(38) }
        return button
    }

    private func optionTapped(id: String) {
        guard !isSolved else { return }
        switch challenge.kind {
        case .singleChoice:
            evaluateImmediate(optionId: id)
        case .causalOrder:
            evaluateOrder(optionId: id)
        case .classification:
            if selectedIds.contains(id) {
                selectedIds.remove(id)
            } else {
                selectedIds.insert(id)
            }
            updateClassificationButtons()
        case .hotspot:
            break
        }
    }

    private func evaluateImmediate(optionId: String) {
        guard !isSolved else { return }
        if challenge.correctOptionIds.contains(optionId) {
            solve()
        } else {
            mistakes += 1
            showError("这条线索不能解释题目中的地质环境。\n\(challenge.explanation)")
            markWrong(optionId)
        }
    }

    private func evaluateOrder(optionId: String) {
        guard challenge.correctOptionIds.indices.contains(orderIndex) else { return }
        if challenge.correctOptionIds[orderIndex] == optionId {
            orderIndex += 1
            if let button = optionButtons[optionId] {
                button.isEnabled = false
                button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.18)
                button.setTitle("\(orderIndex). \(button.title(for: .normal) ?? "")", for: .disabled)
                button.setTitleColor(UIColor(red: 0.20, green: 0.45, blue: 0.29, alpha: 1), for: .disabled)
            }
            if orderIndex == challenge.correctOptionIds.count {
                solve()
            } else {
                feedbackLabel.text = "正确，继续寻找第 \(orderIndex + 1) 条记录。"
                feedbackLabel.textColor = .systemGreen
            }
        } else {
            mistakes += 1
            showError("这条记录还不能接在这里。想一想：哪一步会直接造成下一步？\n\(challenge.explanation)")
            markWrong(optionId)
        }
    }

    private func updateClassificationButtons() {
        for (id, button) in optionButtons {
            let selected = selectedIds.contains(id)
            button.backgroundColor = selected
                ? UIColor.systemBlue.withAlphaComponent(0.16)
                : UIColor.white.withAlphaComponent(0.66)
            button.layer.borderColor = selected
                ? UIColor.systemBlue.cgColor
                : UIColor(red: 0.48, green: 0.35, blue: 0.24, alpha: 0.20).cgColor
        }
    }

    private func checkClassification() {
        guard !selectedIds.isEmpty else {
            feedbackLabel.text = "请先选择至少一条记录。"
            feedbackLabel.textColor = .systemOrange
            return
        }
        if selectedIds == Set(challenge.correctOptionIds) {
            solve()
        } else {
            mistakes += 1
            showError("分类中还混入了不符合条件的线索，或漏掉了正确项。\n\(challenge.explanation)")
        }
    }

    private func solve() {
        guard !isSolved else { return }
        isSolved = true
        optionButtons.values.forEach { $0.isEnabled = false }
        feedbackLabel.text = "应用成功！\n\(challenge.explanation)"
        feedbackLabel.textColor = UIColor(red: 0.20, green: 0.48, blue: 0.30, alpha: 1)
        actionButton.isHidden = false
        actionButton.setTitle("完成并返回", for: .normal)
        LearningProgressCoordinator.shared.recordApplication(
            topicId: challenge.topicId,
            score: max(60, 100 - mistakes * 15))
    }

    private func showError(_ message: String) {
        feedbackLabel.text = message
        feedbackLabel.textColor = .systemRed
    }

    private func markWrong(_ id: String) {
        guard let button = optionButtons[id] else { return }
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [-6, 6, -4, 4, 0]
        shake.duration = 0.25
        button.layer.add(shake, forKey: "wrongTransferOption")
    }

    private func primaryTapped() {
        if isSolved {
            finish()
        } else if challenge.kind == .classification {
            checkClassification()
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinish()
    }
}

private final class TransferHotspotBoardView: UIView {

    private let options: [TransferChallengeOption]
    private let onTap: (String) -> Void

    init(options: [TransferChallengeOption], onTap: @escaping (String) -> Void) {
        self.options = options
        self.onTap = onTap
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.58, green: 0.78, blue: 0.82, alpha: 1)
        layer.cornerRadius = 14
        clipsToBounds = true

        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.filled()
            configuration.title = option.text
            configuration.image = UIImage(systemName: "mappin.circle.fill")
            configuration.imagePadding = 4
            configuration.baseBackgroundColor = UIColor(red: 0.45, green: 0.29, blue: 0.17, alpha: 0.90)
            configuration.baseForegroundColor = .white
            configuration.cornerStyle = .capsule
            button.configuration = configuration
            button.titleLabel?.font = .systemFont(ofSize: 10, weight: .bold)
            button.accessibilityIdentifier = option.id
            button.addAction(UIAction { [weak self, weak button] _ in
                guard let id = button?.accessibilityIdentifier else { return }
                self?.onTap(id)
            }, for: .touchUpInside)
            addSubview(button)
            let positions: [(CGFloat, CGFloat)] = [(0.63, 0.20), (0.18, 0.66), (0.68, 0.74)]
            let point = positions[index % positions.count]
            button.snp.makeConstraints { make in
                make.centerX.equalToSuperview().multipliedBy(point.0 * 2)
                make.centerY.equalToSuperview().multipliedBy(point.1 * 2)
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.55)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor(red: 0.52, green: 0.34, blue: 0.20, alpha: 1).cgColor)
        context.move(to: CGPoint(x: rect.width * 0.32, y: rect.height))
        context.addLine(to: CGPoint(x: rect.width * 0.56, y: rect.height * 0.44))
        context.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.30))
        context.addLine(to: CGPoint(x: rect.width, y: rect.height))
        context.closePath()
        context.fillPath()

        context.setStrokeColor(UIColor(red: 0.22, green: 0.34, blue: 0.42, alpha: 1).cgColor)
        context.setLineWidth(10)
        context.move(to: CGPoint(x: rect.width * 0.08, y: rect.height * 0.42))
        context.addCurve(
            to: CGPoint(x: rect.width * 0.67, y: rect.height * 0.90),
            control1: CGPoint(x: rect.width * 0.32, y: rect.height * 0.47),
            control2: CGPoint(x: rect.width * 0.40, y: rect.height * 0.82))
        context.strokePath()
    }
}
