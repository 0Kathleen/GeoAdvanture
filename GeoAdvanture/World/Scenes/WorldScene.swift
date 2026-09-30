//
//  WorldScene.swift
//  GeoAdvanture
//
//  横版探索世界核心场景（PR-2 · 克制垂直版）：
//   - 阶梯下降地形（越走越深，呼应「下潜」主题）
//   - 平台间「攀爬点」上下移动（无跳跃/碰撞物理）
//   - 奔跑（按住渐加速）+ 相机水平前瞻缓动
//   - 三层视差背景（占位）
//  坐标：anchorPoint=(0,0)；世界宽=屏宽×widthScreens；垂直范围收进单屏，相机只水平滚动。
//

import SpriteKit

final class WorldScene: SKScene {

    // 依赖
    private let viewModel: WorldViewModel

    // 节点
    private let cameraNode = SKCameraNode()
    private var parallax: ParallaxBackgroundNode!
    private var player: PlayerNode!
    private var climbHint: SKLabelNode!

    // 地形
    private var terrain: WorldTerrain!
    private var currentPlatform = 0
    private var isClimbing = false

    // 布局
    private var worldWidth: CGFloat = 0
    private let edgeMargin: CGFloat = 60

    // 运动
    private var moveDir: CGFloat = 0            // -1 / 0 / 1
    private var moveHoldTime: TimeInterval = 0  // 用于奔跑渐加速
    private let walkSpeed: CGFloat = 300
    private let runSpeed: CGFloat = 560
    private let runRampTime: TimeInterval = 0.6
    private var facing: CGFloat = 1
    private var lastUpdate: TimeInterval = 0
    private var camX: CGFloat = 0

    // POI（PR-3）
    private var poiNodes: [(node: POINode, worldX: CGFloat)] = []
    private var currentNearbyId: String?
    private let poiReach: CGFloat = 92

    /// 走到最深处「出口」的回调（PR-5 接下潜;PR-2 仅提示）。
    var onReachExit: (() -> Void)?
    private var exitTriggered = false

    /// 靠近的可交互 POI 变化回调（nil = 已离开所有 POI）。供 VC 控制「互动」按钮与发现卡。
    var onNearbyPOIChanged: ((POI?) -> Void)?

    init(size: CGSize, viewModel: WorldViewModel) {
        self.viewModel = viewModel
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - 生命周期

    override func didMove(to view: SKView) {
        let palette = viewModel.palette
        backgroundColor = palette.sky
        worldWidth = size.width * viewModel.widthScreens
        terrain = WorldTerrain.descending(worldWidth: worldWidth, sceneHeight: size.height)

        setupCameraAndParallax(palette: palette)
        setupTerrain(palette: palette)
        setupEdgeMarkers()
        setupPOIs()
        setupPlayer(palette: palette)
        setupClimbHint()

        camX = clampCameraX(player.position.x)
        updateCamera(immediate: true)
    }

    // MARK: - 构建

    private func setupCameraAndParallax(palette: WorldPalette) {
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2) // y 固定，只水平滚
        addChild(cameraNode)

        parallax = ParallaxBackgroundNode(size: size, palette: palette)
        cameraNode.addChild(parallax)
    }

    private func setupTerrain(palette: WorldPalette) {
        let surfaceColor = palette.ground.lighter(0.12)
        for p in terrain.platforms {
            // 平台主体（从地面 0 填到平台表面 y，形成阶梯崖壁）
            let body = SKSpriteNode(color: palette.ground, size: CGSize(width: p.width, height: p.y))
            body.anchorPoint = .zero
            body.position = CGPoint(x: p.xStart, y: 0)
            body.zPosition = 0
            addChild(body)

            // 表面高亮条
            let surface = SKSpriteNode(color: surfaceColor, size: CGSize(width: p.width, height: 6))
            surface.anchorPoint = .zero
            surface.position = CGPoint(x: p.xStart, y: p.y - 6)
            surface.zPosition = 1
            addChild(surface)
        }
        // 相邻平台衔接处画梯子
        for i in 0..<(terrain.count - 1) {
            let hi = terrain.platforms[i]
            let lo = terrain.platforms[i + 1]
            addLadder(atX: hi.xEnd, yLow: lo.y, yHigh: hi.y, color: surfaceColor)
        }
    }

