//
//  HomeEarthLayerStageView.swift
//  GeoAdvanture
//
//  首页三层地球模型舞台：组合、展开、选择、移动、旋转与归位。
//

import UIKit
import SceneKit

final class HomeEarthLayerStageView: UIView, UIGestureRecognizerDelegate {
    var onOpenLayer: ((Int) -> Void)?
    var onExpandedChanged: ((Bool) -> Void)?

    private enum StageState {
        case assembled
        case expanded
    }

    private struct ModelNodes {
        let root: SCNNode
        let motion: SCNNode
    }

    private let sceneView = SCNView()
    private let scene = SCNScene()
    private let cameraNode = SCNNode()
    private let haloView = UIView()
    private let hintLabel = UILabel()
    private let selectedLayerLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var models: [HomeLayer: ModelNodes] = [:]
    private var manualOffsets: [HomeLayer: CGPoint] = [:]
    private var state: StageState = .assembled
    private var selectedLayer: HomeLayer?
    private var movingLayer: HomeLayer?
    private var rotatingLayer: HomeLayer?
    private var remainingLoads = HomeLayer.allCases.count
    private let modelLoadingQueue = DispatchQueue(label: "my.GeoAdvanture.home-model-loading", qos: .userInitiated)
    /// 超过该体积的 AIGC 模型通常包含百万级网格或 4K 纹理，真机同时解码会触发 Jetsam。
    private let safeRuntimeModelSize = 20 * 1_024 * 1_024

    #if DEBUG
    private let debugToggleButton = UIButton(type: .system)
    private let debugPanel = HomeModelDebugPanel()
    private var debugTargetLayer: HomeLayer = .crust
    #endif

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureScene()
        configureGestures()
        loadModels()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        configureScene()
        configureGestures()
        loadModels()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sceneView.frame = bounds
        loadingIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
        let hintWidth = min(540, max(280, bounds.width - 180))
        hintLabel.frame = CGRect(x: bounds.midX - hintWidth / 2, y: 20, width: hintWidth, height: 40)

