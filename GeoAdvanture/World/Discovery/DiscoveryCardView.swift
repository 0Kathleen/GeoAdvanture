//
//  DiscoveryCardView.swift
//  GeoAdvanture
//
//  发现卡弹层：走近 POI 触发。展示「插画占位 + 标题 + 发生了什么 + 为什么 + 主操作」。
//  真美术到位后（PR-7）把插画占位换成 illus_<poi> 即可，接口不变。
//  行为通过闭包回调交给 WorldViewController 决定（采集 / 去操作 / 明白了）。
//

import UIKit
import SnapKit

final class DiscoveryCardView: UIView {

    var onClose: (() -> Void)?
    var onPrimary: (() -> Void)?
    /// 点击「问一问」入口（PR-6 · AI 小功能），由 VC 决定弹出问答层。
    var onAsk: (() -> Void)?

    private let card = UIView()
    private let primaryButton = UIButton(type: .system)
    private let askButton = UIButton(type: .system)

    /// - Parameters:
    ///   - poi: 现象点内容
    ///   - primaryTitle: 主按钮文案（由 VC 按交互类型/是否已采集决定）
    ///   - primaryEnabled: 主按钮是否可点（如已采集则禁用）
    init(poi: POI, primaryTitle: String, primaryEnabled: Bool) {
        super.init(frame: .zero)
        buildUI(poi: poi, primaryTitle: primaryTitle, primaryEnabled: primaryEnabled)
        animateIn()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - 构建

    private func buildUI(poi: POI, primaryTitle: String, primaryEnabled: Bool) {
        backgroundColor = UIColor.black.withAlphaComponent(0.55)

        // 点击暗色区域关闭
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimTapped))
        addGestureRecognizer(tap)

        card.backgroundColor = UIColor(white: 0.12, alpha: 1)
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 2
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        card.clipsToBounds = true
        addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
            make.width.equalTo(360).priority(.high)
            make.width.lessThanOrEqualToSuperview().offset(-48)
        }

        // 插画占位（真美术前用主题色 + 类型字形）
        let illus = UIView()
        illus.backgroundColor = Self.color(for: poi.interactionType)
        card.addSubview(illus)
        illus.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(140)
        }
        let glyph = UILabel()
        glyph.text = Self.glyph(for: poi.interactionType)
        glyph.font = .systemFont(ofSize: 64)
        illus.addSubview(glyph)
        glyph.snp.makeConstraints { $0.center.equalToSuperview() }

        // 关闭 ×
        let close = UIButton(type: .system)
        close.setTitle("✕", for: .normal)
        close.setTitleColor(.white, for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        close.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        close.layer.cornerRadius = 16
        close.addTarget(self, action: #selector(dimTapped), for: .touchUpInside)
        card.addSubview(close)
        close.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.width.height.equalTo(32)
        }

        // 标题
        let title = UILabel()
        title.text = poi.title
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = .white
        title.numberOfLines = 0
        card.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalTo(illus.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // 「发生了什么」+「为什么」
        let whatTitle = sectionTitle("发生了什么")
        let whatBody = sectionBody(poi.phenomenon)
        let whyTitle = sectionTitle("为什么")
        let whyBody = sectionBody(poi.explanation)

        let stack = UIStackView(arrangedSubviews: [whatTitle, whatBody, whyTitle, whyBody])
        stack.axis = .vertical
        stack.spacing = 6
        stack.setCustomSpacing(14, after: whatBody)
        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // 「问一问岩小探」入口（PR-6 · AI 小功能）
        askButton.setTitle("🤔 问一问岩小探", for: .normal)
        askButton.setTitleColor(.systemTeal, for: .normal)
        askButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        askButton.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.15)
        askButton.layer.cornerRadius = 14
        askButton.layer.borderWidth = 1
        askButton.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.5).cgColor
        askButton.addTarget(self, action: #selector(askTapped), for: .touchUpInside)
        card.addSubview(askButton)
        askButton.snp.makeConstraints { make in
            make.top.equalTo(stack.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(46)
        }

        // 主操作按钮
        primaryButton.setTitle(primaryTitle, for: .normal)
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        primaryButton.backgroundColor = primaryEnabled ? .systemBlue : UIColor(white: 0.3, alpha: 1)
        primaryButton.isEnabled = primaryEnabled
        primaryButton.layer.cornerRadius = 14
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        card.addSubview(primaryButton)
        primaryButton.snp.makeConstraints { make in
            make.top.equalTo(askButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = .systemTeal
        return l
    }

    private func sectionBody(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15)
        l.textColor = UIColor(white: 0.9, alpha: 1)
        l.numberOfLines = 0
        return l
    }

    // MARK: - 动画

    private func animateIn() {
        card.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        card.alpha = 0
        alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
            self.card.alpha = 1
            self.card.transform = .identity
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    // MARK: - 交互

    @objc private func dimTapped() {
        onClose?()
        dismiss()
    }

    @objc private func primaryTapped() {
        onPrimary?()
    }

    @objc private func askTapped() {
        onAsk?()
    }

    // MARK: - 占位样式映射（与 POINode 一致）

    private static func color(for type: POIInteractionType) -> UIColor {
        switch type {
        case .observe: return .systemTeal
        case .inquiry: return .systemPurple
        case .collect: return .systemYellow
        case .operate: return .systemOrange
        }
    }

    private static func glyph(for type: POIInteractionType) -> String {
        switch type {
        case .observe: return "👁"
        case .inquiry: return "❓"
        case .collect: return "💎"
        case .operate: return "🎮"
        }
    }
}