    private func addLadder(atX x: CGFloat, yLow: CGFloat, yHigh: CGFloat, color: UIColor) {
        let container = SKNode()
        container.zPosition = 2
        let railOffset: CGFloat = 14
        for dx in [-railOffset, railOffset] {
            let rail = SKSpriteNode(color: color, size: CGSize(width: 4, height: yHigh - yLow))
            rail.anchorPoint = .zero
            rail.position = CGPoint(x: x + dx - 2, y: yLow)
            container.addChild(rail)
        }
        var y = yLow + 10
        while y < yHigh {
            let rung = SKSpriteNode(color: color, size: CGSize(width: railOffset * 2 + 8, height: 4))
            rung.anchorPoint = .zero
            rung.position = CGPoint(x: x - railOffset - 4, y: y)
            container.addChild(rung)
            y += 18
        }
        addChild(container)
    }

    private func setupEdgeMarkers() {
        let start = terrain.first
        addFloatingLabel("START", x: start.xStart + 40, y: start.y + 90, color: .white)
        let end = terrain.last
        addFloatingLabel("出口 ↓", x: end.xEnd - 60, y: end.y + 90, color: .systemYellow)
    }

    private func addFloatingLabel(_ text: String, x: CGFloat, y: CGFloat, color: UIColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 20
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: x, y: y)
        label.zPosition = 5
        addChild(label)
    }

    private func setupPOIs() {
        let gm = GameProgressManager.shared
        for poi in viewModel.visiblePOIs {
            let worldX = CGFloat(poi.x) * worldWidth
            let collected = poi.collectibleId.map { gm.isCollected(id: $0) } ?? false
            let node = POINode(poi: poi, discovered: gm.isPOIDiscovered(id: poi.id), collected: collected)
            node.position = CGPoint(x: worldX, y: terrain.surfaceY(atX: worldX) + node.groundOffset)
            node.zPosition = 8
            addChild(node)
            poiNodes.append((node, worldX))
        }
    }

    private func setupPlayer(palette: WorldPalette) {
        player = PlayerNode(color: palette.player, height: size.height * 0.18)
        player.zPosition = 10
        let p0 = terrain.first
        player.position = CGPoint(x: p0.xStart + edgeMargin, y: p0.y + player.height / 2)
        addChild(player)
    }

    private func setupClimbHint() {
        climbHint = SKLabelNode(text: "")
        climbHint.fontName = "PingFangSC-Semibold"
        climbHint.fontSize = 22
        climbHint.fontColor = .systemYellow
        climbHint.verticalAlignmentMode = .center
        climbHint.zPosition = 20
        climbHint.isHidden = true
        addChild(climbHint)
    }

    // MARK: - 对外：移动 / 攀爬控制（由 WorldViewController 调用）

    func startMoving(_ dir: CGFloat) { moveDir = dir }
    func stopMoving() { moveDir = 0; moveHoldTime = 0 }

    /// 更新某个 POI 的已发现视觉（发现/采集后由 VC 调用）。
    func refreshPOIState(_ poiId: String) {
        poiNodes.first { $0.node.poi.id == poiId }?.node.markDiscovered()
    }

    /// 尝试向下攀爬到更深的一层（在平台右端衔接处生效）。
    func tryClimbDown() {
        guard !isClimbing else { return }
        let p = terrain.platforms[currentPlatform]
        guard currentPlatform < terrain.count - 1,
              player.position.x >= p.xEnd - terrain.reach else { return }
        beginClimb(to: currentPlatform + 1, junctionX: p.xEnd, nudge: +(terrain.reach + 10))
    }

    /// 尝试向上攀爬到更浅的一层（在平台左端衔接处生效）。
    func tryClimbUp() {
        guard !isClimbing else { return }
        let p = terrain.platforms[currentPlatform]
        guard currentPlatform > 0,
              player.position.x <= p.xStart + terrain.reach else { return }
        beginClimb(to: currentPlatform - 1, junctionX: p.xStart, nudge: -(terrain.reach + 10))
    }

    private func beginClimb(to index: Int, junctionX: CGFloat, nudge: CGFloat) {
        isClimbing = true
        climbHint.isHidden = true
        let target = terrain.platforms[index]
        let targetY = target.y + player.height / 2
        player.setWalking(true)

        let toX = SKAction.moveTo(x: junctionX, duration: 0.08)
        let toY = SKAction.moveTo(y: targetY, duration: 0.35)
        toY.timingMode = .easeInEaseOut
        player.run(.sequence([toX, toY])) { [weak self] in
            guard let self = self else { return }
            self.currentPlatform = index
            // 落到新平台后向内挪一点，避免立刻再次触发攀爬
            let clampedX = min(max(junctionX + nudge, target.xStart + 4), target.xEnd - 4)
            self.player.position.x = clampedX
            self.isClimbing = false
        }
    }

    // MARK: - 帧更新

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard lastUpdate > 0 else { return }
        let dt = min(currentTime - lastUpdate, 1.0 / 30.0)

        if !isClimbing {
            updateWalk(dt: dt)
            updateClimbHint()
        }
        updateNearbyPOI()
        updateCamera(immediate: false)
    }

    /// 找出离玩家最近且在范围内的 POI，更新高亮与「靠近」回调。
    private func updateNearbyPOI() {
        var nearest: (node: POINode, dist: CGFloat)?
        for (node, worldX) in poiNodes {
            let d = abs(player.position.x - worldX)
            node.setNearby(false)
            if d <= poiReach, nearest == nil || d < nearest!.dist {
                nearest = (node, d)
            }
        }
        nearest?.node.setNearby(true)
        let nearId = nearest?.node.poi.id
        if nearId != currentNearbyId {
            currentNearbyId = nearId
            onNearbyPOIChanged?(nearest?.node.poi)
        }
    }

    private func updateWalk(dt: TimeInterval) {
        let p = terrain.platforms[currentPlatform]
        if moveDir != 0 {
            moveHoldTime += dt
            let ramp = CGFloat(min(moveHoldTime / runRampTime, 1))
            let speed = walkSpeed + (runSpeed - walkSpeed) * ramp
            var x = player.position.x + moveDir * speed * CGFloat(dt)
            x = min(max(x, p.xStart), p.xEnd)
            player.position = CGPoint(x: x, y: p.y + player.height / 2)
            facing = moveDir
            player.setFacing(moveDir)
            player.setWalking(true)
            checkExit(x)
        } else {
            moveHoldTime = 0
            player.setWalking(false)
        }
    }

    private func updateClimbHint() {
        let p = terrain.platforms[currentPlatform]
        let canDown = currentPlatform < terrain.count - 1 && player.position.x >= p.xEnd - terrain.reach
        let canUp = currentPlatform > 0 && player.position.x <= p.xStart + terrain.reach
        if canDown {
            climbHint.text = "▼ 下潜"
        } else if canUp {
            climbHint.text = "▲ 攀上"
        }
        climbHint.isHidden = !(canDown || canUp)
        if !climbHint.isHidden {
            climbHint.position = CGPoint(x: player.position.x, y: player.position.y + player.height / 2 + 26)
        }
    }

    private func updateCamera(immediate: Bool) {
        let lookAhead: CGFloat = 90
        let target = clampCameraX(player.position.x + facing * lookAhead)
        if immediate {
            camX = target
        } else {
            camX += (target - camX) * 0.12   // 缓动前瞻
        }
        cameraNode.position.x = camX
        parallax.update(cameraX: camX)
    }

    private func clampCameraX(_ x: CGFloat) -> CGFloat {
        let half = size.width / 2
        return min(max(x, half), max(half, worldWidth - half))
    }

    private func checkExit(_ x: CGFloat) {
        guard !exitTriggered,
              currentPlatform == terrain.count - 1,
              x >= terrain.last.xEnd - edgeMargin - 1 else { return }
        exitTriggered = true
        onReachExit?()
    }

    /// 出口条件不满足(如本层未通关)时,允许玩家走回再次触发。
    func rearmExit() { exitTriggered = false }
}