        #if DEBUG
        debugToggleButton.frame = CGRect(x: 12, y: 10, width: 92, height: 36)
        let debugPanelY: CGFloat = 54
        let availableHeight = max(180, bounds.height - debugPanelY - 12)
        debugPanel.frame = CGRect(
            x: 12,
            y: debugPanelY,
            width: min(330, bounds.width - 24),
            height: min(370, availableHeight))
        #endif
        updateHaloPosition()
    }

    func reset(animated: Bool = true) {
        state = .assembled
        selectedLayer = nil
        movingLayer = nil
        rotatingLayer = nil
        manualOffsets.removeAll()
        stopSelectionMotion()
        haloView.alpha = 0
        selectedLayerLabel.alpha = 0
        hintLabel.text = "轻点地球，展开三个圈层"
        updateCamera(for: .assembled, animated: animated)

        updateModelTransforms(animated: animated)
        onExpandedChanged?(false)
        #if DEBUG
        debugPanel.setStageExpanded(false)
        syncDebugPanel()
        #endif
    }

    private func configureView() {
        backgroundColor = .clear
        clipsToBounds = true

        haloView.isUserInteractionEnabled = false
        haloView.backgroundColor = GeoTheme.Color.mauve.withAlphaComponent(0.12)
        haloView.layer.cornerRadius = 105
        haloView.layer.borderWidth = 1.5
        haloView.layer.borderColor = GeoTheme.Color.blushControl.withAlphaComponent(0.68).cgColor
        haloView.layer.shadowRadius = 28
        haloView.layer.shadowOpacity = 0.9
        haloView.layer.shadowOffset = .zero
        haloView.alpha = 0
        addSubview(haloView)

        sceneView.backgroundColor = .clear
        sceneView.isOpaque = false
        sceneView.antialiasingMode = .multisampling2X
        sceneView.isPlaying = true
        sceneView.rendersContinuously = true
        sceneView.allowsCameraControl = false
        // 不再叠加自定义强光；使用 SceneKit 的中性默认照明呈现模型原始 PBR 细节。
        sceneView.autoenablesDefaultLighting = true
        sceneView.isAccessibilityElement = true
        sceneView.accessibilityLabel = "地球圈层互动模型"
        sceneView.accessibilityHint = "轻点展开圈层，展开后双击某一层进入知识本"
        addSubview(sceneView)

        selectedLayerLabel.font = GeoTheme.Typography.control(size: 14)
        selectedLayerLabel.textColor = .white
        selectedLayerLabel.textAlignment = .center
        selectedLayerLabel.layer.cornerRadius = 15
        selectedLayerLabel.clipsToBounds = true
        selectedLayerLabel.alpha = 0
        addSubview(selectedLayerLabel)

        hintLabel.text = "轻点地球，展开三个圈层"
        hintLabel.textAlignment = .center
        hintLabel.font = GeoTheme.Typography.heading(size: 19)
        hintLabel.textColor = GeoTheme.Color.lightText
        hintLabel.backgroundColor = .clear
        GeoTheme.applyReadableShadow(to: hintLabel)
        hintLabel.clipsToBounds = false
        addSubview(hintLabel)

        loadingIndicator.color = .white
        loadingIndicator.startAnimating()
        addSubview(loadingIndicator)

        #if DEBUG
        configureDebugPanel()
        #endif
    }

    private func configureScene() {
        sceneView.scene = scene
        scene.background.contents = UIColor.clear

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 2.60
        camera.zNear = 0.1
        camera.zFar = 100
        camera.wantsHDR = false
        camera.bloomIntensity = 0
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.12, 9)
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
    }

    private func configureGestures() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)

        let movePan = UIPanGestureRecognizer(target: self, action: #selector(modelPanned(_:)))
        movePan.minimumNumberOfTouches = 1
        movePan.maximumNumberOfTouches = 1

        let rotatePan = UIPanGestureRecognizer(target: self, action: #selector(modelRotated(_:)))
        rotatePan.minimumNumberOfTouches = 2
        rotatePan.maximumNumberOfTouches = 2

        [singleTap, doubleTap, movePan, rotatePan].forEach {
            $0.delegate = self
            sceneView.addGestureRecognizer($0)
        }
    }

    private func loadModels() {
        remainingLoads = HomeLayer.allCases.count
        for layer in HomeLayer.allCases {
            modelLoadingQueue.async { [weak self] in
                guard let self else { return }
                let loadedScene: SCNScene?
                if let url = Bundle.main.url(forResource: layer.resourceName, withExtension: "usdz"),
                   self.canLoadFullModel(at: url) {
                    loadedScene = autoreleasepool {
                        try? SCNScene(url: url, options: nil)
                    }
                } else {
                    loadedScene = nil
                }

                DispatchQueue.main.async { [weak self] in
                    self?.installModel(from: loadedScene, for: layer)
                }
            }
        }
    }

    private func canLoadFullModel(at url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = values?.fileSize ?? Int.max
        if fileSize > safeRuntimeModelSize {
            print("⚠️ 首页模型过大，启用轻量预览：\(url.lastPathComponent)（\(fileSize / 1_024 / 1_024)MB）")
            return false
        }
        return true
    }

    private func installModel(from loadedScene: SCNScene?, for layer: HomeLayer) {
        let root = SCNNode()
        root.name = "homeLayer_\(layer.rawValue)"

        let motion = SCNNode()
        motion.name = "homeLayerMotion_\(layer.rawValue)"
        root.addChildNode(motion)

        if let loadedScene {
            for child in loadedScene.rootNode.childNodes {
                motion.addChildNode(child.clone())
            }
            motion.enumerateChildNodes { node, _ in
                node.camera = nil
                node.light = nil
            }
            normalize(node: motion)
        } else {
            installFallbackGeometry(in: motion, for: layer)
        }

        scene.rootNode.addChildNode(root)
        models[layer] = ModelNodes(root: root, motion: motion)
        applyAssembledTransform(to: root, layer: layer)

        remainingLoads -= 1
        if remainingLoads == 0 {
            loadingIndicator.stopAnimating()
            loadingIndicator.removeFromSuperview()
            #if DEBUG
            syncDebugPanel()
            #endif
        }
    }

    private func normalize(node: SCNNode) {
        let (minimum, maximum) = node.boundingBox
        let center = SCNVector3(
            (minimum.x + maximum.x) / 2,
            (minimum.y + maximum.y) / 2,
            (minimum.z + maximum.z) / 2)
        let extent = max(
            maximum.x - minimum.x,
            max(maximum.y - minimum.y, maximum.z - minimum.z))
        guard extent.isFinite, extent > 0.0001 else { return }

        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        let scale = 1 / extent
        node.scale = SCNVector3(scale, scale, scale)
    }

    private func installFallbackGeometry(in node: SCNNode, for layer: HomeLayer) {
        let sphere = SCNSphere(radius: 0.5)
        sphere.segmentCount = 96
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = bundledImage(named: layer.lightweightBaseColorName, extension: "jpg")
            ?? layer.tintColor
        material.diffuse.mipFilter = .linear
        sphere.materials = [material]
        node.addChildNode(SCNNode(geometry: sphere))
    }

    private func bundledImage(named name: String, extension fileExtension: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    @objc private func singleTapped(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: sceneView)
        switch state {
        case .assembled:
            guard layer(at: point) != nil else { return }
            expand()
        case .expanded:
            guard let layer = layer(at: point) else { return }
            select(layer, animated: true)
        }
    }

    @objc private func doubleTapped(_ recognizer: UITapGestureRecognizer) {
        guard state == .expanded else {
            expand()
            return
        }
        guard let layer = layer(at: recognizer.location(in: sceneView)) else { return }
        select(layer, animated: true)
        onOpenLayer?(layer.rawValue)
    }

    @objc private func modelPanned(_ recognizer: UIPanGestureRecognizer) {
        guard state == .expanded else { return }
        let point = recognizer.location(in: sceneView)

        if recognizer.state == .began {
            movingLayer = layer(at: point)
            if let movingLayer { select(movingLayer, animated: true) }
        }
        guard let layer = movingLayer else { return }

        if recognizer.state == .changed {
            let translation = recognizer.translation(in: sceneView)
            var offset = manualOffsets[layer] ?? .zero
            offset.x = min(0.48, max(-0.48, offset.x + translation.x * 0.0045))
            offset.y = min(0.42, max(-0.42, offset.y - translation.y * 0.0045))
            manualOffsets[layer] = offset
            recognizer.setTranslation(.zero, in: sceneView)
            updateRootPosition(for: layer)
            updateHaloPosition()
        }

        if recognizer.state == .ended || recognizer.state == .cancelled {
            movingLayer = nil
        }
    }

    @objc private func modelRotated(_ recognizer: UIPanGestureRecognizer) {
        guard state == .expanded else { return }
        let point = recognizer.location(in: sceneView)

        if recognizer.state == .began {
            rotatingLayer = layer(at: point) ?? selectedLayer
            if let rotatingLayer { select(rotatingLayer, animated: true) }
        }
        guard let layer = rotatingLayer, let root = models[layer]?.root else { return }

        if recognizer.state == .changed {
            let translation = recognizer.translation(in: sceneView)
            root.eulerAngles.y += Float(translation.x * 0.008)
            root.eulerAngles.x = min(0.55, max(-0.55, root.eulerAngles.x + Float(translation.y * 0.006)))
            recognizer.setTranslation(.zero, in: sceneView)
        }

        if recognizer.state == .ended || recognizer.state == .cancelled {
            rotatingLayer = nil
        }
    }

    private func expand() {
        guard !models.isEmpty else { return }
        state = .expanded
        selectedLayer = nil
        selectedLayerLabel.alpha = 0
        hintLabel.text = "轻点选择 · 双击进入 · 单指移动 · 双指旋转"
        updateCamera(for: .expanded, animated: true)
        updateModelTransforms(animated: true)
        onExpandedChanged?(true)
    }

    private func select(_ layer: HomeLayer, animated: Bool) {
        guard state == .expanded else { return }
        selectedLayer = layer
        stopSelectionMotion()

        let changes = {
            for candidate in HomeLayer.allCases {
                guard let root = self.models[candidate]?.root else { continue }
                let base = candidate.expandedScale
                root.scale = SCNVector3(base, base, base)
                root.opacity = candidate == layer ? 1 : 0.42
            }
        }
        runTransaction(animated: animated, changes: changes)

        startSelectionMotion(for: layer)
        haloView.layer.shadowColor = layer.tintColor.cgColor
        haloView.backgroundColor = GeoTheme.Color.mauve.withAlphaComponent(0.18)
        selectedLayerLabel.text = layer.title
        selectedLayerLabel.backgroundColor = layer.tintColor.withAlphaComponent(0.88)
        updateHaloPosition()
        UIView.animate(withDuration: 0.25) {
            self.haloView.alpha = 1
            self.selectedLayerLabel.alpha = 1
        }
    }

    private func startSelectionMotion(for layer: HomeLayer) {
        guard let motion = models[layer]?.motion else { return }
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let rise = SCNAction.moveBy(x: 0, y: 0.07, z: 0, duration: 1.15)
        rise.timingMode = .easeInEaseOut
        let turn = SCNAction.rotateBy(x: 0, y: 0.14, z: 0, duration: 1.15)
        turn.timingMode = .easeInEaseOut
        let forward = SCNAction.group([rise, turn])
        motion.runAction(.repeatForever(.sequence([forward, forward.reversed()])), forKey: "selectedMotion")
    }

    private func stopSelectionMotion() {
        for nodes in models.values {
            nodes.motion.removeAction(forKey: "selectedMotion")
            nodes.motion.position = SCNVector3Zero
            nodes.motion.eulerAngles = SCNVector3Zero
        }
    }

    private func updateModelTransforms(animated: Bool) {
        let changes = {
            for layer in HomeLayer.allCases {
                guard let root = self.models[layer]?.root else { continue }
                root.opacity = 1
                self.applyDefaultRotation(to: root, layer: layer)
                if self.state == .assembled {
                    self.applyAssembledTransform(to: root, layer: layer)
                } else {
                    let scale = layer.expandedScale
                    root.scale = SCNVector3(scale, scale, scale)
                    self.updateRootPosition(for: layer)
                }
            }
        }
        runTransaction(animated: animated, changes: changes)
    }

    private func applyAssembledTransform(to root: SCNNode, layer: HomeLayer) {
        let scale = layer.assembledScale
        root.scale = SCNVector3(scale, scale, scale)
        root.position = SCNVector3(0, -0.04, Float(layer.rawValue) * -0.025)
        applyDefaultRotation(to: root, layer: layer)
    }

    private func applyDefaultRotation(to root: SCNNode, layer: HomeLayer) {
        let degrees = layer.defaultRotationDegrees
        let radians = Float(Double.pi / 180)
        root.eulerAngles = SCNVector3(
            degrees.x * radians,
            degrees.y * radians,
            degrees.z * radians)
    }

    private func updateRootPosition(for layer: HomeLayer) {
        guard let root = models[layer]?.root else { return }
        let offset = manualOffsets[layer] ?? .zero
        root.position = SCNVector3(layer.expandedX + Float(offset.x), Float(offset.y) + 0.12, 0)
    }

    private func runTransaction(animated: Bool, changes: () -> Void) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animated && !UIAccessibility.isReduceMotionEnabled ? 0.72 : 0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        changes()
        SCNTransaction.commit()
    }

    private func updateCamera(for state: StageState, animated: Bool) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animated && !UIAccessibility.isReduceMotionEnabled ? 0.72 : 0
        cameraNode.camera?.orthographicScale = state == .assembled ? 2.60 : 5.20
        SCNTransaction.commit()
    }

    private func layer(at point: CGPoint) -> HomeLayer? {
        let hits = sceneView.hitTest(point, options: [
            SCNHitTestOption.firstFoundOnly: true,
            SCNHitTestOption.ignoreHiddenNodes: true
        ])
        for hit in hits {
            var node: SCNNode? = hit.node
            while let current = node {
                if let name = current.name,
                   name.hasPrefix("homeLayer_"),
                   let rawValue = Int(name.dropFirst("homeLayer_".count)),
                   let layer = HomeLayer(rawValue: rawValue) {
                    return layer
                }
                node = current.parent
            }
        }
        return nil
    }

    private func updateHaloPosition() {
        guard let layer = selectedLayer, let root = models[layer]?.root else { return }
        let projected = sceneView.projectPoint(root.presentation.worldPosition)
        guard projected.z >= 0, projected.z <= 1 else { return }
        let point = sceneView.convert(
            CGPoint(x: CGFloat(projected.x), y: sceneView.bounds.height - CGFloat(projected.y)),
            to: self)
        haloView.bounds = CGRect(x: 0, y: 0, width: 230, height: 230)
        haloView.layer.cornerRadius = 115
        haloView.center = point
        selectedLayerLabel.bounds = CGRect(x: 0, y: 0, width: 82, height: 30)
        selectedLayerLabel.center = CGPoint(x: point.x, y: point.y + 126)
    }

    #if DEBUG
    private func configureDebugPanel() {
        debugToggleButton.setTitle("模型调试", for: .normal)
        debugToggleButton.setTitleColor(.white, for: .normal)
        debugToggleButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        debugToggleButton.backgroundColor = UIColor.black.withAlphaComponent(0.66)
        debugToggleButton.layer.cornerRadius = 18
        debugToggleButton.addTarget(self, action: #selector(toggleDebugPanel), for: .touchUpInside)
        addSubview(debugToggleButton)

        debugPanel.isHidden = true
        debugPanel.onLayerChanged = { [weak self] layer in
            self?.debugTargetLayer = layer
            self?.debugHighlight(layer)
            self?.syncDebugPanel()
        }
        debugPanel.onStageChanged = { [weak self] expanded in
            self?.debugSetStageExpanded(expanded)
        }
        debugPanel.onValuesChanged = { [weak self] values in
            self?.applyDebugValues(values)
        }
        debugPanel.onReset = { [weak self] in
            self?.resetDebugTarget()
        }
        debugPanel.onCopy = { [weak self] in
            self?.copyDebugValues()
        }
        addSubview(debugPanel)
    }

    @objc private func toggleDebugPanel() {
        let willShow = debugPanel.isHidden
        debugPanel.isHidden = !willShow
        debugToggleButton.setTitle(willShow ? "收起调试" : "模型调试", for: .normal)
        sceneView.gestureRecognizers?.forEach { $0.isEnabled = !willShow }
        if willShow {
            debugHighlight(debugTargetLayer)
            syncDebugPanel()
        } else {
            models.values.forEach { $0.root.opacity = 1 }
            haloView.alpha = 0
        }
    }

    private func debugSetStageExpanded(_ expanded: Bool) {
        stopSelectionMotion()
        state = expanded ? .expanded : .assembled
        selectedLayer = nil
        manualOffsets.removeAll()
        selectedLayerLabel.alpha = 0
        updateCamera(for: state, animated: false)
        hintLabel.text = expanded ? "调试模式：使用面板调整模型" : "调试模式：合拢状态"
        updateModelTransforms(animated: false)
        debugHighlight(debugTargetLayer)
        syncDebugPanel()
        onExpandedChanged?(expanded)
    }

    private func debugHighlight(_ layer: HomeLayer) {
        selectedLayer = layer
        for candidate in HomeLayer.allCases {
            models[candidate]?.root.opacity = candidate == layer ? 1 : 0.24
        }
        haloView.layer.shadowColor = layer.tintColor.cgColor
        haloView.backgroundColor = GeoTheme.Color.mauve.withAlphaComponent(0.14)
        haloView.alpha = 1
        updateHaloPosition()
    }

    private func debugValues(for layer: HomeLayer) -> HomeModelDebugValues? {
        guard let root = models[layer]?.root else { return nil }
        let radiansToDegrees = Float(180 / Double.pi)
        return HomeModelDebugValues(
            position: root.position,
            rotationDegrees: SCNVector3(
                root.eulerAngles.x * radiansToDegrees,
                root.eulerAngles.y * radiansToDegrees,
                root.eulerAngles.z * radiansToDegrees),
            scale: root.scale.x)
    }

    private func syncDebugPanel() {
        guard let values = debugValues(for: debugTargetLayer) else { return }
        debugPanel.setStageExpanded(state == .expanded)
        debugPanel.setValues(values)
    }

    private func applyDebugValues(_ values: HomeModelDebugValues) {
        guard let root = models[debugTargetLayer]?.root else { return }
        let degreesToRadians = Float(Double.pi / 180)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        root.position.x = values.position.x
        root.position.y = values.position.y
        root.eulerAngles = SCNVector3(
            values.rotationDegrees.x * degreesToRadians,
            values.rotationDegrees.y * degreesToRadians,
            values.rotationDegrees.z * degreesToRadians)
        root.scale = SCNVector3(values.scale, values.scale, values.scale)
        SCNTransaction.commit()
        updateHaloPosition()
    }

    private func resetDebugTarget() {
        guard let root = models[debugTargetLayer]?.root else { return }
        applyDefaultRotation(to: root, layer: debugTargetLayer)
        if state == .assembled {
            applyAssembledTransform(to: root, layer: debugTargetLayer)
        } else {
            root.scale = SCNVector3(
                debugTargetLayer.expandedScale,
                debugTargetLayer.expandedScale,
                debugTargetLayer.expandedScale)
            root.position = SCNVector3(debugTargetLayer.expandedX, 0.12, 0)
        }
        debugHighlight(debugTargetLayer)
        syncDebugPanel()
    }

    private func copyDebugValues() {
        guard let values = debugValues(for: debugTargetLayer) else { return }
        let mode = state == .expanded ? "expanded" : "assembled"
        let output = String(
            format: "%@.%@: position=(%.3f, %.3f, %.3f), rotationDegrees=(%.1f, %.1f, %.1f), scale=%.3f",
            debugTargetLayer.title,
            mode,
            values.position.x, values.position.y, values.position.z,
            values.rotationDegrees.x, values.rotationDegrees.y, values.rotationDegrees.z,
            values.scale)
        UIPasteboard.general.string = output
        print("🧭 首页模型参数：\(output)")
        debugPanel.showCopiedFeedback()
    }
    #endif

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
