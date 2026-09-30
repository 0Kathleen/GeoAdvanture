//
//  NotebookAtlasViewController.swift
//  GeoAdvanture
//
//  首页地质博物馆：中央桌台循环展示收藏，支持滑动切换；后续模型与 AR 共用此入口。
//

import UIKit
import SnapKit
import SceneKit
import ARKit

#if DEBUG
private struct MuseumModelDebugValues {
    var position: SCNVector3
    var rotationDegrees: SCNVector3
    var scale: Float

    static let initial = MuseumModelDebugValues(
        position: SCNVector3Zero,
        rotationDegrees: SCNVector3Zero,
        scale: 1)
}

private final class MuseumModelDebugPanel: UIView {
    var onModelChanged: ((Int) -> Void)?
    var onValuesChanged: ((MuseumModelDebugValues) -> Void)?
    var onReset: (() -> Void)?
    var onCopy: (() -> Void)?

    private enum Field: Int, CaseIterable {
        case rotationX, rotationY, rotationZ, positionX, positionY, scale

        var title: String {
            switch self {
            case .rotationX: return "角度 X"
            case .rotationY: return "角度 Y"
            case .rotationZ: return "角度 Z"
            case .positionX: return "位置 X"
            case .positionY: return "位置 Y"
            case .scale: return "模型大小"
            }
        }

        var range: ClosedRange<Float> {
            switch self {
            case .rotationX, .rotationY, .rotationZ: return -180...180
            case .positionX, .positionY: return -0.8...0.8
            case .scale: return 0.35...2.5
            }
        }
    }

    private let modelControl = UISegmentedControl(items: ["岩石", "裂谷", "火山"])
    private let statusLabel = UILabel()
    private let scrollView = UIScrollView()
    private var sliders: [Field: UISlider] = [:]
    private var valueLabels: [Field: UILabel] = [:]
    private var isSynchronizing = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func setSelectedModel(index: Int) {
        modelControl.selectedSegmentIndex = index
    }

    func setValues(_ values: MuseumModelDebugValues) {
        isSynchronizing = true
        set(values.rotationDegrees.x, for: .rotationX)
        set(values.rotationDegrees.y, for: .rotationY)
        set(values.rotationDegrees.z, for: .rotationZ)
        set(values.position.x, for: .positionX)
        set(values.position.y, for: .positionY)
        set(values.scale, for: .scale)
        isSynchronizing = false
    }

    func showCopiedFeedback() {
        statusLabel.text = "已保存、复制并打印参数"
    }

    private func configure() {
        backgroundColor = UIColor(white: 0.07, alpha: 0.92)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor

        let title = UILabel()
        title.text = "博物馆模型调试"
        title.textColor = .white
        title.font = .systemFont(ofSize: 16, weight: .bold)

        modelControl.selectedSegmentIndex = 0
        modelControl.addTarget(self, action: #selector(modelChanged), for: .valueChanged)

        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, modelControl])
        stack.axis = .vertical
        stack.spacing = 6
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        Field.allCases.forEach { stack.addArrangedSubview(makeRow(for: $0)) }

        let reset = makeButton(title: "恢复当前模型", action: #selector(resetTapped))
        let copy = makeButton(title: "复制参数", action: #selector(copyTapped))
        let buttons = UIStackView(arrangedSubviews: [reset, copy])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 8
        stack.addArrangedSubview(buttons)

        statusLabel.text = "滑动后实时生效并保存"
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.64)
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textAlignment = .center
        stack.addArrangedSubview(statusLabel)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -10),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24)
        ])
    }

    private func makeRow(for field: Field) -> UIView {
        let name = UILabel()
        name.text = field.title
        name.textColor = UIColor.white.withAlphaComponent(0.84)
        name.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        name.widthAnchor.constraint(equalToConstant: 62).isActive = true

        let slider = UISlider()
        slider.minimumValue = field.range.lowerBound
        slider.maximumValue = field.range.upperBound
        slider.tag = field.rawValue
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        sliders[field] = slider

        let value = UILabel()
        value.textColor = .white
        value.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        value.textAlignment = .right
        value.widthAnchor.constraint(equalToConstant: 50).isActive = true
        valueLabels[field] = value

        let row = UIStackView(arrangedSubviews: [name, slider, value])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 7
        row.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return row
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func set(_ value: Float, for field: Field) {
        sliders[field]?.value = value
        valueLabels[field]?.text = String(format: field == .scale ? "%.2f" : "%.1f", value)
    }

    private func value(_ field: Field) -> Float { sliders[field]?.value ?? 0 }

    private func currentValues() -> MuseumModelDebugValues {
        MuseumModelDebugValues(
            position: SCNVector3(value(.positionX), value(.positionY), 0),
            rotationDegrees: SCNVector3(value(.rotationX), value(.rotationY), value(.rotationZ)),
            scale: value(.scale))
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        guard let field = Field(rawValue: sender.tag) else { return }
        valueLabels[field]?.text = String(format: field == .scale ? "%.2f" : "%.1f", sender.value)
        statusLabel.text = "滑动后实时生效并保存"
        if !isSynchronizing { onValuesChanged?(currentValues()) }
    }

    @objc private func modelChanged() { onModelChanged?(modelControl.selectedSegmentIndex) }
    @objc private func resetTapped() { onReset?() }
    @objc private func copyTapped() { onCopy?() }
}
#endif

