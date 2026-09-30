//
//  LayerProfileCardView.swift
//  GeoAdvanture
//
//  介绍页「圈层身份卡」与整体知识骨架。
//

import UIKit
import SnapKit

final class LayerProfileCardView: UIView {

    init(profile: LayerProfile, overview: LayerOverviewViewData) {
        super.init(frame: .zero)
        backgroundColor = .clear
        layer.cornerRadius = GeoTheme.Radius.card
        layer.borderWidth = 1
        layer.borderColor = GeoTheme.Color.separator.cgColor

        let icon = UIImageView(image: UIImage(systemName: "scope"))
        icon.tintColor = GeoTheme.Color.mauve
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "\(overview.layerName) · 圈层身份"
        title.font = GeoTheme.Typography.heading(size: 15)
        title.textColor = GeoTheme.Color.ink

        let position = UILabel()
        position.text = overview.position
        position.font = GeoTheme.Typography.caption(size: 10)
        position.textColor = GeoTheme.Color.mauve
        position.textAlignment = .left

        let titleStack = UIStackView(arrangedSubviews: [title, position])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        let header = UIStackView(arrangedSubviews: [icon, titleStack])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 7
        icon.snp.makeConstraints { $0.width.height.equalTo(30) }

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 6

        grid.addArrangedSubview(makeRow(
            left: ("深度范围", profile.depthRange, "ruler"),
            right: ("温度", profile.temperature, "thermometer.medium")))
        grid.addArrangedSubview(makeRow(
            left: ("主要组成", profile.composition, "cube.fill"),
            right: ("物质状态", profile.state, "circle.dotted")))

        let stack = UIStackView(arrangedSubviews: [header, grid])
        stack.axis = .vertical
        stack.spacing = 9
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(11) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func makeRow(left: (String, String, String), right: (String, String, String)) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        row.addArrangedSubview(makeStat(label: left.0, value: left.1, symbol: left.2))
        row.addArrangedSubview(makeStat(label: right.0, value: right.1, symbol: right.2))
        return row
    }

    private func makeStat(label: String, value: String, symbol: String) -> UIView {
        let box = UIView()
        box.backgroundColor = .clear
        box.layer.cornerRadius = 9
        box.layer.borderWidth = 1
        box.layer.borderColor = GeoTheme.Color.separator.cgColor

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = GeoTheme.Color.teal
        icon.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = GeoTheme.Typography.caption(size: 9)
        titleLabel.textColor = GeoTheme.Color.inkMuted

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = GeoTheme.Typography.control(size: 11)
        valueLabel.textColor = GeoTheme.Color.ink
        valueLabel.numberOfLines = 2
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8

        box.addSubview(icon)
        box.addSubview(titleLabel)
        box.addSubview(valueLabel)

        icon.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(7)
            make.width.height.equalTo(15)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(4)
            make.centerY.equalTo(icon)
            make.trailing.lessThanOrEqualToSuperview().inset(5)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(7)
            make.top.equalTo(icon.snp.bottom).offset(3)
            make.bottom.equalToSuperview().inset(6)
        }
        box.snp.makeConstraints { make in make.height.greaterThanOrEqualTo(48) }
        return box
    }
}

final class LayerOverviewCardView: UIView {

    init(overview: LayerOverviewViewData, title: String?) {
        super.init(frame: .zero)
        backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = GeoTheme.Typography.heading(size: 14)
        titleLabel.textColor = GeoTheme.Color.mauve

        let definition = UILabel()
        definition.text = overview.definition
        definition.font = GeoTheme.Typography.body(size: 11)
        definition.textColor = GeoTheme.Color.ink
        definition.numberOfLines = 2

        let framework = LayerKnowledgeFrameworkView(branches: overview.branches)
        framework.snp.makeConstraints { $0.height.equalTo(58) }

        let divider = UIView()
        divider.backgroundColor = GeoTheme.Color.separator
        divider.snp.makeConstraints { $0.height.equalTo(1) }

        var arranged: [UIView] = []
        if let title, !title.isEmpty { arranged.append(titleLabel) }
        arranged.append(contentsOf: [definition, framework, divider])
        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 7
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class LayerKnowledgeFrameworkView: UIView {

    init(branches: [LayerOverviewBranchViewData]) {
        super.init(frame: .zero)
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 5
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }

        var cards: [UIView] = []
        for (index, branch) in branches.enumerated() {
            let card = makeCard(branch)
            cards.append(card)
            row.addArrangedSubview(card)
            if index < branches.count - 1 {
                let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
                arrow.tintColor = GeoTheme.Color.mauve.withAlphaComponent(0.55)
                arrow.contentMode = .scaleAspectFit
                arrow.snp.makeConstraints { $0.width.equalTo(8) }
                row.addArrangedSubview(arrow)
            }
        }
        for card in cards.dropFirst() { card.snp.makeConstraints { $0.width.equalTo(cards[0]) } }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func makeCard(_ branch: LayerOverviewBranchViewData) -> UIView {
        let card = UIView()
        card.backgroundColor = .clear
        card.layer.cornerRadius = 9
        card.layer.borderWidth = 1
        card.layer.borderColor = GeoTheme.Color.separator.cgColor

        let icon = UIImageView(image: UIImage(systemName: branch.systemImage))
        icon.tintColor = GeoTheme.Color.teal
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = branch.title
        title.font = GeoTheme.Typography.control(size: 10)
        title.textColor = GeoTheme.Color.ink
        let detail = UILabel()
        detail.text = branch.detail
        detail.font = GeoTheme.Typography.caption(size: 9)
        detail.textColor = GeoTheme.Color.inkMuted
        detail.adjustsFontSizeToFitWidth = true
        detail.minimumScaleFactor = 0.75

        let labels = UIStackView(arrangedSubviews: [title, detail])
        labels.axis = .vertical
        labels.spacing = 1
        card.addSubview(icon)
        card.addSubview(labels)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(7)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(17)
        }
        labels.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(5)
            make.trailing.equalToSuperview().inset(5)
            make.centerY.equalToSuperview()
        }
        return card
    }
}
