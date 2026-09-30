//
//  NotebookPlaceholderView.swift
//  GeoAdvanture
//
//  笔记本内「知识预览 / 空态」占位视图。
//  一期地幔/地核的「闯关地图」「知识总结」内容后补（占位可进），用它给出友好的提示，
//  避免页面看起来是坏的或空白的。真内容到位后（R-3/R-5）直接替换承载视图即可。
//

import UIKit
import SnapKit

final class NotebookPlaceholderView: UIView {

    init(emoji: String, title: String, message: String) {
        super.init(frame: .zero)
        backgroundColor = .clear

        let icon = UILabel()
        icon.text = emoji
        icon.font = .systemFont(ofSize: 52)
        icon.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = NotebookTypography.ListCell.titleFont
        titleLabel.textColor = NotebookTypography.ListCell.titleColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = NotebookTypography.ListCell.bodyFont
        messageLabel.textColor = NotebookTypography.ListCell.bodyColor
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = GeoTheme.Spacing.medium
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
