//
//  NotebookHarvestViewController.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import UIKit
import SnapKit

class NotebookHarvestViewController: UIViewController {
    
    private let viewModel: NotebookViewModel
    weak var notebookNavigationDelegate: NotebookPageNavigationDelegate?
    private var sections: [HarvestSectionData] = []
    private var sectionViews: [String: HarvestSectionView] = [:]
    private var focusedTopicId: String?
    private var placeholderView: NotebookPlaceholderView?
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()
    
    init(viewModel: NotebookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
        refreshContent()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16))
            make.width.equalToSuperview().offset(-32)
        }
    }
    
    private func loadData(preservingOffset: Bool) {
        let oldOffset = scrollView.contentOffset
        sections = viewModel.fetchHarvestData()
        clearRenderedContent()

        guard !sections.isEmpty else {
            showPlaceholder()
            return
        }

        placeholderView?.removeFromSuperview()
        placeholderView = nil
        scrollView.isHidden = false

        for (index, section) in sections.enumerated() {
            let isLast = index == sections.count - 1
            let sectionView = HarvestSectionView(data: section, isLast: isLast)
            sectionViews[section.id] = sectionView
            contentStackView.addArrangedSubview(sectionView)
        }

        view.layoutIfNeeded()
        if let focusedTopicId {
            scrollToTopic(id: focusedTopicId, animated: false)
        } else if preservingOffset {
            let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
            scrollView.setContentOffset(
                CGPoint(x: oldOffset.x, y: min(oldOffset.y, maxY)),
                animated: false)
        }
    }

    private func clearRenderedContent() {
        sectionViews.removeAll()
        for arranged in contentStackView.arrangedSubviews {
            contentStackView.removeArrangedSubview(arranged)
            arranged.removeFromSuperview()
        }
    }

    /// 本层还没有知识点（地幔/地核一期为空）时的友好占位。
    private func showPlaceholder() {
        scrollView.isHidden = true
        placeholderView?.removeFromSuperview()
        let placeholder = NotebookPlaceholderView(
            emoji: "📖",
            title: "「\(viewModel.layerName)」知识总结待解锁",
            message: "在「闯关地图」里完成探索，\n这一层的知识卡就会一张张收进来啦！")
        placeholderView = placeholder
        view.addSubview(placeholder)
        placeholder.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func scrollToTopic(id: String, animated: Bool) {
        guard let sectionView = sectionViews[id] else { return }
        view.layoutIfNeeded()
        let rect = sectionView.convert(sectionView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -12), animated: animated)
    }
}

// MARK: - NotebookPageContent
extension NotebookHarvestViewController: NotebookPageContent {
    func refreshContent() {
        guard isViewLoaded else { return }
        loadData(preservingOffset: true)
    }

    @discardableResult
    func focus(on target: NotebookFocusTarget, animated: Bool) -> Bool {
        guard case let .knowledgeTopic(id) = target,
              sections.contains(where: { $0.id == id }) else { return false }
        focusedTopicId = id
        scrollToTopic(id: id, animated: animated)
        return true
    }
}
