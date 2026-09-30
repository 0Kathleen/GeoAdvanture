//
//  KnowledgeViewController.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/12/4.
//
import UIKit
import SnapKit

class NotebookViewController: UIViewController {

    var initialEarthLayerIndex: Int = 1

    // MARK: - State
    private var selectedPage: NotebookPage = .intro
    private var currentContentViewController: UIViewController?
    /// 每个页签只创建一次，切换时保留展开、滚动和定位状态。
    private var pageViewControllers: [NotebookPage: UIViewController] = [:]
    private var isRefreshScheduled = false
    private var lastAppliedEarthLayerIndex: Int?
    private var viewModel: NotebookViewModel!

    // MARK: - UI
    private let backgroundImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: NotebookResourceNames.background))
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()

    private let notebookImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: NotebookResourceNames.notebook))
        v.contentMode = .scaleAspectFill
        v.isUserInteractionEnabled = true
        return v
    }()

    private let notebookContentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = true
        return v
    }()

    private let contentContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private static let bookmarkCount = NotebookPage.allCases.count

    /// 书签条：相对笔记本内容区顶部靠右，纵向排列
    private lazy var bookmarkButtons: [UIButton] = {
        (0..<Self.bookmarkCount).map { idx in
            let b = UIButton(type: .custom)
            b.tag = idx
            b.setImage(UIImage(named: NotebookResourceNames.bookmarkNormal[idx]), for: .normal)
            b.addTarget(self, action: #selector(bookmarkTapped(_:)), for: .touchUpInside)
            return b
        }
    }()
    private lazy var bookmarkStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.distribution = .fill
        s.spacing = NotebookLayout.bookmarkVerSpacing
        s.isLayoutMarginsRelativeArrangement = false
        return s
    }()

    /// 左侧：已翻过的书签，纵向叠放
    private lazy var selectedBookmarkButtons: [UIButton] = {
        (0..<Self.bookmarkCount).map { idx in
            let b = UIButton(type: .custom)
            b.tag = idx
            b.setImage(UIImage(named: NotebookResourceNames.bookmarkSelected[idx]), for: .normal)
            b.addTarget(self, action: #selector(bookmarkTapped(_:)), for: .touchUpInside)
            return b
        }
    }()
    private lazy var selectedBookmarkStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.distribution = .fill
        s.spacing = NotebookLayout.bookmarkVerSpacing
        return s
    }()

    /// 顶部标题
    private let topCenterTitle: UIImageView = {
        let v = UIImageView(image: UIImage(named: NotebookResourceNames.titleBubble))
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let topTitleLabel: UILabel = {
        let l = UILabel()
        l.font = NotebookTypography.topTitleFont(size: 24)
        l.textColor = GeoTheme.Color.ink
        l.textAlignment = .center
        return l
    }()

    // MARK: - lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
        title = nil

        setupUI()
        observeProgressChanges()
        configureForLayerEntry()
        lastAppliedEarthLayerIndex = initialEarthLayerIndex
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastAppliedEarthLayerIndex != initialEarthLayerIndex {
            lastAppliedEarthLayerIndex = initialEarthLayerIndex
            configureForLayerEntry()
        } else {
            refreshCurrentPage()
        }
        
        let context = LevelContext(
            levelId: "notebook_\(initialEarthLayerIndex)",
            levelName: viewModel.layerName,
            targetGoal: "浏览地球内部结构知识笔记"
        )
        LearningEventBus.shared.updateContext(context)
        LearningEventBus.shared.post(action: LearningAction(type: .enterPage))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        LearningEventBus.shared.post(action: LearningAction(type: .leavePage))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        removeAllPageViewControllers()
    }

    // MARK: - setupUI
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(notebookImageView)
        view.addSubview(topCenterTitle)
        topCenterTitle.addSubview(topTitleLabel)
        
        notebookImageView.addSubview(notebookContentView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NotebookLayout.backgroundInsets)
        }
        notebookImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(NotebookLayout.notebookInsets.top)
            make.leading.equalToSuperview().offset(NotebookLayout.notebookInsets.left)
            make.trailing.equalToSuperview().inset(NotebookLayout.notebookInsets.right)
            make.bottom.equalToSuperview().inset(NotebookLayout.notebookInsets.bottom)
        }
        notebookContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        topCenterTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(NotebookLayout.topCenterTitleTop)
            make.centerX.equalToSuperview()
        }
        topTitleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        /// 未翻书签
        notebookContentView.addSubview(bookmarkStackView)
        fillBookmarkStackWithStaggeredRows(bookmarkStackView, buttons: bookmarkButtons)
        bookmarkStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(NotebookLayout.bookmarkBarTop)
            make.trailing.equalToSuperview().inset(6)
            make.height.equalTo(NotebookLayout.bookmarkBarSize.height)
            make.width.equalTo(NotebookLayout.bookmarkBarSize.width)
        }

        /// 已翻书签
        notebookContentView.addSubview(selectedBookmarkStackView)
        fillBookmarkStackWithStaggeredRows(selectedBookmarkStackView, buttons: selectedBookmarkButtons)
        selectedBookmarkStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(NotebookLayout.bookmarkBarTop)
            make.width.equalTo(NotebookLayout.bookmarkBarSize.width)
            make.height.equalTo(NotebookLayout.bookmarkBarSize.height)
        }

        /// 主内容区：由 contentContainerView 承载不同的独立页面
        notebookContentView.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { make in
            make.leading.equalTo(selectedBookmarkStackView.snp.trailing).offset(NotebookLayout.mainContentLeading)
            make.top.equalToSuperview().offset(NotebookLayout.mainContentTop)
            make.bottom.equalToSuperview().inset(NotebookLayout.mainContentBottom)
            make.trailing.equalTo(bookmarkStackView.snp.leading).offset(-NotebookLayout.mainContentTrail)
        }
    }

    private func fillBookmarkStackWithStaggeredRows(_ stack: UIStackView, buttons: [UIButton]) {
        guard stack.arrangedSubviews.isEmpty else { return }
        for idx in 0..<buttons.count {
            let row = UIView()
            row.backgroundColor = .clear
            let b = buttons[idx]
            row.addSubview(b)
            let stagger = CGFloat(idx) * NotebookLayout.bookmarkHoriSpacing
            b.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(stagger)
                make.top.bottom.equalToSuperview()
                make.width.equalTo(NotebookLayout.bookmarkSize.width)
                make.height.equalTo(NotebookLayout.bookmarkSize.height)
            }
            row.snp.makeConstraints { make in
                make.width.equalTo(NotebookLayout.bookmarkBarSize.width)
                make.height.equalTo(NotebookLayout.bookmarkSize.height)
            }
            stack.addArrangedSubview(row)
        }
    }
    
    // MARK: - Action
    @objc private func bookmarkTapped(_ sender: UIButton) {
        guard let page = NotebookPage(rawValue: sender.tag) else { return }
        navigate(to: .init(page: page, focus: nil), animated: true)
    }

    @objc func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - configure
    private func configureForLayerEntry() {
        removeAllPageViewControllers()
        selectedPage = .intro
        viewModel = NotebookViewModel(layerIndex: initialEarthLayerIndex)
        updateBookmarkVisibility()
        showSelectedPage(animated: false, focus: nil)
        // R-3：知识卡不再靠「打开笔记本」自动解锁，改为在「闯关地图」完成对应关键点后点亮。
    }

    private func updateBookmarkVisibility() {
        let k = selectedPage.rawValue
        for i in 0..<Self.bookmarkCount {
            selectedBookmarkButtons[i].isHidden = !(i <= k)
            bookmarkButtons[i].isHidden = !(i > k)
        }
    }
    
    private func showSelectedPage(animated: Bool, focus: NotebookFocusTarget?) {
        let oldVC = currentContentViewController
        let newVC = pageViewController(for: selectedPage)

        topTitleLabel.text = selectedPage == .explore
            ? "生活百科"
            : "\(viewModel.layerName) · \(selectedPage.title)"
        // “认识”页右侧已有完整的大问题标题，继续显示中央气泡会遮挡内容并造成重复。
        topCenterTitle.isHidden = selectedPage == .intro
        (newVC as? NotebookPageContent)?.refreshContent()

        guard oldVC !== newVC else {
            if let focus { (newVC as? NotebookPageContent)?.focus(on: focus, animated: animated) }
            return
        }

        let installNewView = {
            oldVC?.view.removeFromSuperview()
            self.contentContainerView.addSubview(newVC.view)
            newVC.view.snp.makeConstraints { make in make.edges.equalToSuperview() }
        }

        if animated, oldVC != nil {
            UIView.transition(
                with: contentContainerView,
                duration: 0.25,
                options: [.transitionCrossDissolve, .allowAnimatedContent],
                animations: installNewView,
                completion: { _ in
                    if let focus {
                        (newVC as? NotebookPageContent)?.focus(on: focus, animated: true)
                    }
                })
        } else {
            installNewView()
            if let focus { (newVC as? NotebookPageContent)?.focus(on: focus, animated: false) }
        }

        currentContentViewController = newVC
    }

    private func pageViewController(for page: NotebookPage) -> UIViewController {
        if let cached = pageViewControllers[page] { return cached }

        let controller: UIViewController
        switch page {
        case .intro:
            let intro = NotebookIntroViewController(viewModel: viewModel)
            intro.notebookNavigationDelegate = self
            controller = intro
        case .map:
            let map = NotebookMapViewController(viewModel: viewModel)
            map.notebookNavigationDelegate = self
            controller = map
        case .summary:
            let summary = KnowledgeSummaryViewController(viewModel: viewModel)
            summary.notebookNavigationDelegate = self
            controller = summary
        case .explore:
            controller = NotebookLifeEncyclopediaViewController(viewModel: viewModel)
        }

        addChild(controller)
        controller.didMove(toParent: self)
        pageViewControllers[page] = controller
        return controller
    }

    private func removeAllPageViewControllers() {
        for child in pageViewControllers.values {
            child.willMove(toParent: nil)
            child.viewIfLoaded?.removeFromSuperview()
            child.removeFromParent()
        }
        pageViewControllers.removeAll()
        currentContentViewController = nil
    }

    private func observeProgressChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(progressDidChange),
            name: .didChangeKnowledgeProgress,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(progressDidChange),
            name: .didUnlockContent,
            object: nil)
    }

    @objc private func progressDidChange() {
        guard !isRefreshScheduled else { return }
        isRefreshScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isRefreshScheduled = false
            self.refreshCurrentPage()
        }
    }

    private func refreshCurrentPage() {
        (currentContentViewController as? NotebookPageContent)?.refreshContent()
    }

    /// 后续三个页面及关卡结果页统一使用此入口跨页定位。
    func navigate(to request: NotebookNavigationRequest, animated: Bool = true) {
        selectedPage = request.page
        updateBookmarkVisibility()
        showSelectedPage(animated: animated, focus: request.focus)
    }
}

extension NotebookViewController: NotebookPageNavigationDelegate {
    func notebookPageRequestsNavigation(_ request: NotebookNavigationRequest, animated: Bool) {
        navigate(to: request, animated: animated)
    }
}
