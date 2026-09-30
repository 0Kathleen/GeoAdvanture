//
//  KnowledgeSummaryViewController.swift
//  GeoAdvanture
//
//  Step 7：知识总结主页面。左侧专题与关系图，右侧问题、因果、证据、误区和应用入口。
//

import UIKit
import SnapKit

final class KnowledgeSummaryViewController: UIViewController {

    private let viewModel: NotebookViewModel
    private lazy var summaryViewModel = KnowledgeSummaryViewModel(notebookViewModel: viewModel)
    weak var notebookNavigationDelegate: NotebookPageNavigationDelegate?

    private let leftPanel = UIView()
    private let rightScroll = UIScrollView()
    private let rightStack = UIStackView()
    private var placeholderView: NotebookPlaceholderView?
    private var selectedTopicId: String?
    private var pageData: KnowledgeSummaryPageData?

    init(viewModel: NotebookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
        refreshContent()
    }

    private func setupUI() {
        let divider = UIView()
        divider.backgroundColor = GeoTheme.Color.separator

        view.addSubview(leftPanel)
        view.addSubview(divider)
        view.addSubview(rightScroll)
        rightScroll.addSubview(rightStack)
        rightScroll.showsVerticalScrollIndicator = false
        rightScroll.contentInsetAdjustmentBehavior = .never
        rightStack.axis = .vertical
        rightStack.spacing = 12

        leftPanel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(14)
            make.width.equalToSuperview().multipliedBy(0.39)
        }
        divider.snp.makeConstraints { make in
            make.leading.equalTo(leftPanel.snp.trailing).offset(10)
            make.top.bottom.equalToSuperview().inset(18)
            make.width.equalTo(1)
        }
        rightScroll.snp.makeConstraints { make in
            make.leading.equalTo(divider.snp.trailing).offset(12)
            make.trailing.top.bottom.equalToSuperview().inset(14)
        }
        rightStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    private func render(preservingOffset: Bool) {
        let oldOffset = rightScroll.contentOffset
        let oldSelected = pageData?.selected.topic.id
        guard var data = summaryViewModel.makePageData(selectedTopicId: selectedTopicId) else {
            showPlaceholder()
            return
        }
        if data.selected.progress.stage >= .discovered,
           data.topics.first(where: { $0.id == data.selected.topic.id })?.hasUnreadContent == true {
            summaryViewModel.markRead(topicId: data.selected.topic.id)
            data = summaryViewModel.makePageData(selectedTopicId: data.selected.topic.id) ?? data
        }
        pageData = data
        selectedTopicId = data.selected.topic.id
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        leftPanel.isHidden = false
        rightScroll.isHidden = false

        rebuildLeft(data)
        rebuildRight(data.selected, overview: data.overview)
        view.layoutIfNeeded()
        if preservingOffset, oldSelected == data.selected.topic.id {
            let maxY = max(0, rightScroll.contentSize.height - rightScroll.bounds.height)
            rightScroll.setContentOffset(CGPoint(x: 0, y: min(oldOffset.y, maxY)), animated: false)
        } else {
            rightScroll.setContentOffset(.zero, animated: false)
        }
    }

