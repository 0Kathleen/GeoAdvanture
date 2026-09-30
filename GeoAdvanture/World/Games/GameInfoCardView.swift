//
//  GameInfoCardView.swift
//  GeoAdvanture
//
//  游戏通用信息卡(可复用):进入前的「操作提示卡」与通关后的「知识卡」共用一套样式,
//  用 style 区分强调色/图标。知识卡把「你的操作」与「地球内部结构」联系起来。
//  真美术到位后把顶部色条换成插画即可,接口不变。
//

import UIKit
import SnapKit

final class GameInfoCardView: UIView {

    enum Style {
        case tip        // 操作提示(进入时)
        case knowledge  // 知识卡(通关后)

        var accent: UIColor {
            switch self {
            case .tip: return GeoTheme.Color.clay
            case .knowledge: return GeoTheme.Color.teal
            }
        }
        var glyph: String {
            switch self {
            case .tip: return "🎮"
            case .knowledge: return "💡"
            }
        }
    }

    var onDismiss: (() -> Void)?

    private let card = UIView()

    /// - Parameters:
    ///   - style: 提示 / 知识
    ///   - title: 卡片标题
    ///   - lines: 逐条要点(自动加圆点)
    ///   - buttonTitle: 主按钮文案
    ///   - illustration: 顶部插图视图(图文混合)。传 nil 用纯色条 + emoji 占位;
    ///     PR-7 可传 `UIImageView(image:)` 换成 AI 生成插画,接口不变。
    init(style: Style, title: String, lines: [String], buttonTitle: String, illustration: UIView? = nil) {
        super.init(frame: .zero)
        build(style: style, title: title, lines: lines, buttonTitle: buttonTitle, illustration: illustration)
        animateIn()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(style: Style, title: String, lines: [String], buttonTitle: String, illustration: UIView?) {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)

        card.backgroundColor = GeoTheme.Color.paper
        card.layer.cornerRadius = GeoTheme.Radius.modal
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        card.clipsToBounds = true
        addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(600).priority(.high)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        // 顶部视觉:有插图→图文混合;无插图→纯色条 + emoji
        let topVisual = UIView()
        card.addSubview(topVisual)
        topVisual.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(illustration == nil ? 68 : 132)
        }
        if let illustration = illustration {
            topVisual.backgroundColor = style.accent.withAlphaComponent(0.18)
            topVisual.clipsToBounds = true
            topVisual.addSubview(illustration)
            illustration.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            topVisual.backgroundColor = style.accent.withAlphaComponent(0.16)
            let glyph = UILabel()
            glyph.text = style.glyph
            glyph.font = .systemFont(ofSize: 30)
            let heading = UILabel()
            heading.text = title
            heading.font = GeoTheme.Typography.heading(size: 21)
            heading.textColor = GeoTheme.Color.ink
            heading.numberOfLines = 1
            topVisual.addSubview(glyph)
            topVisual.addSubview(heading)
            glyph.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
            }
            heading.snp.makeConstraints { make in
                make.leading.equalTo(glyph.snp.trailing).offset(12)
                make.trailing.equalToSuperview().inset(20)
                make.centerY.equalToSuperview()
            }
        }

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = GeoTheme.Typography.heading(size: 21)
        titleLabel.textColor = GeoTheme.Color.ink
        titleLabel.numberOfLines = 0
        titleLabel.isHidden = illustration == nil
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topVisual.snp.bottom).offset(illustration == nil ? 0 : 12)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // 信息层级：先告诉孩子“这一关要完成什么”，再给两条短步骤。
        // 主目标与操作提示不再并列抢注意力，也避免三块长文字造成阅读压力。
        let roleTitles: [String]
        let symbols: [String]
        switch style {
        case .tip:
            roleTitles = ["本关目标", "怎么做", "完成条件"]
            symbols = ["scope", "hand.draw.fill", "checkmark.circle.fill"]
        case .knowledge:
            roleTitles = ["发现", "原因", "联系"]
            symbols = ["checkmark.seal.fill", "lightbulb.fill", "arrow.triangle.branch"]
        }

        func makeInfoCard(index: Int, line: String, prominent: Bool) -> UIView {
            let row = UIView()
            row.backgroundColor = prominent
                ? style.accent.withAlphaComponent(0.12)
                : UIColor.white.withAlphaComponent(0.62)
            row.layer.cornerRadius = 13
            row.layer.borderWidth = 1
            row.layer.borderColor = style.accent.withAlphaComponent(prominent ? 0.28 : 0.14).cgColor

            let icon = UIImageView(image: UIImage(systemName: symbols[index]))
            icon.tintColor = style.accent
            icon.contentMode = .scaleAspectFit

            let role = UILabel()
            role.text = roleTitles[index]
            role.font = GeoTheme.Typography.heading(size: prominent ? 12 : 11)
            role.textColor = style.accent

            let body = UILabel()
            body.text = line
            body.font = GeoTheme.Typography.body(size: prominent ? 15 : 13)
            body.textColor = GeoTheme.Color.ink
            body.numberOfLines = prominent ? 2 : 3

            let textStack = UIStackView(arrangedSubviews: [role, body])
            textStack.axis = .vertical
            textStack.alignment = .fill
            textStack.spacing = prominent ? 3 : 5

            let content = UIStackView(arrangedSubviews: [icon, textStack])
            content.axis = .horizontal
            content.alignment = .center
            content.spacing = 10
            row.addSubview(content)
            icon.snp.makeConstraints { make in
                make.width.height.equalTo(prominent ? 24 : 19)
            }
            content.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(prominent ? 13 : 11)
            }
            row.snp.makeConstraints {
                $0.height.greaterThanOrEqualTo(prominent ? 66 : 72)
            }
            return row
        }

        let visibleLines = Array(lines.prefix(3))
        let informationStack = UIStackView()
        informationStack.axis = .vertical
        informationStack.spacing = 9
        if let firstLine = visibleLines.first {
            informationStack.addArrangedSubview(makeInfoCard(index: 0, line: firstLine, prominent: true))
        }
        if visibleLines.count > 1 {
            let details = UIStackView()
            details.axis = .horizontal
            details.alignment = .fill
            details.distribution = .fillEqually
            details.spacing = 9
            for index in 1..<visibleLines.count {
                details.addArrangedSubview(makeInfoCard(index: index, line: visibleLines[index], prominent: false))
            }
            informationStack.addArrangedSubview(details)
        }
        card.addSubview(informationStack)
        informationStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(illustration == nil ? 10 : 9)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // 按钮
        let button = UIButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = GeoTheme.Typography.control(size: 16)
        button.backgroundColor = style.accent
        button.layer.cornerRadius = GeoTheme.Radius.control
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        card.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(informationStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-18)
        }
    }

    private func animateIn() {
        alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
            self.card.transform = .identity
        }
    }

    @objc private func dismissTapped() {
        UIView.animate(withDuration: 0.15, animations: { self.alpha = 0 }, completion: { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        })
    }

    /// 便捷:铺满宿主 VC 的 view 并添加。
    func present(in host: UIView) {
        frame = host.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)
    }
}