final class NotebookAtlasViewController: UIViewController {

    private struct MuseumModelPresentation {
        let position: SCNVector3
        let rotationDegrees: SCNVector3
        let scale: Float
    }

    private struct MuseumExhibit {
        enum UnlockRequirement {
            case collectible(String)
            case poi(String)
        }

        let id: String
        let name: String
        let category: String
        let imageName: String?
        let worldId: String
        let funFact: String
        let modelResourceName: String?
        let unlockRequirement: UnlockRequirement
    }

    private lazy var items: [MuseumExhibit] = {
        let collectibles = ContentStore.shared.collectibles.map { item in
            MuseumExhibit(
                id: item.id,
                name: item.name,
                category: item.category,
                imageName: item.image,
                worldId: item.worldId,
                funFact: item.funFact,
                modelResourceName: nil,
                unlockRequirement: .collectible(item.id))
        }
        let models = [
            MuseumExhibit(
                id: "museum_rock_model",
                name: "岩石与化石样本",
                category: "fossil",
                imageName: nil,
                worldId: "crust",
                funFact: "岩石的纹理和其中的化石，记录了地球环境变化的线索。",
                modelResourceName: "ammonite+fossil+3d+model_simplified",
                unlockRequirement: .poi("poi_crust_rock")),
            MuseumExhibit(
                id: "museum_rift_model",
                name: "裂谷地貌",
                category: "phenomenon",
                imageName: nil,
                worldId: "crust",
                funFact: "地壳向两侧拉张时，中间地块可能下陷，逐渐形成裂谷。",
                modelResourceName: "canyon+terrain+3d+model_simplified",
                unlockRequirement: .poi("poi_crust_crack")),
            MuseumExhibit(
                id: "museum_volcano_model",
                name: "火山地貌",
                category: "phenomenon",
                imageName: nil,
                worldId: "crust",
                funFact: "岩浆沿地壳薄弱处上升喷出，冷却后会不断改造火山周围的地形。",
                modelResourceName: "mountain+diorama+3d+model_simplified",
                unlockRequirement: .poi("poi_crust_volcano"))
        ]
        return collectibles + models
    }()
    private let modelPresentations: [String: MuseumModelPresentation] = [
        "canyon+terrain+3d+model_simplified": MuseumModelPresentation(
            position: SCNVector3(-0.19, 0.23, 0),
            rotationDegrees: SCNVector3(44.5, 37.4, 11.3),
            scale: 2.11),
        "ammonite+fossil+3d+model_simplified": MuseumModelPresentation(
            position: SCNVector3(0.08, 0.19, 0),
            rotationDegrees: SCNVector3(7.3, -3.2, 0),
            scale: 1.13),
        "mountain+diorama+3d+model_simplified": MuseumModelPresentation(
            position: SCNVector3(0, 0.28, 0),
            rotationDegrees: SCNVector3(26.1, -36.0, -15.5),
            scale: 1.96)
    ]
    private var currentIndex = 0
    private var carouselTimer: Timer?
    private var modelLoadToken = UUID()
    private weak var displayedModelOrientationNode: SCNNode?
    private var modelRotationAtPanStart = SCNVector3Zero
    private let modelLoadingQueue = DispatchQueue(label: "com.geoadvanture.museum-model-loading", qos: .userInitiated)

    private let progressLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let modelContainer = UIView()
    private let sceneView = SCNView()
    private let modelLoadingIndicator = UIActivityIndicatorView(style: .medium)
    private let artworkView = UIImageView()
    private let glyphLabel = UILabel()
    private let itemNameLabel = UILabel()
    private let sourceLabel = UILabel()
    private let lockLabel = UILabel()
    private let pageControl = UIPageControl()
    private let arButton = UIButton(type: .system)

    #if DEBUG
    private let debugToggleButton = UIButton(type: .system)
    private let debugPanel = MuseumModelDebugPanel()
    private var displayedModelResourceName: String?
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshMuseum(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshMuseum(animated: false)
        startCarousel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        carouselTimer?.invalidate()
    }

    deinit { carouselTimer?.invalidate() }

    @objc func closeTapped() {
        dismiss(animated: true)
    }

