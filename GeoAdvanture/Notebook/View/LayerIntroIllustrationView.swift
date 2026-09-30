//
//  LayerIntroIllustrationView.swift
//  GeoAdvanture
//
//  介绍页知识卡顶部示意图工厂：按「圈层 + 卡片类型」产出占位插图。
//

import UIKit
import SnapKit

enum LayerIntroIllustration {

    static func make(layerId: String, kind: IntroKnowledgeRow.Kind) -> UIView {
        switch kind {
        case .feature, .compare:
            return EarthCrossSectionDiagramView(highlightLayerId: layerId)
        case .life:
            return LifeConnectionIllustrationView(layerId: layerId)
        case .fun:
            return FunFactIllustrationView(layerId: layerId)
        }
    }
}

// MARK: - 生活联系：三枚主题 emoji

private final class LifeConnectionIllustrationView: UIView {
    init(layerId: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.systemTeal.withAlphaComponent(0.12)
        layer.cornerRadius = 10

        let items = Self.items(for: layerId)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
            make.height.equalTo(90)
        }

        for item in items {
            let col = UIStackView()
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 4
            let emoji = UILabel()
            emoji.text = item.emoji
            emoji.font = .systemFont(ofSize: 28)
            let cap = UILabel()
            cap.text = item.caption
            cap.font = .systemFont(ofSize: 11)
            cap.textColor = NotebookTypography.ListCell.bodyColor
            cap.textAlignment = .center
            cap.numberOfLines = 2
            col.addArrangedSubview(emoji)
            col.addArrangedSubview(cap)
            stack.addArrangedSubview(col)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private struct Item { let emoji: String; let caption: String }

    private static func items(for layerId: String) -> [Item] {
        switch layerId {
        case "mantle":
            return [
                Item(emoji: "🌋", caption: "火山岩浆"),
                Item(emoji: "💎", caption: "宝石诞生"),
                Item(emoji: "🏔", caption: "板块运动")
            ]
        case "core":
            return [
                Item(emoji: "🧭", caption: "指南针"),
                Item(emoji: "🛡", caption: "磁场保护"),
                Item(emoji: "☀️", caption: "挡住射线")
            ]
        default:
            return [
                Item(emoji: "🏠", caption: "脚下土地"),
                Item(emoji: "🛣", caption: "砂石建材"),
                Item(emoji: "💎", caption: "矿石宝石")
            ]
        }
    }
}

// MARK: - 趣味冷知识：大字 emoji + 提示

private final class FunFactIllustrationView: UIView {
    init(layerId: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
        layer.cornerRadius = 10

        let emoji = UILabel()
        emoji.text = Self.glyph(for: layerId)
        emoji.font = .systemFont(ofSize: 44)
        emoji.textAlignment = .center

        let hint = UILabel()
        hint.text = "你知道吗?"
        hint.font = .systemFont(ofSize: 14, weight: .semibold)
        hint.textColor = NotebookTypography.ListCell.titleColor
        hint.textAlignment = .center

        addSubview(emoji)
        addSubview(hint)
        emoji.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }
        hint.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(emoji.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(12)
        }
        snp.makeConstraints { make in make.height.equalTo(90) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func glyph(for layerId: String) -> String {
        switch layerId {
        case "mantle": return "🍯"
        case "core": return "🔥"
        default: return "🥚"
        }
    }
}
