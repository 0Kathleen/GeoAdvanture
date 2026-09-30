//
//  DeepDiveLabScene.swift
//  GeoAdvanture
//
//  地幔 operate 游戏「深潜驾驶舱」的仿真 + 可视化（几何占位）。
//  取代旧「设参数看样本自己掉」：全程玩家实时调「隔热/耐压」把样本状态压在安全包络内。
//  越深温度/压力越高（浅层热主导、深层压主导），过圈层边界有骤升事件，失衡即熔毁/压碎。
//  真美术到位后（PR-7）把圆点样本/色带换成 sample_/layer_ 贴图即可，接口不变。
//

import SpriteKit

struct DiveTelemetry {
    let depthKm: Int
    let layerName: String
    let envTemp: CGFloat     // 0…1
    let envPressure: CGFloat // 0…1
    let heat: CGFloat        // 0…1 累积热负荷
    let stress: CGFloat      // 0…1 累积压力负荷
    let event: String?       // 边界事件提示
}

protocol DeepDiveLabSceneDelegate: AnyObject {
    func diveDidUpdate(_ t: DiveTelemetry)
    func diveDidFinish(success: Bool, reachedLayer: String, stars: Int)
}

final class DeepDiveLabScene: SKScene {

    weak var diveDelegate: DeepDiveLabSceneDelegate?

    // 玩家实时输入（由 VC 的滑杆设置）
    var insulation: CGFloat = 0.3
    var resist: CGFloat = 0.3

    // 仿真状态
    private var progress: CGFloat = 0        // 0…1 深度进度
    private var heat: CGFloat = 0
    private var stress: CGFloat = 0
    private var maxHeat: CGFloat = 0
    private var maxStress: CGFloat = 0
    private var finished = false
    private var lastUpdate: TimeInterval = 0
    private var running = false

    // 圈层（归一化起始深度）
    private let layers: [(name: String, start: CGFloat, km: Int)] = [
        ("地壳", 0.00, 0), ("上地幔", 0.10, 400), ("下地幔", 0.25, 1000),
        ("外核", 0.55, 3400), ("内核", 0.83, 5200)
    ]
    private let maxDepthKm = 6371
    private let descentSeconds: CGFloat = 32
    private var lastLayerIndex = -1
    private var spikeTimer: CGFloat = 0
    private var spikeEvent: String?

    // 节点
    private let sample = SKShapeNode(circleOfRadius: 22)
    private var bands: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = .hex(0x120A08)
        buildBands()
        sample.fillColor = .hex(0xFFE08A)
        sample.strokeColor = .white
        sample.lineWidth = 3
        // 放到屏幕垂直中部:上方留给深度/负荷条 HUD,下方留给双滑杆,避免被 UIKit 控件遮挡
        sample.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        sample.zPosition = 10
        addChild(sample)
    }

    private func buildBands() {
        // 背景色带随下潜滚动，制造「持续下沉」的感觉
        let colors: [UIColor] = [.hex(0x6E4A2A), .hex(0x8E241B), .hex(0xC63A2A), .hex(0x184A78), .hex(0x5E6675)]
        let bandH = size.height * 0.5
        for i in 0..<8 {
            let b = SKSpriteNode(color: colors[i % colors.count], size: CGSize(width: size.width, height: bandH))
            b.anchorPoint = .zero
            b.position = CGPoint(x: 0, y: size.height - CGFloat(i) * bandH)
            b.zPosition = 0
            b.alpha = 0.5
            addChild(b)
            bands.append(b)
        }
    }

    func startDive() {
        running = true
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard running, !finished, lastUpdate > 0 else { return }
        let dt = CGFloat(min(currentTime - lastUpdate, 1.0 / 30.0))

        progress = min(1, progress + dt / descentSeconds)
        scrollBands(dt: dt)

        // 圈层与边界骤升事件
        let idx = currentLayerIndex()
        if idx != lastLayerIndex {
            lastLayerIndex = idx
            if idx > 0 {
                spikeTimer = 2.2
                spikeEvent = "进入\(layers[idx].name):环境骤变!"
            }
        }
        var spikeMul: CGFloat = 1
        if spikeTimer > 0 { spikeTimer -= dt; spikeMul = 1.45 } else { spikeEvent = nil }

        // 环境:浅层热主导、深层压主导
        let envTemp = min(1, (0.25 + progress * 0.9) * spikeMul)
        let envPressure = min(1, (progress * progress * 1.3) * spikeMul)

        // 负荷累积（防护不足则升，充足则缓降）
        let comfort: CGFloat = 0.15
        let hRate = envTemp * (1 - insulation) - comfort
        let sRate = envPressure * (1 - resist) - comfort
        heat = max(0, heat + (hRate > 0 ? hRate * dt * 0.55 : -0.14 * dt))
        stress = max(0, stress + (sRate > 0 ? sRate * dt * 0.55 : -0.14 * dt))
        maxHeat = max(maxHeat, heat)
        maxStress = max(maxStress, stress)

        updateSampleVisual()

        diveDelegate?.diveDidUpdate(DiveTelemetry(
            depthKm: Int(progress * CGFloat(maxDepthKm)),
            layerName: layers[idx].name,
            envTemp: envTemp, envPressure: envPressure,
            heat: min(1, heat), stress: min(1, stress),
            event: spikeEvent))

        if heat >= 1 { fail(reason: "样本在\(layers[idx].name)熔毁") }
        else if stress >= 1 { fail(reason: "样本在\(layers[idx].name)被压碎") }
        else if progress >= 1 { succeed() }
    }

    private func scrollBands(dt: CGFloat) {
        let speed = size.height * 0.5 / descentSeconds
        for b in bands {
            b.position.y += speed * dt
            if b.position.y > size.height { b.position.y -= CGFloat(bands.count) * b.size.height }
        }
    }

    private func updateSampleVisual() {
        // 越热越红、越受压越暗/缩小
        let r = 1.0
        let g = max(0.2, 0.88 - heat * 0.7)
        let b = max(0.1, 0.54 - heat * 0.5 - stress * 0.2)
        sample.fillColor = UIColor(red: r, green: g, blue: b, alpha: 1)
        let scale = max(0.7, 1 - stress * 0.3)
        sample.setScale(scale)
        sample.strokeColor = stress > 0.7 ? .systemRed : .white
    }

    private func currentLayerIndex() -> Int {
        var idx = 0
        for (i, l) in layers.enumerated() where progress >= l.start { idx = i }
        return idx
    }

    private func fail(reason: String) {
        guard !finished else { return }
        finished = true
        running = false
        diveDelegate?.diveDidFinish(success: false, reachedLayer: reason, stars: 0)
    }

    private func succeed() {
        guard !finished else { return }
        finished = true
        running = false
        let worst = max(maxHeat, maxStress)
        let stars = worst < 0.6 ? 3 : (worst < 0.85 ? 2 : 1)
        diveDelegate?.diveDidFinish(success: true, reachedLayer: "内核", stars: stars)
    }
}
