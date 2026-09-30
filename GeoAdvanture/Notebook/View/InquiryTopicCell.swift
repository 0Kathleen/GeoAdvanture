//
//  InquiryTopicCell.swift
//  GeoAdvanture
//
//  “认识”页右侧探索问题卡：问题、进度、原理与误区。
//

import UIKit
import SnapKit

final class InquiryTopicCell: UITableViewCell {

    static let reuseId = "InquiryTopicCell"

    var onExplore: (() -> Void)?

    private let cardView = UIView()
    private let numberLabel = UILabel()
    private let titleLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let detailStack = UIStackView()
    private let explanationLabel = UILabel()
    private let misconceptionLabel = UILabel()
    private let exploreButton = UIButton(type: .system)
    private let chevronLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        GeoTheme.applyPaperCard(to: cardView)
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 4, bottom: 5, right: 4))
        }

        numberLabel.font = GeoTheme.Typography.control(size: 13)
        numberLabel.textAlignment = .center
        numberLabel.textColor = .white
        numberLabel.backgroundColor = GeoTheme.Color.inkMuted
        numberLabel.layer.cornerRadius = 13
        numberLabel.clipsToBounds = true

        titleLabel.font = NotebookTypography.ListCell.titleFont.withSize(17)
        titleLabel.textColor = NotebookTypography.ListCell.titleColor
        titleLabel.numberOfLines = 2

        progressLabel.font = GeoTheme.Typography.caption(size: 11)
        progressLabel.textAlignment = .center
        progressLabel.layer.cornerRadius = 9
        progressLabel.clipsToBounds = true

        chevronLabel.font = GeoTheme.Typography.control(size: 11)
        chevronLabel.textColor = NotebookTypography.ListCell.titleColor

        progressView.trackTintColor = GeoTheme.Color.separator
        progressView.progressTintColor = GeoTheme.Color.success

        detailStack.axis = .vertical
        detailStack.spacing = 7
        explanationLabel.numberOfLines = 0
        misconceptionLabel.numberOfLines = 0
        detailStack.addArrangedSubview(explanationLabel)
        detailStack.addArrangedSubview(misconceptionLabel)
        detailStack.addArrangedSubview(exploreButton)

        exploreButton.titleLabel?.font = GeoTheme.Typography.control(size: 13)
        exploreButton.tintColor = .white
        exploreButton.backgroundColor = GeoTheme.Color.teal
        exploreButton.layer.cornerRadius = GeoTheme.Radius.control
        exploreButton.addTarget(self, action: #selector(exploreTapped), for: .touchUpInside)
        exploreButton.snp.makeConstraints { make in make.height.equalTo(34) }

        let header = UIStackView(arrangedSubviews: [numberLabel, titleLabel, progressLabel, chevronLabel])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        numberLabel.snp.makeConstraints { make in make.size.equalTo(CGSize(width: 26, height: 26)) }
        progressLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(46)
            make.height.equalTo(20)
        }
        chevronLabel.snp.makeConstraints { make in make.width.equalTo(14) }

        cardView.addSubview(header)
        cardView.addSubview(progressView)
        cardView.addSubview(detailStack)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(11)
        }
        progressView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        detailStack.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

    }

    func configure(data: NotebookInquiryViewData, number: Int, expanded: Bool, focused: Bool) {
        numberLabel.text = "\(number)"
        titleLabel.text = data.topic.title
        progressLabel.text = "\(data.discoveredCount)/\(data.totalCount)"
        progressLabel.textColor = data.isCompleted ? .white : NotebookTypography.ListCell.titleColor
        progressLabel.backgroundColor = data.isCompleted
            ? GeoTheme.Color.success
            : GeoTheme.Color.paperMuted
        progressView.progress = data.totalCount == 0
            ? 0
            : Float(data.discoveredCount) / Float(data.totalCount)
        chevronLabel.text = expanded ? "▲" : "▼"

        explanationLabel.attributedText = detailText(
            title: "原理线索",
            body: data.topic.explanation,
            color: NotebookTypography.ListCell.bodyColor)
        misconceptionLabel.attributedText = detailText(
            title: "容易误会",
            body: data.topic.misconception ?? "",
            color: GeoTheme.Color.clay)
        misconceptionLabel.isHidden = data.topic.misconception?.isEmpty ?? true
        exploreButton.setTitle(data.isCompleted ? "回地图复习证据" : "去地图寻找证据 →", for: .normal)
        detailStack.isHidden = !expanded

        cardView.layer.borderWidth = focused ? 2.5 : 1
        cardView.layer.borderColor = focused
            ? GeoTheme.Color.warning.cgColor
            : GeoTheme.Color.separator.cgColor
        cardView.accessibilityValue = focused ? "当前定位" : nil
    }

    private func detailText(title: String, body: String, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: "\(title)：",
            attributes: [.font: GeoTheme.Typography.control(size: 12), .foregroundColor: color])
        result.append(NSAttributedString(
            string: body,
            attributes: [.font: GeoTheme.Typography.body(size: 12), .foregroundColor: color]))
        return result
    }

    @objc private func exploreTapped() { onExplore?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onExplore = nil
    }
}
