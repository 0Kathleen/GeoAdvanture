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
    private var sections: [HarvestSectionData] = []
    
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
        loadData()
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
    
    private func loadData() {
        sections = viewModel.fetchHarvestData()
        
        for (index, section) in sections.enumerated() {
            let isLast = index == sections.count - 1
            let sectionView = HarvestSectionView(data: section, isLast: isLast)
            contentStackView.addArrangedSubview(sectionView)
        }
    }
}
