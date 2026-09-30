//
//  KnowledgeSummaryComponents.swift
//  GeoAdvanture
//
//  Step 7 知识总结页的专题入口、关系图、证据条与因果整理组件。
//

import UIKit
import SnapKit

final class KnowledgeConclusionView: UIView {

    init(steps: [CausalStep], understood: Bool) {
        super.init(frame: .zero)
        backgroundColor = understood
            ? UIColor(red: 0.84, green: 0.92, blue: 0.84, alpha: 0.82)
            : UIColor(white: 0.90, alpha: 0.72)
        layer.cornerRadius = 13
        layer.borderWidth = 1
        layer.borderColor = (understood ? UIColor.systemGreen : UIColor.systemGray3).withAlphaComponent(0.55).cgColor

        let icon = UIImageView(image: UIImage(systemName: understood ? "checkmark.seal.fill" : "ellipsis.bubble.fill"))
        icon.tintColor = understood ? .systemGreen : .systemGray
        let label = UILabel()
        if understood {
            let chain = steps.map(\.text).joined(separator: " → ")
            label.text = "结论：\(chain)"
        } else {
            label.text = "排好过程后，这里会显示关键结论。"
        }
        label.font = GeoTheme.Typography.body(size: 11)
        label.textColor = GeoTheme.Color.ink
        label.numberOfLines = 0
        addSubview(icon)
        addSubview(label)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(11)
            make.centerY.equalTo(label)
            make.width.height.equalTo(21)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(9)
            make.trailing.equalToSuperview().inset(11)
            make.top.bottom.equalToSuperview().inset(9)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class KnowledgeMisconceptionDisclosureView: UIControl {

    private let body = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
    private var expanded = false

    init(text: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.94, green: 0.84, blue: 0.69, alpha: 0.45)
        layer.cornerRadius = 12

        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.bubble.fill"))
        icon.tintColor = GeoTheme.Color.warning
        let title = UILabel()
        title.text = "常见误区"
        title.font = GeoTheme.Typography.heading(size: 12)
        title.textColor = GeoTheme.Color.ink
        chevron.tintColor = title.textColor
        body.text = text
        body.font = GeoTheme.Typography.body(size: 11)
        body.textColor = GeoTheme.Color.inkMuted
        body.numberOfLines = 0
        body.isHidden = true

        let header = UIStackView(arrangedSubviews: [icon, title, chevron])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 7
        icon.snp.makeConstraints { $0.width.height.equalTo(18) }
        chevron.snp.makeConstraints { $0.width.equalTo(13) }
        let stack = UIStackView(arrangedSubviews: [header, body])
        stack.axis = .vertical
        stack.spacing = 7
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(10) }
        addAction(UIAction { [weak self] _ in self?.toggle() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func toggle() {
        expanded.toggle()
        body.isHidden = !expanded
        chevron.image = UIImage(systemName: expanded ? "chevron.up" : "chevron.down")
        UIView.animate(withDuration: 0.2) { self.superview?.layoutIfNeeded() }
    }
}

final class KnowledgeTopicListItemView: UIControl {

    private let titleLabel = UILabel()
    private let stageLabel = UILabel()
    private let dot = UIView()
    private(set) var topicId = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = GeoTheme.Radius.control
        layer.borderWidth = 1

        titleLabel.font = GeoTheme.Typography.heading(size: 13)
        titleLabel.numberOfLines = 1
        stageLabel.font = GeoTheme.Typography.caption(size: 10)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, stageLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        addSubview(dot)
        addSubview(textStack)
        dot.layer.cornerRadius = 5
        dot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(11)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(10)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { $0.height.equalTo(48) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ data: KnowledgeTopicListItemData, selected: Bool) {
        topicId = data.id
        titleLabel.text = data.title
        let appearance = KnowledgeStageAppearance(data.stage)
        stageLabel.text = appearance.title + (data.hasUnreadContent ? " · 新" : "")
        stageLabel.textColor = appearance.color
        dot.backgroundColor = appearance.color
        titleLabel.textColor = data.stage == .locked
            ? UIColor(white: 0.48, alpha: 1)
            : GeoTheme.Color.ink
        backgroundColor = selected
            ? UIColor(red: 0.90, green: 0.77, blue: 0.51, alpha: 0.72)
            : GeoTheme.Color.paperCard
        layer.borderColor = selected
            ? UIColor(red: 0.59, green: 0.40, blue: 0.20, alpha: 0.65).cgColor
            : GeoTheme.Color.separator.cgColor
    }
}

final class KnowledgeRelationGraphView: UIView {

    var onSelectTopic: ((String) -> Void)?

    private var topics: [KnowledgeTopicListItemData] = []
    private var edges: [KnowledgeRelationEdge] = []
    private var nodes: [String: UIButton] = [:]
    private let lineLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = GeoTheme.Color.paperCard.withAlphaComponent(0.62)
        layer.cornerRadius = GeoTheme.Radius.card
        lineLayer.strokeColor = GeoTheme.Color.inkMuted.withAlphaComponent(0.42).cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 2
        layer.addSublayer(lineLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func render(topics: [KnowledgeTopicListItemData], edges: [KnowledgeRelationEdge]) {
        self.topics = topics
        self.edges = edges
        nodes.values.forEach { $0.removeFromSuperview() }
        nodes.removeAll()

        for topic in topics {
            let button = UIButton(type: .system)
            button.setTitle(topic.stage >= .applied ? "✓ \(topic.title)" : topic.title, for: .normal)
            button.titleLabel?.font = GeoTheme.Typography.caption(size: 9)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.72
            switch topic.stage {
            case .locked:
                button.backgroundColor = GeoTheme.Color.locked
            case .discovered:
                button.backgroundColor = GeoTheme.Color.success
            case .understood:
                button.backgroundColor = GeoTheme.Color.blue
            case .applied:
                button.backgroundColor = GeoTheme.Color.warning
            }
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 11
            button.accessibilityIdentifier = topic.id
            button.addAction(UIAction { [weak self, weak button] _ in
                guard let id = button?.accessibilityIdentifier else { return }
                self?.onSelectTopic?(id)
            }, for: .touchUpInside)
            addSubview(button)
            nodes[topic.id] = button
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lineLayer.frame = bounds
        guard !topics.isEmpty else { return }
        let columns = 2
        let rows = Int(ceil(Double(topics.count) / Double(columns)))
        let horizontalInset: CGFloat = 10
        let verticalInset: CGFloat = 9
        let gapX: CGFloat = 10
        let gapY: CGFloat = 8
        let nodeWidth = (bounds.width - horizontalInset * 2 - gapX) / 2
        let nodeHeight = min(27, (bounds.height - verticalInset * 2 - gapY * CGFloat(max(0, rows - 1))) / CGFloat(rows))

        for (index, topic) in topics.enumerated() {
            let row = index / columns
            let column = index % columns
            nodes[topic.id]?.frame = CGRect(
                x: horizontalInset + CGFloat(column) * (nodeWidth + gapX),
                y: verticalInset + CGFloat(row) * (nodeHeight + gapY),
                width: nodeWidth,
                height: nodeHeight)
        }

        let path = UIBezierPath()
        for edge in edges {
            guard let from = nodes[edge.fromId], let to = nodes[edge.toId] else { continue }
            path.move(to: from.center)
            path.addLine(to: to.center)
        }
        lineLayer.path = path.cgPath
    }
}

final class KnowledgeEvidenceStripView: UIView {

    init(items: [KnowledgeEvidenceViewData]) {
        super.init(frame: .zero)

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        addSubview(scroll)
        scroll.addSubview(row)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        for item in items {
            let card = UIView()
            card.backgroundColor = item.isCollected
                ? UIColor(red: 0.84, green: 0.92, blue: 0.84, alpha: 1)
                : UIColor(white: 0.88, alpha: 1)
            card.layer.cornerRadius = 12
            card.layer.borderWidth = 1
            card.layer.borderColor = (item.isCollected ? UIColor.systemGreen : UIColor.systemGray3).cgColor

            let icon = UIImageView(image: UIImage(systemName: item.isCollected ? "checkmark.seal.fill" : "lock.fill"))
            icon.tintColor = item.isCollected ? .systemGreen : .systemGray
            let title = UILabel()
            title.text = item.title
            title.font = GeoTheme.Typography.heading(size: 11)
            title.textColor = GeoTheme.Color.ink
            title.numberOfLines = 1
            let kind = UILabel()
            kind.text = item.isCollected ? item.kindLabel : "尚未取得"
            kind.font = GeoTheme.Typography.caption(size: 9)
            kind.textColor = .secondaryLabel
            let labels = UIStackView(arrangedSubviews: [title, kind])
            labels.axis = .vertical
            labels.spacing = 1
            card.addSubview(icon)
            card.addSubview(labels)
            icon.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(9)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(20)
            }
            labels.snp.makeConstraints { make in
                make.leading.equalTo(icon.snp.trailing).offset(7)
                make.trailing.equalToSuperview().inset(9)
                make.centerY.equalToSuperview()
            }
            card.snp.makeConstraints { make in
                make.width.equalTo(145)
                make.height.equalTo(54)
            }
            row.addArrangedSubview(card)
        }
        snp.makeConstraints { $0.height.equalTo(54) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class CausalOrderView: UIView {

    var onCompleted: (() -> Void)?

    private let orderedSteps: [CausalStep]
    private var nextIndex = 0
    private let instructionLabel = UILabel()
    private let buttonsStack = UIStackView()

    init(steps: [CausalStep], alreadyUnderstood: Bool) {
        orderedSteps = steps
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.91, green: 0.86, blue: 0.74, alpha: 0.55)
        layer.cornerRadius = 14

        instructionLabel.text = alreadyUnderstood ? "✓ 形成过程已整理" : "按发生顺序点击，拼出形成过程"
        instructionLabel.font = GeoTheme.Typography.heading(size: 12)
        instructionLabel.textColor = alreadyUnderstood ? GeoTheme.Color.success : GeoTheme.Color.ink
        instructionLabel.numberOfLines = 0

        buttonsStack.axis = .vertical
        buttonsStack.spacing = 6
        let displayed = alreadyUnderstood ? [] : Array(steps.dropFirst()) + Array(steps.prefix(1))
        for (index, step) in displayed.enumerated() {
            if alreadyUnderstood {
                let label = UILabel()
                label.text = "\(index + 1). \(step.text)"
                label.font = GeoTheme.Typography.body(size: 11)
                label.textColor = GeoTheme.Color.ink
                label.numberOfLines = 0
                buttonsStack.addArrangedSubview(label)
            } else {
                let button = UIButton(type: .system)
                button.setTitle(step.text, for: .normal)
                button.setTitleColor(GeoTheme.Color.ink, for: .normal)
                button.titleLabel?.font = GeoTheme.Typography.control(size: 11)
                button.titleLabel?.numberOfLines = 2
                button.contentHorizontalAlignment = .left
                button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
                button.backgroundColor = GeoTheme.Color.paperControl
                button.layer.cornerRadius = GeoTheme.Radius.control
                button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(38) }
                button.accessibilityIdentifier = step.id
                button.addAction(UIAction { [weak self, weak button] _ in
                    guard let id = button?.accessibilityIdentifier else { return }
                    self?.select(stepId: id, button: button)
                }, for: .touchUpInside)
                buttonsStack.addArrangedSubview(button)
            }
        }

        let stack = UIStackView(arrangedSubviews: [instructionLabel, buttonsStack])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func select(stepId: String, button: UIButton?) {
        guard orderedSteps.indices.contains(nextIndex) else { return }
        guard orderedSteps[nextIndex].id == stepId else {
            instructionLabel.text = "顺序还不对：先找出导致后续变化的那一步。"
            instructionLabel.textColor = .systemRed
            let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
            shake.values = [-5, 5, -4, 4, 0]
            shake.duration = 0.24
            button?.layer.add(shake, forKey: "wrongOrder")
            return
        }

        nextIndex += 1
        button?.isEnabled = false
        button?.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.18)
        button?.setTitle("\(nextIndex). \(button?.title(for: .normal) ?? "")", for: .disabled)
        button?.setTitleColor(UIColor(red: 0.20, green: 0.45, blue: 0.29, alpha: 1), for: .disabled)
        if nextIndex == orderedSteps.count {
            instructionLabel.text = "✓ 整理完成，你已经能解释这条因果链"
            instructionLabel.textColor = GeoTheme.Color.success
            onCompleted?()
        } else {
            instructionLabel.text = "正确，再找第 \(nextIndex + 1) 步"
            instructionLabel.textColor = GeoTheme.Color.success
        }
    }
}

private struct KnowledgeStageAppearance {
    let title: String
    let color: UIColor

    init(_ stage: KnowledgeMasteryStage) {
        switch stage {
        case .locked:
            title = "待发现"
            color = GeoTheme.Color.locked
        case .discovered:
            title = "已发现"
            color = GeoTheme.Color.success
        case .understood:
            title = "已理解"
            color = GeoTheme.Color.blue
        case .applied:
            title = "会应用"
            color = GeoTheme.Color.warning
        }
    }
}

/// 总结页内的知识应用题：选项纵向排列，原地作答和反馈，不再跳出知识页。
private final class InlineTransferChallengeView: UIView {

    private let challenge: TransferChallengeDefinition
    private let isInteractionEnabledForProgress: Bool
    private let recordsProgress: Bool
    private let optionStack = UIStackView()
    private let answerHintLabel = UILabel()
    private let checkButton = UIButton(type: .system)
    private var optionButtons: [String: UIButton] = [:]
    private var selectedIds = Set<String>()
    private var nextOrderIndex = 0
    private var mistakes = 0
    private var solved = false
    var onSolved: (() -> Void)?

    init(challenge: TransferChallengeDefinition, enabled: Bool, recordsProgress: Bool = true) {
        self.challenge = challenge
        self.isInteractionEnabledForProgress = enabled
        self.recordsProgress = recordsProgress
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = GeoTheme.Color.paperCard
        layer.cornerRadius = GeoTheme.Radius.card
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.35, green: 0.55, blue: 0.43, alpha: 0.25).cgColor

        let prompt = UILabel()
        prompt.text = challenge.prompt
        prompt.font = GeoTheme.Typography.heading(size: 14)
        prompt.textColor = GeoTheme.Color.ink
        prompt.numberOfLines = 2

        answerHintLabel.text = "选择答案"
        answerHintLabel.font = GeoTheme.Typography.caption(size: 10)
        answerHintLabel.textColor = GeoTheme.Color.teal
        answerHintLabel.numberOfLines = 2

        optionStack.axis = .vertical
        optionStack.spacing = 6

        for option in challenge.options {
            let button = makeOptionButton(option)
            optionButtons[option.id] = button
            optionStack.addArrangedSubview(button)
        }

        checkButton.setTitle("检查选择", for: .normal)
        checkButton.setTitleColor(.white, for: .normal)
        checkButton.titleLabel?.font = GeoTheme.Typography.control(size: 12)
        checkButton.backgroundColor = GeoTheme.Color.teal
        checkButton.layer.cornerRadius = GeoTheme.Radius.control
        checkButton.isHidden = challenge.kind != .classification
        checkButton.isEnabled = isInteractionEnabledForProgress
        checkButton.alpha = isInteractionEnabledForProgress ? 1 : 0.5
        checkButton.addTarget(self, action: #selector(checkSelection), for: .touchUpInside)

        let contentStack = UIStackView(arrangedSubviews: [prompt, answerHintLabel, optionStack, checkButton])
        contentStack.axis = .vertical
        contentStack.spacing = 7
        contentStack.setCustomSpacing(4, after: prompt)
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }
        checkButton.snp.makeConstraints { make in
            make.height.equalTo(34)
        }
    }

    private func makeOptionButton(_ option: TransferChallengeOption) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(option.text, for: .normal)
        button.setTitleColor(GeoTheme.Color.ink, for: .normal)
        button.setTitleColor(GeoTheme.Color.inkMuted, for: .disabled)
        button.titleLabel?.font = GeoTheme.Typography.control(size: 11)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.backgroundColor = GeoTheme.Color.paperControl
        button.layer.cornerRadius = GeoTheme.Radius.control
        button.layer.borderWidth = 1
        button.layer.borderColor = GeoTheme.Color.separator.cgColor
        button.accessibilityIdentifier = option.id
        button.isEnabled = isInteractionEnabledForProgress
        button.alpha = isInteractionEnabledForProgress ? 1 : 0.5
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        button.snp.makeConstraints { $0.height.equalTo(38) }
        return button
    }

    @objc private func optionTapped(_ sender: UIButton) {
        guard !solved, let id = sender.accessibilityIdentifier else { return }
        switch challenge.kind {
        case .singleChoice, .hotspot:
            evaluateImmediate(id)
        case .causalOrder:
            evaluateOrder(id)
        case .classification:
            if selectedIds.contains(id) { selectedIds.remove(id) } else { selectedIds.insert(id) }
            refreshSelection()
        }
    }

    private func evaluateImmediate(_ id: String) {
        if challenge.correctOptionIds.contains(id) {
            solve()
        } else {
            mistakes += 1
            showRetry("再观察题目中的地质条件。")
        }
    }

    private func evaluateOrder(_ id: String) {
        guard challenge.correctOptionIds.indices.contains(nextOrderIndex) else { return }
        if challenge.correctOptionIds[nextOrderIndex] == id {
            nextOrderIndex += 1
            optionButtons[id]?.isEnabled = false
            optionButtons[id]?.backgroundColor = GeoTheme.Color.success.withAlphaComponent(0.18)
            if nextOrderIndex == challenge.correctOptionIds.count {
                solve()
            } else {
                answerHintLabel.text = "正确，继续选择第 \(nextOrderIndex + 1) 步"
                answerHintLabel.textColor = GeoTheme.Color.teal
            }
        } else {
            mistakes += 1
            showRetry("这一步还不能接在这里。")
        }
    }

    @objc private func checkSelection() {
        guard !solved else { return }
        if selectedIds == Set(challenge.correctOptionIds) {
            solve()
        } else {
            mistakes += 1
            showRetry(selectedIds.isEmpty ? "先选择至少一项。" : "还有选项需要重新判断。")
        }
    }

    private func refreshSelection() {
        for (id, button) in optionButtons {
            let selected = selectedIds.contains(id)
            button.backgroundColor = selected
                ? GeoTheme.Color.blue.withAlphaComponent(0.16)
                : GeoTheme.Color.paperControl
            button.layer.borderColor = selected
                ? GeoTheme.Color.blue.cgColor
                : GeoTheme.Color.separator.cgColor
        }
    }

    private func showRetry(_ text: String) {
        answerHintLabel.text = text
        answerHintLabel.textColor = GeoTheme.Color.warning
    }

    private func solve() {
        solved = true
        optionButtons.values.forEach { $0.isEnabled = false }
        checkButton.isHidden = true
        answerHintLabel.text = "✓ \(challenge.explanation)"
        answerHintLabel.textColor = GeoTheme.Color.teal
        if recordsProgress {
            LearningProgressCoordinator.shared.recordApplication(
                topicId: challenge.topicId,
                score: max(60, 100 - mistakes * 15))
        }
        onSolved?()
    }
}

/// 同一知识专题的连续应用题。答对当前题后，在原区域切换到下一题。
final class InlineTransferChallengeSequenceView: UIView {

    private let challenges: [TransferChallengeDefinition]
    private let canAnswer: Bool
    private let counterLabel = UILabel()
    private let pageControl = UIPageControl()
    private let questionContainer = UIView()
    private var currentIndex = 0

    init(challenges: [TransferChallengeDefinition], enabled: Bool) {
        self.challenges = challenges
        self.canAnswer = enabled
        super.init(frame: .zero)
        setupUI()
        showQuestion(at: 0, animated: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        counterLabel.font = GeoTheme.Typography.heading(size: 12)
        counterLabel.textColor = GeoTheme.Color.teal

        pageControl.numberOfPages = challenges.count
        pageControl.currentPageIndicatorTintColor = GeoTheme.Color.teal
        pageControl.pageIndicatorTintColor = GeoTheme.Color.teal.withAlphaComponent(0.20)
        pageControl.isUserInteractionEnabled = false

        addSubview(counterLabel)
        addSubview(pageControl)
        addSubview(questionContainer)
        counterLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.height.equalTo(22)
        }
        pageControl.snp.makeConstraints { make in
            make.centerY.equalTo(counterLabel)
            make.trailing.equalToSuperview()
            make.height.equalTo(22)
        }
        questionContainer.snp.makeConstraints { make in
            make.top.equalTo(counterLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func showQuestion(at index: Int, animated: Bool) {
        guard challenges.indices.contains(index) else { return }
        currentIndex = index
        counterLabel.text = "第 \(index + 1) / \(challenges.count) 题"
        pageControl.currentPage = index

        let question = InlineTransferChallengeView(
            challenge: challenges[index],
            enabled: canAnswer,
            recordsProgress: false)
        question.onSolved = { [weak self] in self?.questionSolved() }

        let replace = {
            self.questionContainer.subviews.forEach { $0.removeFromSuperview() }
            self.questionContainer.addSubview(question)
            question.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        if animated {
            UIView.transition(
                with: questionContainer,
                duration: 0.28,
                options: .transitionCrossDissolve,
                animations: replace)
        } else {
            replace()
        }
    }

    private func questionSolved() {
        let next = currentIndex + 1
        guard next < challenges.count else {
            counterLabel.text = "已完成 \(challenges.count) / \(challenges.count) 题"
            guard let topicId = challenges.first?.topicId else { return }
            LearningProgressCoordinator.shared.recordApplication(topicId: topicId, score: 100)
            return
        }
        counterLabel.text = "答对了，准备下一题…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.showQuestion(at: next, animated: true)
        }
    }
}
