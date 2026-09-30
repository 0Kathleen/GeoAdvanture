//
//  SpecimenIllustrationView.swift
//  GeoAdvanture
//
//  采集知识卡用的「标本」插图占位(图文混合):分类色底 + 字形 + 名称。
//  PR-7 可换成 collect_<id> 真插画,接口不变。
//

import UIKit

final class SpecimenIllustrationView: UIView {

    init(collectible: Collectible) {
        super.init(frame: .zero)
        backgroundColor = Self.color(for: collectible.category).withAlphaComponent(0.35)

        let glyph = UILabel()
        glyph.text = Self.glyph(for: collectible.category)
        glyph.font = .systemFont(ofSize: 64)
        glyph.textAlignment = .center
        addSubview(glyph)
        glyph.translatesAutoresizingMaskIntoConstraints = false

        let name = UILabel()
        name.text = collectible.name
        name.font = GeoTheme.Typography.heading(size: 16)
        name.textColor = .white
        name.textAlignment = .center
        addSubview(name)
        name.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -12),
            name.topAnchor.constraint(equalTo: glyph.bottomAnchor, constant: 2),
            name.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func color(for category: String) -> UIColor {
        switch category {
        case "rock": return .systemBrown
        case "mineral": return .systemTeal
        case "fossil": return .systemIndigo
        default: return .systemGray
        }
    }

    private static func glyph(for category: String) -> String {
        switch category {
        case "rock": return "🪨"
        case "mineral": return "💎"
        case "fossil": return "🦴"
        default: return "📦"
        }
    }
}
