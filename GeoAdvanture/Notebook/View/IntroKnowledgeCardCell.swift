//
//  IntroKnowledgeCardCell.swift
//  GeoAdvanture
//
//  介绍页「图文知识卡」：标题行 + 可展开插图 + 正文。
//

import UIKit
import SnapKit

final class IntroKnowledgeCardCell: UITableViewCell {

    static let reuseId = "IntroKnowledgeCardCell"

    var onToggle: (() -> Void)?

    private let cardView = UIView()
    private let glyphLabel = UILabel()
    private let titleLabel = UILabel()
    private let chevronLabel = UILabel()
    private let illustrationContainer = UIView()
    private let contentLabel = UILabel()
    private var illustrationSubview: UIView?
    private var illustrationHeightConstraint: Constraint?
    private var bodyHeightConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor(red: 0.82, green: 0.72, blue: 0.55, alpha: 0.6).cgColor
        contentView.addSubview(cardView)

        glyphLabel.font = .systemFont(ofSize: 20)
        titleLabel.font = NotebookTypography.ListCell.titleFont
        titleLabel.textColor = NotebookTypography.ListCell.titleColor
        chevronLabel.font = .systemFont(ofSize: 14, weight: .bold)
        chevronLabel.textColor = NotebookTypography.ListCell.titleColor
        chevronLabel.text = "▼"

        contentLabel.numberOfLines = 0

        let header = UIStackView(arrangedSubviews: [glyphLabel, titleLabel, chevronLabel])
        header.axis = .horizontal
        header.spacing = 6
        header.alignment = .center

        cardView.addSubview(header)
        cardView.addSubview(illustrationContainer)
        cardView.addSubview(contentLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))
        }
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }
        chevronLabel.snp.makeConstraints { make in
            make.width.equalTo(20)
        }
        illustrationContainer.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(10)
            illustrationHeightConstraint = make.height.equalTo(0).constraint
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(illustrationContainer.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
            bodyHeightConstraint = make.height.equalTo(0).constraint
        }
        bodyHeightConstraint?.deactivate()

        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        cardView.addGestureRecognizer(tap)
    }

    func configure(row: IntroKnowledgeRow, layerId: String, expanded: Bool) {
        glyphLabel.text = row.glyph
        titleLabel.text = row.title
        contentLabel.attributedText = NotebookTypography.ListCell.attributedBody(row.content)
        chevronLabel.text = expanded ? "▲" : "▼"

        illustrationSubview?.removeFromSuperview()
        if expanded {
            let illus = LayerIntroIllustration.make(layerId: layerId, kind: row.kind)
            illustrationContainer.addSubview(illus)
            illus.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            illustrationSubview = illus
            illustrationHeightConstraint?.update(offset: 110)
            illustrationContainer.isHidden = false
            contentLabel.isHidden = false
            bodyHeightConstraint?.deactivate()
        } else {
            illustrationHeightConstraint?.update(offset: 0)
            illustrationContainer.isHidden = true
            contentLabel.isHidden = true
            bodyHeightConstraint?.activate()
        }
    }

    @objc private func headerTapped() {
        onToggle?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        illustrationSubview?.removeFromSuperview()
        illustrationSubview = nil
        onToggle = nil
    }
}