    private func setupUI() {
        view.backgroundColor = GeoTheme.Color.darkSurface

        let background = UIImageView(image: UIImage(named: "bg_geology_museum"))
        background.contentMode = .scaleAspectFill
        background.clipsToBounds = true
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        let atmosphere = UIView()
        atmosphere.backgroundColor = UIColor(red: 0.16, green: 0.12, blue: 0.09, alpha: 0.24)
        view.addSubview(atmosphere)
        atmosphere.snp.makeConstraints { $0.edges.equalToSuperview() }

        let header = UIView()
        header.backgroundColor = .clear
        header.layer.borderWidth = 0

        let title = UILabel()
        title.text = "我的地质博物馆"
        title.font = GeoTheme.Typography.brandTitle(size: 25)
        title.textColor = GeoTheme.Color.lightText
        GeoTheme.applyReadableShadow(to: title)

        progressLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .bold)
        progressLabel.textAlignment = .left
        progressLabel.textColor = GeoTheme.Color.lightText
        progressLabel.layer.shadowColor = UIColor.black.cgColor
        progressLabel.layer.shadowOpacity = 0.55
        progressLabel.layer.shadowRadius = 3
        progressView.progressTintColor = GeoTheme.Color.success
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.28)
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        let progressStack = UIStackView(arrangedSubviews: [progressLabel, progressView])
        progressStack.axis = .horizontal
        progressStack.alignment = .center
        progressStack.spacing = 10

        header.addSubview(title)
        header.addSubview(progressStack)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(18)
        }
        progressStack.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
        }
        progressView.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(7)
        }

        let exhibitArea = UIView()
        exhibitArea.backgroundColor = UIColor.clear

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = GeoTheme.Color.ink
        closeButton.backgroundColor = GeoTheme.Color.paper.withAlphaComponent(0.94)
        closeButton.layer.cornerRadius = 21
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        closeButton.accessibilityLabel = "关闭"
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let glow = UIView()
        glow.backgroundColor = UIColor(red: 0.95, green: 0.75, blue: 0.34, alpha: 0.16)
        glow.layer.cornerRadius = 112

        modelContainer.backgroundColor = UIColor.clear
        modelContainer.isUserInteractionEnabled = true
        modelContainer.layer.shadowColor = UIColor(red: 1, green: 0.78, blue: 0.33, alpha: 1).cgColor
        modelContainer.layer.shadowOpacity = 0.55
        modelContainer.layer.shadowRadius = 18
        modelContainer.layer.shadowOffset = .zero

        sceneView.backgroundColor = .clear
        sceneView.antialiasingMode = .multisampling2X
        sceneView.autoenablesDefaultLighting = true
        sceneView.isPlaying = true
        sceneView.isHidden = true
        sceneView.isUserInteractionEnabled = true

        modelLoadingIndicator.color = .white
        modelLoadingIndicator.hidesWhenStopped = true
        artworkView.contentMode = .scaleAspectFit
        glyphLabel.font = .systemFont(ofSize: 108)
        glyphLabel.textAlignment = .center
        modelContainer.addSubview(sceneView)
        modelContainer.addSubview(artworkView)
        modelContainer.addSubview(glyphLabel)
        modelContainer.addSubview(modelLoadingIndicator)
        sceneView.snp.makeConstraints { $0.edges.equalToSuperview() }
        artworkView.snp.makeConstraints { $0.edges.equalToSuperview().inset(7) }
        glyphLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        modelLoadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        itemNameLabel.font = GeoTheme.Typography.heading(size: 23)
        itemNameLabel.textColor = GeoTheme.Color.lightText
        itemNameLabel.textAlignment = .center
        itemNameLabel.layer.shadowColor = UIColor.black.cgColor
        itemNameLabel.layer.shadowOpacity = 0.7
        itemNameLabel.layer.shadowRadius = 4

        sourceLabel.font = GeoTheme.Typography.caption(size: 12)
        sourceLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        sourceLabel.textAlignment = .center

        lockLabel.font = GeoTheme.Typography.caption(size: 12)
        lockLabel.textColor = .white
        lockLabel.textAlignment = .center
        lockLabel.backgroundColor = UIColor.black.withAlphaComponent(0.40)
        lockLabel.layer.cornerRadius = 11
        lockLabel.clipsToBounds = true

        let previous = carouselButton(systemName: "chevron.left")
        previous.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        let next = carouselButton(systemName: "chevron.right")
        next.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        pageControl.numberOfPages = items.count
        pageControl.currentPageIndicatorTintColor = GeoTheme.Color.gold
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.35)
        pageControl.isUserInteractionEnabled = false

        var arConfiguration = GeoTheme.buttonConfiguration(
            title: "AR 观察",
            systemImage: "arkit",
            style: .paper)
        arConfiguration.baseForegroundColor = GeoTheme.Color.mauve
        arConfiguration.baseBackgroundColor = GeoTheme.Color.blushControl
        arConfiguration.background.strokeColor = GeoTheme.Color.mauve.withAlphaComponent(0.20)
        arConfiguration.background.strokeWidth = 1
        arButton.configuration = arConfiguration
        GeoTheme.applyFloatingShadow(to: arButton)
        arButton.addTarget(self, action: #selector(arTapped), for: .touchUpInside)

        view.addSubview(header)
        view.addSubview(closeButton)
        view.addSubview(exhibitArea)
        exhibitArea.addSubview(glow)
        exhibitArea.addSubview(modelContainer)
        exhibitArea.addSubview(itemNameLabel)
        exhibitArea.addSubview(sourceLabel)
        exhibitArea.addSubview(lockLabel)
        exhibitArea.addSubview(previous)
        exhibitArea.addSubview(next)
        exhibitArea.addSubview(pageControl)
        exhibitArea.addSubview(arButton)

        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(24)
            make.width.equalTo(398)
            make.height.equalTo(88)
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(header)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.width.height.equalTo(42)
        }
        exhibitArea.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        glow.snp.makeConstraints { make in
            make.center.equalTo(modelContainer)
            make.width.height.equalTo(224)
        }
        modelContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(58)
            make.width.height.equalTo(184)
        }
        itemNameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(modelContainer.snp.top).offset(-7)
        }
        sourceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(itemNameLabel.snp.top).offset(-3)
        }
        lockLabel.snp.makeConstraints { make in
            make.centerX.equalTo(modelContainer)
            make.bottom.equalTo(modelContainer).offset(-2)
            make.width.equalTo(112)
            make.height.equalTo(23)
        }
        previous.snp.makeConstraints { make in
            make.trailing.equalTo(modelContainer.snp.leading).offset(-36)
            make.centerY.equalTo(modelContainer)
            make.width.height.equalTo(46)
        }
        next.snp.makeConstraints { make in
            make.leading.equalTo(modelContainer.snp.trailing).offset(36)
            make.centerY.equalTo(modelContainer)
            make.width.height.equalTo(46)
        }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(modelContainer.snp.bottom).offset(4)
        }
        arButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(30)
            make.bottom.equalToSuperview().inset(26)
            make.width.equalTo(126)
            make.height.equalTo(42)
        }

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        swipeRight.direction = .right
        exhibitArea.addGestureRecognizer(swipeLeft)
        exhibitArea.addGestureRecognizer(swipeRight)
        modelContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(modelTapped)))
        let rotateModelPan = UIPanGestureRecognizer(target: self, action: #selector(modelPanned(_:)))
        rotateModelPan.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(rotateModelPan)

        #if DEBUG
        configureMuseumDebugPanel()
        #endif
    }

    private func carouselButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = GeoTheme.Color.ink
        button.backgroundColor = GeoTheme.Color.paper.withAlphaComponent(0.90)
        button.layer.cornerRadius = 23
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        return button
    }

    private func refreshMuseum(animated: Bool) {
        let collectedCount = items.filter(isUnlocked).count
        progressLabel.text = "已收集  \(collectedCount) / \(items.count)"
        progressView.setProgress(items.isEmpty ? 0 : Float(collectedCount) / Float(items.count), animated: animated)
        guard !items.isEmpty else {
            itemNameLabel.text = "等待第一件藏品"
            modelContainer.isHidden = true
            return
        }
        currentIndex = min(currentIndex, items.count - 1)
        pageControl.currentPage = currentIndex
        renderCurrentItem(animated: animated)
    }

    private func renderCurrentItem(animated: Bool) {
        guard items.indices.contains(currentIndex) else { return }
        let item = items[currentIndex]
        let collected = isUnlocked(item)
        let image = collected ? item.imageName.flatMap(UIImage.init(named:)) : nil
        #if DEBUG
        let showsModel = item.modelResourceName != nil
        #else
        let showsModel = collected && item.modelResourceName != nil
        #endif
        let canUseAR = collected && item.modelResourceName != nil

        let updates = {
            self.sceneView.isHidden = !showsModel
            self.artworkView.image = image
            self.artworkView.isHidden = image == nil
            self.glyphLabel.isHidden = image != nil || showsModel
            self.glyphLabel.text = collected ? Self.glyph(for: item.category) : "❔"
            self.glyphLabel.alpha = collected ? 1 : 0.52
            self.itemNameLabel.text = collected ? item.name : "尚未解锁"
            self.sourceLabel.text = Self.layerName(for: item.worldId)
            self.lockLabel.text = collected ? "轻点查看详情" : "继续探索后解锁"
            self.lockLabel.isHidden = false
            self.arButton.isEnabled = canUseAR
            self.arButton.alpha = canUseAR ? 1 : 0.48
            self.pageControl.currentPage = self.currentIndex
        }

        modelLoadToken = UUID()
        sceneView.scene = nil
        modelLoadingIndicator.stopAnimating()
        modelContainer.layer.removeAnimation(forKey: "museumFloat")
        updates()
        #if DEBUG
        syncMuseumDebugPanel(for: item.modelResourceName)
        #endif
        if let resourceName = item.modelResourceName, showsModel {
            loadModel(named: resourceName, token: modelLoadToken)
        }
        if animated {
            modelContainer.alpha = 0
            modelContainer.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            UIView.animate(withDuration: 0.24, delay: 0, options: .curveEaseOut) {
                self.modelContainer.alpha = 1
                self.modelContainer.transform = .identity
            } completion: { [weak self] _ in
                self?.startModelMotion()
            }
        } else {
            modelContainer.alpha = 1
            modelContainer.transform = .identity
            startModelMotion()
        }
    }

    private func startModelMotion() {
        modelContainer.layer.removeAnimation(forKey: "museumFloat")
        let float = CABasicAnimation(keyPath: "transform.translation.y")
        float.fromValue = -3
        float.toValue = 3
        float.duration = 1.8
        float.autoreverses = true
        float.repeatCount = .infinity
        float.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        modelContainer.layer.add(float, forKey: "museumFloat")
    }

    private func startCarousel() {
        carouselTimer?.invalidate()
        #if DEBUG
        guard debugPanel.isHidden else { return }
        #endif
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: true) { [weak self] _ in
            self?.move(by: 1, userInitiated: false)
        }
    }

    private func move(by offset: Int, userInitiated: Bool = true) {
        guard !items.isEmpty else { return }
        currentIndex = (currentIndex + offset + items.count) % items.count
        renderCurrentItem(animated: true)
        if userInitiated { startCarousel() }
    }

    @objc private func previousTapped() { move(by: -1) }
    @objc private func nextTapped() { move(by: 1) }

    @objc private func swiped(_ gesture: UISwipeGestureRecognizer) {
        move(by: gesture.direction == .left ? 1 : -1)
    }

    @objc private func modelTapped() {
        guard items.indices.contains(currentIndex) else { return }
        let item = items[currentIndex]
        guard isUnlocked(item) else { return }
        let alert = UIAlertController(title: item.name, message: item.funFact, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "收好啦", style: .default))
        present(alert, animated: true)
    }

    @objc private func modelPanned(_ recognizer: UIPanGestureRecognizer) {
        guard let orientationNode = displayedModelOrientationNode else { return }
        switch recognizer.state {
        case .began:
            modelRotationAtPanStart = orientationNode.eulerAngles
        case .changed:
            let translation = recognizer.translation(in: sceneView)
            orientationNode.eulerAngles = SCNVector3(
                modelRotationAtPanStart.x + Float(translation.y) * 0.008,
                modelRotationAtPanStart.y + Float(translation.x) * 0.008,
                modelRotationAtPanStart.z)
        case .ended, .cancelled:
            #if DEBUG
            saveCurrentMuseumDebugValues()
            #endif
        default:
            break
        }
    }

    @objc private func arTapped() {
        guard items.indices.contains(currentIndex) else { return }
        let item = items[currentIndex]
        guard isUnlocked(item), let resourceName = item.modelResourceName else { return }
        guard ARWorldTrackingConfiguration.isSupported else {
            let alert = UIAlertController(
                title: "当前设备不支持 AR",
                message: "仍可在博物馆展台上旋转观察这件展品。",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            present(alert, animated: true)
            return
        }
        let arViewController = MuseumARViewController(
            modelResourceName: resourceName,
            displayName: item.name)
        arViewController.modalPresentationStyle = .fullScreen
        present(arViewController, animated: true)
    }

    private func isUnlocked(_ item: MuseumExhibit) -> Bool {
        switch item.unlockRequirement {
        case .collectible(let id):
            return GameProgressManager.shared.isCollected(id: id)
        case .poi(let id):
            return GameProgressManager.shared.isPOIDiscovered(id: id)
        }
    }

    private func loadModel(named resourceName: String, token: UUID) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "usdz") else {
            showModelFallback(for: token)
            return
        }
        modelLoadingIndicator.startAnimating()
        modelLoadingQueue.async { [weak self] in
            let loadedScene = try? SCNScene(url: url, options: nil)
            DispatchQueue.main.async {
                guard let self, self.modelLoadToken == token else { return }
                self.modelLoadingIndicator.stopAnimating()
                guard let loadedScene else {
                    self.showModelFallback(for: token)
                    return
                }
                self.installModelScene(loadedScene, resourceName: resourceName)
            }
        }
    }

    private func installModelScene(_ loadedScene: SCNScene, resourceName: String) {
        let scene = SCNScene()
        let orientationNode = SCNNode()
        let displayRoot = SCNNode()
        loadedScene.rootNode.childNodes.forEach { displayRoot.addChildNode($0.clone()) }
        removeImportedCamerasAndLights(from: displayRoot)
        normalize(displayRoot)
        displayRoot.runAction(
            .repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 14)),
            forKey: "museumSpin")
        orientationNode.addChildNode(displayRoot)
        scene.rootNode.addChildNode(orientationNode)
        displayedModelOrientationNode = orientationNode
        applyMuseumPresentation(
            modelPresentations[resourceName]
                ?? MuseumModelPresentation(
                    position: SCNVector3Zero,
                    rotationDegrees: SCNVector3Zero,
                    scale: 1),
            to: orientationNode)
        #if DEBUG
        displayedModelResourceName = resourceName
        applyMuseumDebugValues(debugValues(for: resourceName))
        displayRoot.isPaused = !debugPanel.isHidden
        #endif

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.55
        camera.zNear = 0.01
        camera.zFar = 100
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 4)
        scene.rootNode.addChildNode(cameraNode)

        sceneView.scene = scene
        sceneView.pointOfView = cameraNode
        sceneView.isHidden = false
    }

    private func applyMuseumPresentation(_ presentation: MuseumModelPresentation, to node: SCNNode) {
        node.position = presentation.position
        node.eulerAngles = SCNVector3(
            presentation.rotationDegrees.x * .pi / 180,
            presentation.rotationDegrees.y * .pi / 180,
            presentation.rotationDegrees.z * .pi / 180)
        node.scale = SCNVector3(presentation.scale, presentation.scale, presentation.scale)
    }

    private func normalize(_ node: SCNNode) {
        let bounds = node.boundingBox
        let center = SCNVector3(
            (bounds.min.x + bounds.max.x) / 2,
            (bounds.min.y + bounds.max.y) / 2,
            (bounds.min.z + bounds.max.z) / 2)
        let extent = max(
            max(bounds.max.x - bounds.min.x, bounds.max.y - bounds.min.y),
            bounds.max.z - bounds.min.z)
        guard extent.isFinite, extent > 0 else { return }
        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        let scale = 1.72 / extent
        node.scale = SCNVector3(scale, scale, scale)
    }

    private func removeImportedCamerasAndLights(from node: SCNNode) {
        node.camera = nil
        node.light = nil
        node.childNodes.forEach(removeImportedCamerasAndLights)
    }

    private func showModelFallback(for token: UUID) {
        guard modelLoadToken == token else { return }
        modelLoadingIndicator.stopAnimating()
        sceneView.isHidden = true
        glyphLabel.text = "🪨"
        glyphLabel.isHidden = false
    }

    #if DEBUG
    private var modelExhibitIndices: [Int] {
        items.indices.filter { items[$0].modelResourceName != nil }
    }

    private func configureMuseumDebugPanel() {
        debugToggleButton.setTitle("模型调试", for: .normal)
        debugToggleButton.setTitleColor(.white, for: .normal)
        debugToggleButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        debugToggleButton.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        debugToggleButton.layer.cornerRadius = 18
        debugToggleButton.addTarget(self, action: #selector(toggleMuseumDebugPanel), for: .touchUpInside)

        debugPanel.isHidden = true
        debugPanel.onModelChanged = { [weak self] modelIndex in
            guard let self else { return }
            let indices = self.modelExhibitIndices
            guard indices.indices.contains(modelIndex) else { return }
            self.currentIndex = indices[modelIndex]
            self.renderCurrentItem(animated: false)
        }
        debugPanel.onValuesChanged = { [weak self] values in
            guard let self, let resourceName = self.displayedModelResourceName else { return }
            self.storeDebugValues(values, for: resourceName)
            self.applyMuseumDebugValues(values)
        }
        debugPanel.onReset = { [weak self] in
            guard let self, let resourceName = self.displayedModelResourceName else { return }
            UserDefaults.standard.removeObject(forKey: self.debugDefaultsKey(for: resourceName))
            let values = self.defaultDebugValues(for: resourceName)
            self.debugPanel.setValues(values)
            self.applyMuseumDebugValues(values)
        }
        debugPanel.onCopy = { [weak self] in self?.copyMuseumDebugValues() }

        view.addSubview(debugToggleButton)
        view.addSubview(debugPanel)
        debugToggleButton.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(22)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.equalTo(104)
            make.height.equalTo(36)
        }
        debugPanel.snp.makeConstraints { make in
            make.leading.equalTo(debugToggleButton)
            make.bottom.equalTo(debugToggleButton.snp.top).offset(-8)
            make.width.equalTo(320)
            make.height.equalTo(286)
        }
    }

    @objc private func toggleMuseumDebugPanel() {
        debugPanel.isHidden.toggle()
        let isVisible = !debugPanel.isHidden
        debugToggleButton.setTitle(isVisible ? "隐藏调试" : "模型调试", for: .normal)
        displayedModelOrientationNode?.childNodes.first?.isPaused = isVisible
        if isVisible {
            carouselTimer?.invalidate()
            if items.indices.contains(currentIndex), items[currentIndex].modelResourceName == nil,
               let firstModelIndex = modelExhibitIndices.first {
                currentIndex = firstModelIndex
                renderCurrentItem(animated: false)
            } else {
                syncMuseumDebugPanel(for: items.indices.contains(currentIndex)
                    ? items[currentIndex].modelResourceName : nil)
            }
        } else {
            startCarousel()
        }
    }

    private func syncMuseumDebugPanel(for resourceName: String?) {
        guard let resourceName else {
            displayedModelResourceName = nil
            return
        }
        displayedModelResourceName = resourceName
        let resources = modelExhibitIndices.compactMap { items[$0].modelResourceName }
        if let index = resources.firstIndex(of: resourceName) {
            debugPanel.setSelectedModel(index: index)
        }
        debugPanel.setValues(debugValues(for: resourceName))
    }

    private func debugDefaultsKey(for resourceName: String) -> String {
        "museum.preview.\(resourceName)"
    }

    private func debugValues(for resourceName: String) -> MuseumModelDebugValues {
        guard let numbers = UserDefaults.standard.array(forKey: debugDefaultsKey(for: resourceName)) as? [NSNumber],
              numbers.count == 6 else { return defaultDebugValues(for: resourceName) }
        return MuseumModelDebugValues(
            position: SCNVector3(numbers[3].floatValue, numbers[4].floatValue, 0),
            rotationDegrees: SCNVector3(
                numbers[0].floatValue,
                numbers[1].floatValue,
                numbers[2].floatValue),
            scale: numbers[5].floatValue)
    }

    private func defaultDebugValues(for resourceName: String) -> MuseumModelDebugValues {
        guard let presentation = modelPresentations[resourceName] else { return .initial }
        return MuseumModelDebugValues(
            position: presentation.position,
            rotationDegrees: presentation.rotationDegrees,
            scale: presentation.scale)
    }

    private func storeDebugValues(_ values: MuseumModelDebugValues, for resourceName: String) {
        UserDefaults.standard.set([
            Double(values.rotationDegrees.x),
            Double(values.rotationDegrees.y),
            Double(values.rotationDegrees.z),
            Double(values.position.x),
            Double(values.position.y),
            Double(values.scale)
        ], forKey: debugDefaultsKey(for: resourceName))
    }

    private func applyMuseumDebugValues(_ values: MuseumModelDebugValues) {
        guard let node = displayedModelOrientationNode else { return }
        node.position = values.position
        node.eulerAngles = SCNVector3(
            values.rotationDegrees.x * .pi / 180,
            values.rotationDegrees.y * .pi / 180,
            values.rotationDegrees.z * .pi / 180)
        node.scale = SCNVector3(values.scale, values.scale, values.scale)
    }

    private func saveCurrentMuseumDebugValues() {
        guard let node = displayedModelOrientationNode,
              let resourceName = displayedModelResourceName else { return }
        let values = MuseumModelDebugValues(
            position: node.position,
            rotationDegrees: SCNVector3(
                node.eulerAngles.x * 180 / .pi,
                node.eulerAngles.y * 180 / .pi,
                node.eulerAngles.z * 180 / .pi),
            scale: node.scale.x)
        storeDebugValues(values, for: resourceName)
        debugPanel.setValues(values)
    }

    private func copyMuseumDebugValues() {
        guard let resourceName = displayedModelResourceName else { return }
        let values = debugValues(for: resourceName)
        let output = String(
            format: "%@ | rotation(%.1f, %.1f, %.1f) position(%.2f, %.2f) scale %.2f",
            resourceName,
            values.rotationDegrees.x,
            values.rotationDegrees.y,
            values.rotationDegrees.z,
            values.position.x,
            values.position.y,
            values.scale)
        UIPasteboard.general.string = output
        print("🏛️ \(output)")
        debugPanel.showCopiedFeedback()
    }
    #endif

    private static func glyph(for category: String) -> String {
        switch category {
        case "rock": return "🪨"
        case "mineral": return "💎"
        case "fossil": return "🦴"
        default: return "🌋"
        }
    }

    private static func layerName(for worldId: String) -> String {
        switch worldId {
        case "crust": return "地壳展区"
        case "mantle": return "地幔展区"
        case "outer_core", "inner_core": return "地核展区"
        default: return "地球收藏"
        }
    }
}

