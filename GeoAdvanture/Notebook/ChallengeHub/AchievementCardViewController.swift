//
//  AchievementCardViewController.swift
//  GeoAdvanture
//
//  Step 6：所有关卡共用的“左图右成就”结果页。
//

import UIKit
import SnapKit

final class AchievementCardViewController: UIViewController {

    enum ExitAction {
        case continueChallenge
        case returnToHub
    }

    private let result: ChallengeResult
    private let content: AchievementCardDefinition
    private let isMilestone: Bool
    private let supportsImmersive: Bool
    private let onFinish: (ExitAction) -> Void
    private var didFinish = false

    init(result: ChallengeResult,
         content: AchievementCardDefinition,
         isMilestone: Bool,
         supportsImmersive: Bool,
         onFinish: @escaping (ExitAction) -> Void) {
        self.result = result
        self.content = content
        self.isMilestone = isMilestone
        self.supportsImmersive = supportsImmersive
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = GeoTheme.Color.darkSurface

        let paper = UIView()
        paper.backgroundColor = GeoTheme.Color.paper
        paper.layer.cornerRadius = GeoTheme.Radius.modal
        paper.layer.borderWidth = 2
        paper.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        view.addSubview(paper)
        paper.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide).inset(8) }

        let ribbon = UILabel()
        ribbon.text = isMilestone ? "  ★ 总成就  " : "  新成就  "
        ribbon.font = GeoTheme.Typography.control(size: 13)
        ribbon.textColor = .white
        ribbon.textAlignment = .center
        ribbon.backgroundColor = isMilestone
            ? GeoTheme.Color.warning
            : GeoTheme.Color.success
        ribbon.layer.cornerRadius = 12
        ribbon.clipsToBounds = true
        paper.addSubview(ribbon)

        let artwork = AchievementArtworkView(content: content, result: result)
        paper.addSubview(artwork)

        let rightPanel = UIView()
        GeoTheme.applyPaperCard(to: rightPanel, radius: GeoTheme.Radius.modal)
        paper.addSubview(rightPanel)

        let title = makeLabel(content.title, size: 24, weight: .heavy,
                              color: GeoTheme.Color.ink)
        let subtitle = makeLabel(content.subtitle, size: 12, weight: .semibold,
                                 color: GeoTheme.Color.inkMuted)

        let score = UILabel()
        score.text = scoreText
        score.font = GeoTheme.Typography.control(size: 16)
        score.textColor = GeoTheme.Color.warning

        let heading = UIStackView(arrangedSubviews: [title, subtitle])
        heading.axis = .vertical
        heading.spacing = 1
        let header = UIStackView(arrangedSubviews: [heading, score])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        let actionBlock = infoBlock(symbol: "hand.tap.fill", title: "你完成了", body: content.actionSummary)
        let evidenceBlock = infoBlock(symbol: "magnifyingglass", title: "你观察到", body: content.observationSummary)
        let rewardBlock = rewardView()

        let continueButton = makeButton(
            title: isMilestone ? "查看修复成果" : "继续探索",
            background: GeoTheme.Color.teal)
        continueButton.addAction(UIAction { [weak self] _ in
            self?.finish(.continueChallenge)
        }, for: .touchUpInside)

        let returnButton = makeButton(
            title: "返回探索站",
            background: GeoTheme.Color.inkMuted)
        returnButton.addAction(UIAction { [weak self] _ in
            self?.finish(.returnToHub)
        }, for: .touchUpInside)

        let buttons: [UIView] = [returnButton, continueButton]
        let buttonRow = UIStackView(arrangedSubviews: buttons)
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fillEqually
        buttons.forEach { $0.snp.makeConstraints { $0.height.equalTo(40) } }

        let stack = UIStackView(arrangedSubviews: [header, rewardBlock, actionBlock, evidenceBlock, buttonRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fill
        rightPanel.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        ribbon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(22)
        }
        artwork.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalTo(ribbon.snp.bottom).offset(8)
            make.bottom.equalToSuperview().inset(10)
            make.width.equalToSuperview().multipliedBy(0.46)
        }
        rightPanel.snp.makeConstraints { make in
            make.leading.equalTo(artwork.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(14)
            make.top.bottom.equalTo(artwork)
        }
    }

    private var scoreText: String {
        let clamped = max(1, min(3, result.score))
        return String(repeating: "★", count: clamped) + String(repeating: "☆", count: 3 - clamped)
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = size >= 18
            ? GeoTheme.Typography.heading(size: size)
            : GeoTheme.Typography.body(size: size)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func infoBlock(symbol: String, title: String, body: String) -> UIView {
        let container = UIView()
        container.backgroundColor = GeoTheme.Color.paperMuted.withAlphaComponent(0.58)
        container.layer.cornerRadius = GeoTheme.Radius.control

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = GeoTheme.Color.teal
        icon.contentMode = .scaleAspectFit
        let label = makeLabel("\(title)\n\(body)", size: 12, weight: .medium,
                              color: GeoTheme.Color.ink)
        let attributed = NSMutableAttributedString(string: label.text ?? "")
        attributed.addAttribute(.font, value: GeoTheme.Typography.control(size: 12),
                                range: NSRange(location: 0, length: title.count))
        label.attributedText = attributed

        container.addSubview(icon)
        container.addSubview(label)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(label)
            make.width.height.equalTo(22)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(9)
        }
        return container
    }

    private func rewardView() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.95, green: 0.78, blue: 0.33, alpha: 0.23)
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.75, green: 0.48, blue: 0.13, alpha: 0.35).cgColor

        let badge = UIImageView(image: UIImage(systemName: "seal.fill"))
        badge.tintColor = GeoTheme.Color.warning
        let label = makeLabel("\(content.rewardTitle)\n\(content.rewardDescription)", size: 12, weight: .medium,
                              color: GeoTheme.Color.ink)
        let attributed = NSMutableAttributedString(string: label.text ?? "")
        attributed.addAttribute(.font, value: GeoTheme.Typography.heading(size: 14),
                                range: NSRange(location: 0, length: content.rewardTitle.count))
        label.attributedText = attributed
        container.addSubview(badge)
        container.addSubview(label)
        badge.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(27)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(badge.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(9)
        }
        return container
    }

    private func makeButton(title: String, background: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = GeoTheme.Typography.control(size: 15)
        button.backgroundColor = background
        button.layer.cornerRadius = GeoTheme.Radius.control
        return button
    }

    private func finish(_ action: ExitAction) {
        guard !didFinish else { return }
        didFinish = true
        LearningProgressCoordinator.shared.recordChallengeResult(
            result,
            primaryTopicId: content.knowledgeTopicId)
        onFinish(action)
    }

    private func showImmersivePreviewNotice() {
        let alert = UIAlertController(
            title: "3D / AR 观察入口已解锁",
            message: "你已集齐三种板块边界证据。最终地形模型将在美术资源接入后从这里进入。",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}

private final class AchievementArtworkView: UIView {

    init(content: AchievementCardDefinition, result: ChallengeResult) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.20, green: 0.30, blue: 0.31, alpha: 1)
        layer.cornerRadius = 22
        clipsToBounds = true

        if let asset = content.artworkAsset, let image = UIImage(named: asset) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            addSubview(imageView)
            imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else if let collectibleId = result.earnedArtifactIds.first,
                  let collectible = ContentStore.shared.collectible(id: collectibleId) {
            let specimen = SpecimenIllustrationView(collectible: collectible)
            addSubview(specimen)
            specimen.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalToSuperview().multipliedBy(0.66)
            }
        } else {
            let resultModel = AchievementResultModelView(
                symbolName: content.symbolName,
                taskId: result.completedTaskIds.first)
            addSubview(resultModel)
            resultModel.snp.makeConstraints { $0.edges.equalToSuperview() }
        }

        let shade = CAGradientLayer()
        shade.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.62).cgColor]
        shade.locations = [0.48, 1]
        layer.addSublayer(shade)

        let caption = UILabel()
        caption.text = "我的地质成果  ·  \(content.subtitle)"
        caption.font = GeoTheme.Typography.heading(size: 14)
        caption.textColor = .white
        caption.numberOfLines = 2
        addSubview(caption)
        caption.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(18)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.compactMap { $0 as? CAGradientLayer }.forEach { $0.frame = bounds }
    }
}

