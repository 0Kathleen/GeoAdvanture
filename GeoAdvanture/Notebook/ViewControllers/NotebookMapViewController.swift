//
//  NotebookMapViewController.swift
//  GeoAdvanture
//
//  地壳「闯关地图」：只负责 6 个热点的布局、三态显示与二级页路由。
//  游戏启动、观察过程和完成回写统一由 ChallengeHubViewController 负责。
//  仅地壳配置了地图；地幔/地核显示「建设中」占位（见 viewModel.hasLevelMap）。
//

import UIKit
import SnapKit

final class NotebookMapViewController: UIViewController {

    private let viewModel: NotebookViewModel
    weak var notebookNavigationDelegate: NotebookPageNavigationDelegate?

    // MARK: - UI
    private let mapImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "curstMap"))
        v.contentMode = .scaleAspectFit
        v.isUserInteractionEnabled = true
        return v
    }()

    /// 每个热点：图片按钮 + 关联 POI id + 相对地图的位置。
    private struct HotspotDef {
        let imageName: String
        let poiId: String
        let leading: CGFloat
        let top: CGFloat
    }

    private let hotspotDefs: [HotspotDef] = [
        .init(imageName: "map_rock",     poiId: "poi_crust_rock",    leading: NotebookLayout.Map.rockLeading,     top: NotebookLayout.Map.rockTop),
        .init(imageName: "map_movement", poiId: "poi_crust_plate",   leading: NotebookLayout.Map.movementLeading, top: NotebookLayout.Map.movementTop),
        .init(imageName: "map_crack",    poiId: "poi_crust_crack",   leading: NotebookLayout.Map.crackLeading,    top: NotebookLayout.Map.crackTop),
        .init(imageName: "map_diamond",  poiId: "poi_crust_diamond", leading: NotebookLayout.Map.diamondLeading,  top: NotebookLayout.Map.diamondTop),
        .init(imageName: "map_valcano",  poiId: "poi_crust_volcano", leading: NotebookLayout.Map.volcanoLeading,  top: NotebookLayout.Map.volcanoTop),
        .init(imageName: "map_lava",     poiId: "poi_crust_lava",    leading: NotebookLayout.Map.lavaLeading,     top: NotebookLayout.Map.lavaTop)
    ]

    /// poiId → 未探索 / 进行中 / 已完成状态标记。
    private var statusBadges: [String: NotebookMapStatusBadgeView] = [:]
    private var hotspotButtons: [String: UIButton] = [:]
    private var focusedPOIId: String?

    private let gm = GameProgressManager.shared

    // MARK: - Lifecycle
    init(viewModel: NotebookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        if viewModel.hasLevelMap {
            setupMap()
        } else {
            setupPlaceholder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshContent()
    }

    // MARK: - 本期范围说明（非地壳层）
    private func setupPlaceholder() {
        let placeholder = NotebookPlaceholderView(
            emoji: "🗺️",
            title: "\(viewModel.layerName)·知识预览",
            message: "本期完整闯关开放于地壳。\n你可以先在「认识」中了解这个圈层。")
        view.addSubview(placeholder)
        placeholder.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    // MARK: - 地图与热点
    private func setupMap() {
        view.addSubview(mapImageView)
        mapImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        for def in hotspotDefs {
            let btn = UIButton(type: .custom)
            btn.setImage(UIImage(named: def.imageName), for: .normal)
            btn.imageView?.contentMode = .scaleAspectFit
            btn.accessibilityIdentifier = def.poiId
            btn.addTarget(self, action: #selector(hotspotTapped(_:)), for: .touchUpInside)
            mapImageView.addSubview(btn)
            hotspotButtons[def.poiId] = btn
            btn.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(def.leading)
                make.top.equalToSuperview().offset(def.top)
            }

            let badge = Self.makeStatusBadge()
            btn.addSubview(badge)
            badge.snp.makeConstraints { make in
                // 与热点名称拉开距离，避免“未探索”压住图片内的关卡名。
                make.bottom.equalTo(btn.snp.top).offset(-5)
                make.centerX.equalToSuperview()
                make.height.equalTo(23)
                make.width.greaterThanOrEqualTo(64)
            }
            statusBadges[def.poiId] = badge
        }
        refreshHotspotStates()
    }

    private static func makeStatusBadge() -> NotebookMapStatusBadgeView {
        NotebookMapStatusBadgeView()
    }

    /// 刷新热点三态。进入二级页即为“进行中”，真正完成任务后才显示“已完成”。
    private func refreshHotspotStates() {
        for def in hotspotDefs {
            guard let poi = ContentStore.shared.poi(id: def.poiId),
                  let hub = ContentStore.shared.challengeHub(poiId: def.poiId),
                  let badge = statusBadges[def.poiId] else { continue }
            if isDone(poi) {
                badge.configure(text: "已完成", color: .systemGreen, symbol: "checkmark")
            } else if gm.isChallengeHubVisited(id: hub.id) {
                badge.configure(text: "进行中", color: .systemOrange, symbol: "circle.fill")
            } else {
                badge.configure(text: "未探索", color: .white, symbol: "circle")
            }
            hotspotButtons[def.poiId]?.accessibilityValue = badge.accessibilityValue
        }
    }

    // MARK: - 交互
    @objc private func hotspotTapped(_ sender: UIButton) {
        guard let poiId = sender.accessibilityIdentifier else { return }
        openChallengeHub(poiId: poiId)
    }

    private func openChallengeHub(poiId: String) {
        guard let controller = ChallengeHubRouter.makeViewController(
            poiId: poiId,
            delegate: self) else {
            let alert = UIAlertController(
                title: "暂时无法进入",
                message: "「\(poiId)」的二级探索页配置缺失，请检查 NotebookLearning.json 是否已加入工程。",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default))
            present(alert, animated: true)
            return
        }
        present(controller, animated: true)
    }

    private func isCollected(_ poi: POI) -> Bool {
        guard let cid = poi.collectibleId else { return false }
        return gm.isCollected(id: cid)
    }

    private func isDone(_ poi: POI) -> Bool {
        if let hub = ContentStore.shared.challengeHub(poiId: poi.id), !hub.taskIds.isEmpty {
            return hub.taskIds.allSatisfy { gm.isChallengeTaskCompleted(id: $0) }
        }
        if poi.interactionType == .collect { return isCollected(poi) }
        return gm.isPOIDiscovered(id: poi.id)
    }
}