    private func rebuildLeft(_ data: KnowledgeSummaryPageData) {
        leftPanel.subviews.forEach { $0.removeFromSuperview() }

        let eyebrow = UILabel()
        eyebrow.text = "知识地图"
        eyebrow.font = GeoTheme.Typography.heading(size: 18)
        eyebrow.textColor = GeoTheme.Color.ink

        let progress = UILabel()
        progress.text = "发现 \(data.discoveredCount)/\(data.topics.count) · 理解 \(data.understoodCount)/\(data.topics.count) · 应用 \(data.appliedCount)/\(data.topics.count)"
        progress.font = GeoTheme.Typography.caption(size: 11)
        progress.textColor = GeoTheme.Color.teal

        let topicGrid = UIStackView()
        topicGrid.axis = .vertical
        topicGrid.spacing = 7
        for start in stride(from: 0, to: data.topics.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 7
            row.distribution = .fillEqually
            for index in start..<min(start + 2, data.topics.count) {
                let item = data.topics[index]
                let itemView = KnowledgeTopicListItemView()
                itemView.configure(item, selected: item.id == data.selected.topic.id)
                itemView.addAction(UIAction { [weak self] _ in self?.selectTopic(item.id) }, for: .touchUpInside)
                row.addArrangedSubview(itemView)
            }
            if row.arrangedSubviews.count == 1 { row.addArrangedSubview(UIView()) }
            topicGrid.addArrangedSubview(row)
        }

        let relationTitle = UILabel()
        relationTitle.text = "知识关系"
        relationTitle.font = GeoTheme.Typography.heading(size: 13)
        relationTitle.textColor = GeoTheme.Color.inkMuted

        let graph = KnowledgeRelationGraphView()
        graph.render(topics: data.topics, edges: data.relationEdges)
        graph.onSelectTopic = { [weak self] id in self?.selectTopic(id) }
        graph.snp.makeConstraints { $0.height.equalTo(115) }

        let stack = UIStackView(arrangedSubviews: [eyebrow, progress, topicGrid, relationTitle, graph])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(2, after: eyebrow)
        stack.setCustomSpacing(13, after: progress)
        leftPanel.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func rebuildRight(_ detail: KnowledgeTopicDetailData, overview: LayerOverviewViewData) {
        for arranged in rightStack.arrangedSubviews {
            rightStack.removeArrangedSubview(arranged)
            arranged.removeFromSuperview()
        }

        rightStack.addArrangedSubview(LayerOverviewCardView(
            overview: overview,
            title: "\(overview.layerName)全景 · 把局部知识拼回整体"))

        if detail.progress.stage == .locked {
            renderLockedDetail(detail)
        } else {
            renderUnlockedDetail(detail)
        }
        if let mission = pageData?.integratedMission {
            appendIntegratedMission(mission)
        }
    }

    private func renderLockedDetail(_ detail: KnowledgeTopicDetailData) {
        let lock = UIImageView(image: UIImage(systemName: "lock.circle.fill"))
        lock.tintColor = GeoTheme.Color.locked
        lock.contentMode = .scaleAspectFit
        lock.snp.makeConstraints { $0.height.equalTo(72) }

        let title = label(detail.topic.title, size: 25, weight: .heavy, alignment: .center)
        let state = label("这个专题还缺少现场证据", size: 14, weight: .bold, alignment: .center)
        state.textColor = .secondaryLabel
        let hint = label(detail.unlockHint, size: 13, weight: .medium, alignment: .center)
        hint.textColor = GeoTheme.Color.inkMuted

        rightStack.addArrangedSubview(lock)
        rightStack.addArrangedSubview(title)
        rightStack.addArrangedSubview(state)
        rightStack.addArrangedSubview(hint)
        if let poiId = detail.nextPOIId {
            let button = actionButton(title: "前往闯关地图", color: GeoTheme.Color.teal)
            button.addAction(UIAction { [weak self] _ in
                self?.notebookNavigationDelegate?.notebookPageRequestsNavigation(.poi(poiId), animated: true)
            }, for: .touchUpInside)
            button.snp.makeConstraints { $0.height.equalTo(44) }
            rightStack.addArrangedSubview(button)
        }
    }

    private func renderUnlockedDetail(_ detail: KnowledgeTopicDetailData) {
        let heading = UIStackView()
        heading.axis = .horizontal
        heading.alignment = .center
        heading.spacing = 10
        let title = label(detail.topic.title, size: 25, weight: .heavy)
        let badge = stageBadge(detail.progress.stage)
        heading.addArrangedSubview(title)
        heading.addArrangedSubview(badge)
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        badge.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.addArrangedSubview(heading)

        let question = contentCard(text: detail.topic.coreQuestion, symbol: "questionmark.bubble.fill",
                                   tint: GeoTheme.Color.blue)
        rightStack.addArrangedSubview(question)

        let askAI = actionButton(
            title: "这里没看懂？问问岩小探",
            color: GeoTheme.Color.teal)
        askAI.setImage(UIImage(systemName: "sparkles"), for: .normal)
        askAI.tintColor = .white
        askAI.addAction(UIAction { [weak self] _ in self?.presentAI(for: detail) }, for: .touchUpInside)
        askAI.snp.makeConstraints { $0.height.equalTo(36) }
        rightStack.addArrangedSubview(askAI)

        rightStack.addArrangedSubview(sectionTitle("关卡证据"))
        let evidence = KnowledgeEvidenceStripView(items: detail.evidence)
        rightStack.addArrangedSubview(evidence)

        rightStack.addArrangedSubview(sectionTitle("形成过程"))
        let sorter = CausalOrderView(
            steps: detail.topic.causalSteps,
            alreadyUnderstood: detail.progress.stage >= .understood)
        sorter.onCompleted = { [weak self] in
            guard let self else { return }
            self.summaryViewModel.recordUnderstanding(topicId: detail.topic.id)
        }
        rightStack.addArrangedSubview(sorter)

        rightStack.addArrangedSubview(sectionTitle("关键结论"))
        rightStack.addArrangedSubview(KnowledgeConclusionView(
            steps: detail.topic.causalSteps,
            understood: detail.progress.stage >= .understood))
        rightStack.addArrangedSubview(KnowledgeMisconceptionDisclosureView(text: detail.topic.misconception))

        if !detail.transferChallenges.isEmpty {
            rightStack.addArrangedSubview(sectionTitle("换个场景试一试"))
            let canApply = detail.progress.stage >= .understood
            let application = InlineTransferChallengeSequenceView(
                challenges: detail.transferChallenges,
                enabled: canApply)
            application.snp.makeConstraints { $0.height.equalTo(300) }
            rightStack.addArrangedSubview(application)
        }
    }

    private func presentAI(for detail: KnowledgeTopicDetailData) {
        let chat = ChatViewController()
        chat.contextPrompt = """
        当前正在学习“\(detail.topic.title)”。
        核心问题：\(detail.topic.coreQuestion)
        请只围绕这个知识点回答，用生活比喻引导孩子理解，不要直接替孩子完成应用题。
        """
        chat.initialQuestion = detail.topic.coreQuestion
        chat.modalPresentationStyle = .fullScreen
        chat.modalTransitionStyle = .crossDissolve
        present(chat, animated: true)
    }

    private func appendIntegratedMission(_ data: IntegratedMissionViewData) {
        rightStack.addArrangedSubview(sectionTitle("综合任务"))

        let card = UIView()
        card.backgroundColor = UIColor(red: 0.20, green: 0.31, blue: 0.37, alpha: 0.92)
        card.layer.cornerRadius = 17

        let icon = UIImageView(image: UIImage(systemName: data.isCompleted ? "checkmark.seal.fill" : "map.fill"))
        icon.tintColor = data.isCompleted
            ? GeoTheme.Color.gold
            : UIColor(red: 0.71, green: 0.88, blue: 0.82, alpha: 1)
        icon.contentMode = .scaleAspectFit

        let title = label(data.mission.title, size: 16, weight: .heavy)
        title.textColor = .white
        let status = label(data.statusText, size: 11, weight: .semibold)
        status.textColor = UIColor.white.withAlphaComponent(0.78)
        let textStack = UIStackView(arrangedSubviews: [title, status])
        textStack.axis = .vertical
        textStack.spacing = 3

        let button = UIButton(type: .system)
        button.setTitle(data.isCompleted ? "重新挑战任务" : (data.canStart ? "开始调查" : "收集线索"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = GeoTheme.Typography.control(size: 12)
        button.backgroundColor = data.canStart || data.isCompleted
            ? GeoTheme.Color.clay
            : UIColor.white.withAlphaComponent(0.18)
        button.layer.cornerRadius = 13
        button.isEnabled = data.canStart || data.isCompleted
        button.addAction(UIAction { [weak self] _ in
            self?.presentIntegratedMission(data.mission)
        }, for: .touchUpInside)

        card.addSubview(icon)
        card.addSubview(textStack)
        card.addSubview(button)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(11)
            make.top.bottom.equalToSuperview().inset(12)
        }
        button.snp.makeConstraints { make in
            make.leading.equalTo(textStack.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(78)
            make.height.equalTo(32)
        }
        rightStack.addArrangedSubview(card)
    }

    private func presentIntegratedMission(_ mission: IntegratedMissionDefinition) {
        let controller = GeologyDetectiveViewController(mission: mission) { [weak self] in
            self?.dismiss(animated: true) {
                self?.refreshContent()
            }
        }
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    private func selectTopic(_ id: String) {
        guard selectedTopicId != id else { return }
        selectedTopicId = id
        render(preservingOffset: false)
    }

    private func showPlaceholder() {
        leftPanel.isHidden = true
        rightScroll.isHidden = true
        placeholderView?.removeFromSuperview()
        let placeholder = NotebookPlaceholderView(
            emoji: "📖",
            title: "\(viewModel.layerName)·知识预览",
            message: "本期的「学习—闯关—应用」完整闭环集中在地壳。\n这里作为圈层内容预览。")
        placeholderView = placeholder
        view.addSubview(placeholder)
        placeholder.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func label(_ text: String,
                       size: CGFloat,
                       weight: UIFont.Weight,
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

    private func sectionTitle(_ text: String) -> UILabel {
        let title = label(text, size: 13, weight: .heavy)
        title.textColor = GeoTheme.Color.inkMuted
        return title
    }

    private func stageBadge(_ stage: KnowledgeMasteryStage) -> UILabel {
        let badge = UILabel()
        badge.textAlignment = .center
        badge.font = GeoTheme.Typography.caption(size: 11)
        badge.textColor = .white
        badge.layer.cornerRadius = 11
        badge.clipsToBounds = true
        switch stage {
        case .locked:
            badge.text = "待发现"
            badge.backgroundColor = GeoTheme.Color.locked
        case .discovered:
            badge.text = "已发现"
            badge.backgroundColor = GeoTheme.Color.success
        case .understood:
            badge.text = "已理解"
            badge.backgroundColor = GeoTheme.Color.blue
        case .applied:
            badge.text = "会应用"
            badge.backgroundColor = GeoTheme.Color.warning
        }
        badge.snp.makeConstraints { make in
            make.width.equalTo(62)
            make.height.equalTo(23)
        }
        return badge
    }

    private func contentCard(text: String, symbol: String, tint: UIColor) -> UIView {
        let card = UIView()
        GeoTheme.applyPaperCard(to: card)
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        let body = label(text, size: 12, weight: .medium)
        card.addSubview(icon)
        card.addSubview(body)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(body)
            make.width.height.equalTo(22)
        }
        body.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(10)
        }
        return card
    }

    private func actionButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = GeoTheme.Typography.control(size: 14)
        button.backgroundColor = color
        button.layer.cornerRadius = GeoTheme.Radius.control
        return button
    }

    private func applicationStatus(for stage: KnowledgeMasteryStage) -> String {
        if stage >= .applied { return "你已经会应用这个知识，可以再次挑战。" }
        return stage >= .understood
            ? "把知识用到一个没有在原关卡中出现的新情境。"
            : "先整理上方的因果顺序，应用任务才会开放。"
    }
}

extension KnowledgeSummaryViewController: NotebookPageContent {
    func refreshContent() {
        guard isViewLoaded else { return }
        render(preservingOffset: true)
    }

    @discardableResult
    func focus(on target: NotebookFocusTarget, animated: Bool) -> Bool {
        guard case let .knowledgeTopic(id) = target,
              ContentStore.shared.knowledgeTopics(layerId: viewModel.layerId).contains(where: { $0.id == id }) else {
            return false
        }
        selectedTopicId = id
        render(preservingOffset: false)
        return true
    }
}