private final class AchievementResultModelView: UIView {
    init(symbolName: String, taskId: String?) {
        super.init(frame: .zero)

        let halo = UIView()
        halo.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        halo.layer.cornerRadius = 92
        let platform = UIView()
        platform.backgroundColor = UIColor(red: 0.43, green: 0.29, blue: 0.18, alpha: 1)
        platform.layer.cornerRadius = 18
        let symbol = UIImageView(image: UIImage(systemName: symbolName))
        symbol.tintColor = UIColor(red: 0.94, green: 0.77, blue: 0.36, alpha: 1)
        symbol.contentMode = .scaleAspectFit
        let modelTitle = UILabel()
        modelTitle.text = Self.modelTitle(for: taskId)
        modelTitle.font = GeoTheme.Typography.heading(size: 12)
        modelTitle.textColor = .white
        modelTitle.textAlignment = .center
        modelTitle.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        modelTitle.layer.cornerRadius = 10
        modelTitle.clipsToBounds = true

        [halo, platform, symbol, modelTitle].forEach(addSubview)
        halo.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-12)
            make.width.height.equalTo(184)
        }
        platform.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(halo.snp.bottom).offset(-18)
            make.width.equalTo(210)
            make.height.equalTo(36)
        }
        symbol.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(platform.snp.centerY).offset(4)
            make.width.height.equalTo(116)
        }
        modelTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(platform.snp.bottom).offset(12)
            make.height.equalTo(24)
            make.width.equalTo(150)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func modelTitle(for taskId: String?) -> String {
        switch taskId {
        case "plate_task_mountain": return "碰撞造山模型"
        case "plate_task_subduction": return "俯冲海沟模型"
        case "plate_task_rift", "rift_task_observe": return "拉张裂谷模型"
        case "rock_task_collect": return "岩石样本模型"
        case "mineral_task_identify": return "晶体样本模型"
        case "volcano_task_observe": return "火山监测模型"
        case "magma_task_observe": return "岩浆通道模型"
        default: return "地貌成果模型"
        }
    }
}
