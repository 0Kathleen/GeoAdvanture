//
//  HarvestSectionView.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import UIKit
import SnapKit

class HarvestSectionView: UIView {
    
    private let data: HarvestSectionData
    private let isLast: Bool
    
    // MARK: - UI Components
    private let timelineDot = UIView()
    private let timelineLine = UIView()
    private let titleLabel = UILabel()
    private let contentContainer = UIView()
    
    init(data: HarvestSectionData, isLast: Bool) {
        self.data = data
        self.isLast = isLast
        super.init(frame: .zero)
        setupUI()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Timeline Dot
        timelineDot.backgroundColor = data.isUnlocked ? UIColor.systemRed : UIColor.systemOrange
        timelineDot.layer.cornerRadius = 5
        timelineDot.clipsToBounds = true
        addSubview(timelineDot)
        
        // Timeline Line
        timelineLine.backgroundColor = UIColor(red: 0.53, green: 0.39, blue: 0.36, alpha: 0.5) // Notebook brown color
        addSubview(timelineLine)
        
        // Title Label
        titleLabel.numberOfLines = 0
        titleLabel.font = NotebookTypography.ListCell.titleFont.withSize(20)
        titleLabel.textColor = NotebookTypography.ListCell.titleColor
        titleLabel.textAlignment = .center
        
        // Remove "收获" suffix for a cleaner vertical title
        let cleanTitle = data.title.replacingOccurrences(of: "收获", with: "")
        let titleString = cleanTitle.map { String($0) }.joined(separator: "\n")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .center
        let attrString = NSAttributedString(string: titleString, attributes: [
            .paragraphStyle: paragraphStyle
        ])
        titleLabel.attributedText = attrString
        addSubview(titleLabel)
        
        // Content Container
        addSubview(contentContainer)
        
        // Constraints
        timelineDot.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.width.height.equalTo(10)
        }
        
        timelineLine.snp.makeConstraints { make in
            make.top.equalTo(timelineDot.snp.bottom).offset(4)
            make.centerX.equalTo(timelineDot)
            make.width.equalTo(2)
            if isLast {
                make.bottom.equalToSuperview().offset(-8)
            } else {
                make.bottom.equalToSuperview().offset(16) // overlap with next cell slightly
            }
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalTo(timelineDot.snp.trailing).offset(12)
            make.width.equalTo(24)
        }
        
        contentContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-32) // spacing between sections
            make.height.greaterThanOrEqualTo(titleLabel.snp.height)
        }
    }
    
    private func configureContent() {
        if data.isUnlocked {
            let scrollView = UIScrollView()
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.clipsToBounds = true
            contentContainer.addSubview(scrollView)
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 16
            scrollView.addSubview(stackView)
            
            scrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            stackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalToSuperview()
            }
            
            for cardData in data.cards {
                let cardView = HarvestCardView(data: cardData)
                stackView.addArrangedSubview(cardView)
            }
            
            // Set a fixed height for the scroll view container
            contentContainer.snp.makeConstraints { make in
                make.height.equalTo(180)
            }
        } else {
            let lockedStack = UIStackView()
            lockedStack.axis = .vertical
            lockedStack.spacing = 8
            
            let lockedLabel = UILabel()
            lockedLabel.text = "待解锁"
            lockedLabel.font = NotebookTypography.ListCell.titleFont.withSize(18)
            lockedLabel.textColor = .gray
            
            let hintLabel = UILabel()
            hintLabel.text = "快去地图页面挑战关卡解锁知识吧"
            hintLabel.font = NotebookTypography.ListCell.bodyFont.withSize(14)
            hintLabel.textColor = .lightGray
            
            lockedStack.addArrangedSubview(lockedLabel)
            lockedStack.addArrangedSubview(hintLabel)
            lockedStack.addArrangedSubview(UIView()) // spacer
            
            contentContainer.addSubview(lockedStack)
            lockedStack.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
            }
        }
    }
}
