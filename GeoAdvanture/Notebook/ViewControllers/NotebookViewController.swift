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
    private var selectedBookmarkIndex: Int = 0
    private var currentContentViewController: UIViewController?
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

    /// 书签条：相对笔记本内容区顶部靠右，纵向排列
    private lazy var bookmarkButtons: [UIButton] = {
        (0..<4).map { idx in
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
        (0..<4).map { idx in
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
        l.textColor = UIColor(red: 0x52/255, green: 0x38/255, blue: 0x36/255, alpha: 1)
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
        configureForLayerEntry()
        lastAppliedEarthLayerIndex = initialEarthLayerIndex
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastAppliedEarthLayerIndex != initialEarthLayerIndex {
            lastAppliedEarthLayerIndex = initialEarthLayerIndex
            configureForLayerEntry()
        }
    }

    deinit {
        removeCurrentContentViewController()
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
            make.leading.equalToSuperview().offset(NotebookLayout.bookmarkBarLeading)
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
        selectedBookmarkIndex = sender.tag
        updateBookmarkVisibility()
        updateContentArea()
    }

    @objc func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - configure
    private func configureForLayerEntry() {
        selectedBookmarkIndex = 0
        viewModel = NotebookViewModel(layerIndex: initialEarthLayerIndex)
        updateBookmarkVisibility()
        updateContentArea()
    }

    private func updateBookmarkVisibility() {
        let k = selectedBookmarkIndex
        for i in 0..<4 {
            selectedBookmarkButtons[i].isHidden = !(i <= k)
            bookmarkButtons[i].isHidden = !(i > k)
        }
    }
    
    private func updateContentArea() {
        let oldVC = currentContentViewController
        
        let newVC: UIViewController
        let bookmarkTitle = NotebookContent.bookmarkTitles[selectedBookmarkIndex]
        let layerTitle = viewModel.layerName
        
        topTitleLabel.text = "【\(bookmarkTitle)】\(layerTitle)"
        
        switch selectedBookmarkIndex {
        case 0:
            newVC = NotebookIntroViewController(viewModel: viewModel)
        case 1:
            newVC = NotebookMapViewController(viewModel: viewModel)
        default:
            newVC = NotebookSubPageViewController(bookmarkIndex: selectedBookmarkIndex, viewModel: viewModel)
        }
        
        addChild(newVC)
        
        if let oldVC = oldVC {
            oldVC.willMove(toParent: nil)
            
            // 使用交叉溶解（Cross Dissolve）作为书签切换的平滑过渡动画
            UIView.transition(with: contentContainerView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                oldVC.view.removeFromSuperview()
                self.contentContainerView.addSubview(newVC.view)
                newVC.view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }, completion: { _ in
                oldVC.removeFromParent()
                newVC.didMove(toParent: self)
            })
        } else {
            contentContainerView.addSubview(newVC.view)
            newVC.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            newVC.didMove(toParent: self)
        }
        
        currentContentViewController = newVC
    }

    private func removeCurrentContentViewController() {
        guard let child = currentContentViewController else { return }
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
        currentContentViewController = nil
    }
}
