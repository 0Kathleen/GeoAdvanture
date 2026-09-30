//
//  NotebookIntroViewController.swift
//  GeoAdvanture
//
//  “认识”页：先建立圈层整体身份，再进入可追踪的局部探索问题。
//

import UIKit
import SnapKit

final class NotebookIntroViewController: UIViewController {

    private let viewModel: NotebookViewModel
    weak var notebookNavigationDelegate: NotebookPageNavigationDelegate?

    private var learningData: NotebookLearningIntroViewData?
    private var expandedInquiryIds: Set<String> = []
    private var focusedInquiryId: String?
    private var overviewCard: UIView?

    private let leftPage = UIView()
    private let rightPage = UIView()

    private let overviewContainer = UIView()

    private let inquirySectionLabel: UILabel = {
        let label = UILabel()
        label.text = "下面，从这三个问题来探索一下吧"
        label.font = GeoTheme.Typography.heading(size: 13)
        label.textColor = GeoTheme.Color.mauve
        return label
    }()

    private let overallProgressLabel: UILabel = {
        let label = UILabel()
        label.font = GeoTheme.Typography.caption(size: 12)
        label.textColor = GeoTheme.Color.ink
        label.textAlignment = .right
        return label
    }()

    private let overallProgressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = GeoTheme.Color.paperMuted.withAlphaComponent(0.45)
        progress.progressTintColor = GeoTheme.Color.success
        return progress
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(InquiryTopicCell.self, forCellReuseIdentifier: InquiryTopicCell.reuseId)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 112
        table.showsVerticalScrollIndicator = true
        table.contentInsetAdjustmentBehavior = .never
        return table
    }()

    private var placeholderView: NotebookPlaceholderView?

    init(viewModel: NotebookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        refreshContent()
    }

    private func setupLayout() {
        view.addSubview(leftPage)
        view.addSubview(rightPage)
        leftPage.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(NotebookLayout.leftContentWidth)
        }
        rightPage.snp.makeConstraints { make in
            make.leading.equalTo(leftPage.snp.trailing).offset(NotebookLayout.contentHorizontalInset)
            make.top.trailing.bottom.equalToSuperview()
        }

        rightPage.addSubview(overviewContainer)
        overviewContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(2)
        }

        rightPage.addSubview(inquirySectionLabel)
        inquirySectionLabel.snp.makeConstraints { make in
            make.top.equalTo(overviewContainer.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(2)
        }

        rightPage.addSubview(overallProgressLabel)
        rightPage.addSubview(overallProgressView)
        rightPage.addSubview(tableView)
        overallProgressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(inquirySectionLabel)
            make.trailing.equalToSuperview().inset(6)
            make.leading.greaterThanOrEqualTo(inquirySectionLabel.snp.trailing).offset(8)
        }
        overallProgressView.snp.makeConstraints { make in
            make.top.equalTo(inquirySectionLabel.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(overallProgressView.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func render() {
        guard let data = learningData else { return }
        overviewCard?.removeFromSuperview()
        let newOverview = LayerOverviewCardView(
            overview: data.overview,
            title: nil)
        overviewContainer.addSubview(newOverview)
        newOverview.snp.makeConstraints { $0.edges.equalToSuperview() }
        overviewCard = newOverview
        let hasInquiries = !data.inquiries.isEmpty
        overallProgressLabel.text = hasInquiries
            ? "探索进度  \(data.discoveredCount)/\(data.totalCount)"
            : "圈层知识预览"
        overallProgressView.isHidden = !hasInquiries
        overallProgressView.progress = data.totalCount == 0
            ? 0
            : Float(data.discoveredCount) / Float(data.totalCount)

        rebuildLeftPage(data)

        if data.inquiries.isEmpty {
            showPlaceholder()
        } else {
            placeholderView?.removeFromSuperview()
            placeholderView = nil
            tableView.isHidden = false
            if expandedInquiryIds.isEmpty, let first = data.inquiries.first {
                expandedInquiryIds.insert(first.topic.id)
            }
            tableView.reloadData()
            restoreFocusedInquiry(animated: false)
        }
    }

    private func rebuildLeftPage(_ data: NotebookLearningIntroViewData) {
        leftPage.subviews.forEach { $0.removeFromSuperview() }

        let imageView = UIImageView(image: UIImage(named: introImageAsset(for: data.layerId)))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = GeoTheme.Radius.card
        imageView.backgroundColor = .clear
        imageView.snp.makeConstraints { $0.height.equalTo(132) }

        if imageView.image == nil {
            let placeholder = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
            placeholder.tintColor = GeoTheme.Color.inkMuted
            placeholder.contentMode = .scaleAspectFit
            imageView.addSubview(placeholder)
            placeholder.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(58)
            }
        }

        let stack = UIStackView(arrangedSubviews: [imageView])
        stack.axis = .vertical
        stack.spacing = 8
        if let profile = data.profile {
            stack.addArrangedSubview(LayerProfileCardView(profile: profile, overview: data.overview))
        }
        leftPage.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }

    private func introImageAsset(for layerId: String) -> String {
        switch layerId {
        case "mantle": return "intro_mantle_overview"
        case "core", "outer_core", "inner_core": return "intro_core_overview"
        default: return "intro_crust_overview"
        }
    }

    private func showPlaceholder() {
        tableView.isHidden = true
        placeholderView?.removeFromSuperview()
        let placeholder = NotebookPlaceholderView(
            emoji: "🔎",
            title: "先认识\(viewModel.layerName)",
            message: "观察左侧圈层图，记住它在地球内部的位置。\n本期完整探索从地壳开始。")
        rightPage.addSubview(placeholder)
        placeholder.snp.makeConstraints { make in
            make.top.equalTo(overallProgressView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        placeholderView = placeholder
    }

    private func restoreFocusedInquiry(animated: Bool) {
        guard let id = focusedInquiryId,
              let index = learningData?.inquiries.firstIndex(where: { $0.topic.id == id }) else { return }
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: animated)
    }

    private func openMap(for row: NotebookInquiryViewData) {
        guard let poiId = row.nextPOIId else { return }
        notebookNavigationDelegate?.notebookPageRequestsNavigation(.poi(poiId), animated: true)
    }
}

// MARK: - NotebookPageContent
extension NotebookIntroViewController: NotebookPageContent {
    func refreshContent() {
        guard isViewLoaded else { return }
        learningData = viewModel.fetchLearningIntroData()
        render()
    }

    @discardableResult
    func focus(on target: NotebookFocusTarget, animated: Bool) -> Bool {
        guard let data = learningData else { return false }
        let inquiry: NotebookInquiryViewData?
        switch target {
        case let .inquiry(id):
            inquiry = data.inquiries.first { $0.topic.id == id }
        case let .knowledgeTopic(id):
            inquiry = data.inquiries.first { $0.topic.knowledgeTopicIds.contains(id) }
        case let .poi(id):
            inquiry = data.inquiries.first { $0.topic.linkedPOIIds.contains(id) }
        }
        guard let inquiry else { return false }
        focusedInquiryId = inquiry.topic.id
        expandedInquiryIds.insert(inquiry.topic.id)
        tableView.reloadData()
        restoreFocusedInquiry(animated: animated)
        return true
    }
}

// MARK: - UITableView
extension NotebookIntroViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        learningData?.inquiries.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: InquiryTopicCell.reuseId,
            for: indexPath) as! InquiryTopicCell
        guard let row = learningData?.inquiries[indexPath.row] else { return cell }
        let id = row.topic.id
        cell.configure(
            data: row,
            number: indexPath.row + 1,
            expanded: expandedInquiryIds.contains(id),
            focused: focusedInquiryId == id)
        cell.onExplore = { [weak self] in self?.openMap(for: row) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = learningData?.inquiries[indexPath.row] else { return }
        let id = row.topic.id
        if expandedInquiryIds.contains(id) {
            expandedInquiryIds.remove(id)
        } else {
            expandedInquiryIds.insert(id)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
