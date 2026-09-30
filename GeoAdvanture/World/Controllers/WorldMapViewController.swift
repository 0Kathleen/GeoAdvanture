//
//  WorldMapViewController.swift
//  GeoAdvanture
//
//  选层页(竖直剖面):自地表向地心排列各层节点,按门禁显示 可进入 / 已通关(★) / 未解锁(🔒) / 敬请期待。
//  同时作为「下潜闭环」的装配者:进入世界 → 世界最右端出口 → 过场 → 打开下一层。
//  真美术到位后(PR-7)把卡片背景换成 map_bg / map_node_* 即可,导航逻辑不变。
//

import UIKit
import SnapKit

final class WorldMapViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var nodeCards: [WorldNodeCard] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1)
        setupHeader()
        setupList()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadStates()
    }

    // MARK: - UI

    private func setupHeader() {
        let back = UIButton(type: .system)
        back.setTitle("返回", for: .normal)
        back.setTitleColor(.white, for: .normal)
        back.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        back.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        view.addSubview(back)

        let title = UILabel()
        title.text = "选择下潜层"
        title.font = .systemFont(ofSize: 22, weight: .heavy)
        title.textColor = .white
        view.addSubview(title)

        let subtitle = UILabel()
        subtitle.text = "从地表一路潜向地心"
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.6)
        view.addSubview(subtitle)

        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
        }
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalTo(back.snp.bottom).offset(12)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(4)
        }

        scrollViewTopAnchor = subtitle.snp.bottom
    }

    private var scrollViewTopAnchor: ConstraintItem!

    private func setupList() {
        view.addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(scrollViewTopAnchor).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
            make.bottom.equalToSuperview().offset(-40)
        }

        for (i, world) in ContentStore.shared.worlds.enumerated() {
            if i > 0 {
                let connector = Self.makeConnector()
                stack.addArrangedSubview(connector)
            }
            let card = WorldNodeCard(world: world)
            card.onTap = { [weak self] in self?.handleTap(world) }
            stack.addArrangedSubview(card)
            card.snp.makeConstraints { make in make.height.equalTo(96) }
            nodeCards.append(card)
        }
    }

    private static func makeConnector() -> UIView {
        let container = UIView()
        let line = UIView()
        line.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        container.addSubview(line)
        line.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(3)
        }
        container.snp.makeConstraints { make in make.height.equalTo(18) }
        return container
    }

    // MARK: - 状态刷新

    private func reloadStates() {
        let gm = GameProgressManager.shared
        for card in nodeCards {
            let world = card.world
            let state: WorldNodeCard.State
            if world.isComingSoon {
                state = .comingSoon
            } else if gm.isWorldCompleted(id: world.id) {
                state = .completed
            } else if gm.canEnterWorld(world) {
                state = .enterable
            } else {
                state = .locked
            }
            card.apply(state: state)
        }
    }

    // MARK: - 交互 / 导航

    private func handleTap(_ world: WorldLayer) {
        let gm = GameProgressManager.shared
        if world.isComingSoon {
            presentInfo(title: "敬请期待", message: "「\(world.title)」将在二期开放。")
            return
        }
        guard gm.canEnterWorld(world) else {
            presentInfo(title: "🔒 尚未解锁", message: "先通关上一层,才能下潜到「\(world.title)」。")
            return
        }
        openWorld(id: world.id, animated: true)
    }

    private func openWorld(id: String, animated: Bool) {
        guard let vc = WorldViewController(worldId: id) else { return }
        vc.onRequestDescend = { [weak self] fromId in self?.descend(from: fromId) }
        present(vc, animated: animated)
    }

    /// 下潜闭环:关闭当前世界(及其上的过场),刷新门禁,再打开下一层。
    private func descend(from fromId: String) {
        guard let cur = ContentStore.shared.world(id: fromId),
              let next = ContentStore.shared.world(at: cur.index + 1),
              !next.isComingSoon else {
            dismiss(animated: true)
            return
        }
        dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            self.reloadStates()
            self.openWorld(id: next.id, animated: false)
        }
    }

    private func presentInfo(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    @objc private func tapBack() { dismiss(animated: true) }
}

// MARK: - 层节点卡片

private final class WorldNodeCard: UIControl {

    enum State { case enterable, completed, locked, comingSoon }

    let world: WorldLayer
    var onTap: (() -> Void)?

    private let iconView = UILabel()
    private let titleLabel = UILabel()
    private let depthLabel = UILabel()
    private let badgeLabel = UILabel()

    init(world: WorldLayer) {
        self.world = world
        super.init(frame: .zero)
        layer.cornerRadius = 18
        clipsToBounds = true
        setup()
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        let palette = WorldPalette.forWorld(world.id)
        backgroundColor = palette.sky

        iconView.font = .systemFont(ofSize: 40)
        iconView.text = Self.glyph(for: world)
        addSubview(iconView)

        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.text = world.title
        addSubview(titleLabel)

        depthLabel.font = .systemFont(ofSize: 13)
        depthLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        depthLabel.text = Self.depthText(for: world)
        addSubview(depthLabel)

        badgeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .right
        badgeLabel.numberOfLines = 2
        addSubview(badgeLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.top.equalToSuperview().offset(24)
        }
        depthLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        badgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(130)
        }
    }

    func apply(state: State) {
        switch state {
        case .enterable:
            badgeLabel.text = "进入 ▸"
            alpha = 1
            isUserInteractionEnabled = true
        case .completed:
            badgeLabel.text = "★ 已通关\n可重玩"
            alpha = 1
            isUserInteractionEnabled = true
        case .locked:
            badgeLabel.text = "🔒 未解锁"
            alpha = 0.55
            isUserInteractionEnabled = true // 允许点出提示
        case .comingSoon:
            badgeLabel.text = "敬请期待\n(二期)"
            alpha = 0.5
            isUserInteractionEnabled = true
        }
    }

    @objc private func tapped() { onTap?() }

    // MARK: - 占位内容

    private static func glyph(for world: WorldLayer) -> String {
        switch world.index {
        case 0: return "🏔"
        case 1: return "🌋"
        case 2: return "🔥"
        case 3: return "💎"
        default: return "🌍"
        }
    }

    private static func depthText(for world: WorldLayer) -> String {
        switch world.index {
        case 0: return "地表 · 0–35 km"
        case 1: return "地幔 · 35–2900 km"
        case 2: return "外核 · 2900–5100 km"
        case 3: return "内核 · 5100–6371 km"
        default: return ""
        }
    }
}