private final class NotebookMapStatusBadgeView: UIView {

    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let dot = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 11.5
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.68).cgColor
        clipsToBounds = true

        addSubview(effectView)
        effectView.snp.makeConstraints { $0.edges.equalToSuperview() }
        label.font = GeoTheme.Typography.caption(size: 9)
        label.textColor = .white
        let row = UIStackView(arrangedSubviews: [dot, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        effectView.contentView.addSubview(row)
        dot.contentMode = .scaleAspectFit
        dot.snp.makeConstraints { $0.width.height.equalTo(10) }
        row.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(7)
            make.trailing.lessThanOrEqualToSuperview().inset(7)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(text: String, color: UIColor, symbol: String) {
        label.text = text
        dot.image = UIImage(systemName: symbol)
        dot.tintColor = color
        accessibilityValue = text
    }
}

// MARK: - NotebookPageContent
extension NotebookMapViewController: NotebookPageContent {
    func refreshContent() {
        refreshHotspotStates()
    }

    @discardableResult
    func focus(on target: NotebookFocusTarget, animated: Bool) -> Bool {
        guard case let .poi(id) = target,
              let button = hotspotButtons[id] else { return false }

        focusedPOIId = id
        hotspotButtons.forEach { poiId, hotspot in
            if poiId == id {
                hotspot.accessibilityHint = "当前定位"
            } else {
                hotspot.accessibilityHint = nil
            }
        }
        view.layoutIfNeeded()
        guard animated else { return true }

        button.layer.removeAnimation(forKey: "notebook.focus")
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.16
        pulse.duration = 0.32
        pulse.autoreverses = true
        pulse.repeatCount = 2
        button.layer.add(pulse, forKey: "notebook.focus")
        return true
    }
}

// MARK: - 二级页进度回流
extension NotebookMapViewController: ChallengeHubViewControllerDelegate {
    func challengeHubViewControllerDidUpdateProgress(poiId: String) {
        refreshHotspotStates()
    }
}
