//
//  HarvestCardView.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import UIKit
import SnapKit

class HarvestCardView: UIView {
    
    private let data: HarvestCardData
    
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let containerView = UIView()
    
    init(data: HarvestCardData) {
        self.data = data
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        containerView.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.93, alpha: 1.0)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.8, green: 0.75, blue: 0.65, alpha: 0.5).cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.shadowOffset = CGSize(width: 2, height: 2)
        containerView.layer.shadowRadius = 4
        addSubview(containerView)
        
        titleLabel.text = "【\(data.title)】"
        titleLabel.font = NotebookTypography.ListCell.titleFont.withSize(16)
        titleLabel.textColor = NotebookTypography.ListCell.titleColor
        titleLabel.textAlignment = .center
        
        contentLabel.attributedText = NotebookTypography.ListCell.attributedBody(data.content)
        contentLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, contentLabel, UIView()])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        
        containerView.addSubview(stack)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(260)
            make.height.equalTo(180)
        }
        
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }
}
