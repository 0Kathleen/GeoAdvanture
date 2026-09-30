//
//  ChatTableViewCell.swift
//  GeoAdvanture
//
//

import UIKit

final class ChatCell: UITableViewCell {

    private var userConstraints: [NSLayoutConstraint] = []
    private var aiConstraints: [NSLayoutConstraint] = []

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 为阴影提供路径，减少离屏/过度绘制
        let r: CGFloat
        if bubbleView.layer.cornerRadius > 0 {
            r = bubbleView.layer.cornerRadius
        } else {
            r = 0
        }
        let path = UIBezierPath(roundedRect: bubbleView.bounds, cornerRadius: r)
        shadowContainer.layer.shadowPath = path.cgPath
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        // 阴影与圆角内容分离：shadow 在外层
        contentView.addSubview(shadowContainer)
        shadowContainer.addSubview(bubbleView)
        bubbleView.addSubview(diaTextLabel)
        bubbleView.addSubview(spinner)
    }

    private func setupConstraints() {
        [shadowContainer, bubbleView, diaTextLabel, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            bubbleView.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            bubbleView.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor),

            diaTextLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            diaTextLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            diaTextLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            diaTextLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

            // 让 spinner 居中显示
            spinner.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            
            // 确保如果只有 spinner 的时候，bubbleView 也能被撑开
            bubbleView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            shadowContainer.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            shadowContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            shadowContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        userConstraints = [
            shadowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AIChatLayout.userRowHorizontalPadding)
        ]

        aiConstraints = [
            shadowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AIChatLayout.aiRowHorizontalPadding)
        ]
    }

    // MARK: - Config
    func configure(with word: Word) {
        if word.role == "user" {
            NSLayoutConstraint.deactivate(aiConstraints)
            NSLayoutConstraint.activate(userConstraints)
            applyUserBubbleStyle()
        } else {
            NSLayoutConstraint.deactivate(userConstraints)
            NSLayoutConstraint.activate(aiConstraints)
            applyBotBubbleStyle()
        }
        updateContent(word: word)
    }

    func updateContent(word: Word) {
        if word.isPlaceholder {
            diaTextLabel.text = ""
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            spinner.isHidden = true
            
            // 解决流式更新时跳动/卡顿的重要优化：如果文本没变，直接 return 避免重绘
            if diaTextLabel.text == word.text {
                return
            }
            
            diaTextLabel.attributedText = NSAttributedString(
                string: word.text,
                attributes: makeTextAttributes()
            )
            
            // 强制重新布局
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    private func applyBotBubbleStyle() {
        AIChatShadow.apply(to: shadowContainer.layer)
        bubbleView.backgroundColor = AIChatBubbleStyle.botFill
        bubbleView.layer.cornerRadius = AIChatBubbleStyle.botCornerRadius
        bubbleView.layer.borderWidth = AIChatBubbleStyle.botStrokeWidth
        bubbleView.layer.borderColor = AIChatBubbleStyle.botStroke.cgColor
        bubbleView.layer.masksToBounds = true
    }

    private func applyUserBubbleStyle() {
        AIChatShadow.apply(to: shadowContainer.layer)
        bubbleView.backgroundColor = AIChatBubbleStyle.userFill
        bubbleView.layer.cornerRadius = AIChatBubbleStyle.userCornerRadius
        bubbleView.layer.borderWidth = AIChatBubbleStyle.userStrokeWidth
        bubbleView.layer.borderColor = AIChatBubbleStyle.userStroke.cgColor
        bubbleView.layer.masksToBounds = true
    }

    private func makeTextAttributes() -> [NSAttributedString.Key: Any] {
        let p = NSMutableParagraphStyle()
        p.lineSpacing = 4
        return [
            .font: GeoTheme.Typography.body(size: 16),
            .paragraphStyle: p,
            .foregroundColor: AIChatTextColors.messagePrimary
        ]
    }

    private let shadowContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private let diaTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .natural
        label.lineBreakMode = .byCharWrapping
        return label
    }()

    private let spinner: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(style: .medium)
        activity.hidesWhenStopped = true
        return activity
    }()
}