extension NotebookAtlasViewController: NotebookPageContent {
    func refreshContent() {
        guard isViewLoaded else { return }
        refreshMuseum(animated: true)
    }
}

private final class MuseumARStatusLabel: UILabel {
    private let textInsets = UIEdgeInsets(top: 9, left: 18, bottom: 9, right: 18)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetBounds = bounds.inset(by: textInsets)
        let rect = super.textRect(forBounds: insetBounds, limitedToNumberOfLines: numberOfLines)
        return rect.inset(by: UIEdgeInsets(
            top: -textInsets.top,
            left: -textInsets.left,
            bottom: -textInsets.bottom,
            right: -textInsets.right))
    }
}

private final class MuseumARViewController: UIViewController {
    private let modelResourceName: String
    private let displayName: String
    private let sceneView = ARSCNView(frame: .zero)
    private let statusLabel = MuseumARStatusLabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let modelLoadingQueue = DispatchQueue(label: "com.geoadvanture.museum-ar-model", qos: .userInitiated)

    private var modelTemplate: SCNNode?
    private var placedModel: SCNNode?
    private var rotationAtPanStart = SCNVector3Zero
    private var scaleAtPinchStart = SCNVector3(1, 1, 1)

    init(modelResourceName: String, displayName: String) {
        self.modelResourceName = modelResourceName
        self.displayName = displayName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureGestures()
        loadModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    private func configureUI() {
        view.backgroundColor = .black
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true
        sceneView.antialiasingMode = .multisampling2X
        view.addSubview(sceneView)
        sceneView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let closeButton = capsuleButton(title: "关闭", systemName: "xmark")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        let resetButton = capsuleButton(title: "重新放置", systemName: "arrow.counterclockwise")
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        statusLabel.text = "正在准备 \(displayName)…"
        statusLabel.font = GeoTheme.Typography.control(size: 15)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.46)
        statusLabel.layer.cornerRadius = 18
        statusLabel.clipsToBounds = true

        loadingIndicator.color = .white
        loadingIndicator.startAnimating()

        view.addSubview(closeButton)
        view.addSubview(resetButton)
        view.addSubview(statusLabel)
        view.addSubview(loadingIndicator)

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.width.equalTo(92)
            make.height.equalTo(42)
        }
        resetButton.snp.makeConstraints { make in
            make.top.equalTo(closeButton)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.equalTo(126)
            make.height.equalTo(42)
        }
        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(22)
            make.width.lessThanOrEqualTo(430)
            make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(28)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(28)
            make.height.greaterThanOrEqualTo(44)
        }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        let coaching = ARCoachingOverlayView()
        coaching.session = sceneView.session
        coaching.goal = .horizontalPlane
        coaching.activatesAutomatically = true
        view.insertSubview(coaching, aboveSubview: sceneView)
        coaching.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func capsuleButton(title: String, systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.configuration = GeoTheme.buttonConfiguration(
            title: title,
            systemImage: systemName,
            style: .overlay)
        return button
    }

    private func configureGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(sceneTapped(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(modelPanned(_:)))
        pan.maximumNumberOfTouches = 1
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(modelPinched(_:)))
        sceneView.addGestureRecognizer(tap)
        sceneView.addGestureRecognizer(pan)
        sceneView.addGestureRecognizer(pinch)
    }

    private func loadModel() {
        guard let url = Bundle.main.url(forResource: modelResourceName, withExtension: "usdz") else {
            showLoadFailure()
            return
        }
        modelLoadingQueue.async { [weak self] in
            guard let self, let loadedScene = try? SCNScene(url: url, options: nil) else {
                DispatchQueue.main.async { [weak self] in self?.showLoadFailure() }
                return
            }
            let root = SCNNode()
            loadedScene.rootNode.childNodes.forEach { root.addChildNode($0.clone()) }
            self.removeImportedCamerasAndLights(from: root)
            self.normalizeForAR(root)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.modelTemplate = root
                self.loadingIndicator.stopAnimating()
                self.statusLabel.text = "缓慢移动 iPad 寻找桌面，轻点放置·拖动旋转·双指缩放"
            }
        }
    }

    private func normalizeForAR(_ node: SCNNode) {
        let bounds = node.boundingBox
        let centerX = (bounds.min.x + bounds.max.x) / 2
        let centerZ = (bounds.min.z + bounds.max.z) / 2
        let extent = max(
            max(bounds.max.x - bounds.min.x, bounds.max.y - bounds.min.y),
            bounds.max.z - bounds.min.z)
        guard extent.isFinite, extent > 0 else { return }
        node.pivot = SCNMatrix4MakeTranslation(centerX, bounds.min.y, centerZ)
        let scale = 0.28 / extent
        node.scale = SCNVector3(scale, scale, scale)
    }

    private func removeImportedCamerasAndLights(from node: SCNNode) {
        node.camera = nil
        node.light = nil
        node.childNodes.forEach(removeImportedCamerasAndLights)
    }

    private func showLoadFailure() {
        loadingIndicator.stopAnimating()
        statusLabel.text = "模型加载失败，请返回博物馆重试"
    }

    @objc private func sceneTapped(_ recognizer: UITapGestureRecognizer) {
        guard let template = modelTemplate else { return }
        let point = recognizer.location(in: sceneView)
        let query = sceneView.raycastQuery(
            from: point,
            allowing: .estimatedPlane,
            alignment: .horizontal)
        guard let query, let result = sceneView.session.raycast(query).first else {
            statusLabel.text = "还没找到桌面，请继续缓慢移动 iPad"
            return
        }
        placedModel?.removeFromParentNode()
        let placementNode = SCNNode()
        placementNode.simdTransform = result.worldTransform
        placementNode.addChildNode(template.clone())
        sceneView.scene.rootNode.addChildNode(placementNode)
        placedModel = placementNode
        statusLabel.text = "已放置 \(displayName)·拖动旋转·双指缩放·轻点更换位置"
    }

    @objc private func modelPanned(_ recognizer: UIPanGestureRecognizer) {
        guard let model = placedModel else { return }
        switch recognizer.state {
        case .began:
            rotationAtPanStart = model.eulerAngles
        case .changed:
            let translation = recognizer.translation(in: sceneView)
            let x = rotationAtPanStart.x + Float(translation.y) * 0.006
            model.eulerAngles = SCNVector3(
                min(.pi / 2, max(-.pi / 2, x)),
                rotationAtPanStart.y + Float(translation.x) * 0.008,
                rotationAtPanStart.z)
        default:
            break
        }
    }

    @objc private func modelPinched(_ recognizer: UIPinchGestureRecognizer) {
        guard let model = placedModel else { return }
        if recognizer.state == .began { scaleAtPinchStart = model.scale }
        let factor = Float(min(2.5, max(0.45, recognizer.scale)))
        model.scale = SCNVector3(
            scaleAtPinchStart.x * factor,
            scaleAtPinchStart.y * factor,
            scaleAtPinchStart.z * factor)
    }

    @objc private func resetTapped() {
        placedModel?.removeFromParentNode()
        placedModel = nil
        statusLabel.text = "轻点桌面，重新放置 \(displayName)"
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
