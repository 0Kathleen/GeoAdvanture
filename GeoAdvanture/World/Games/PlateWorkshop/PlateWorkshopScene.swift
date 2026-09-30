//
//  PlateWorkshopScene.swift
//  GeoAdvanture
//
//  「板块工坊」的可视化场景（几何占位）：两块板块在地幔上相遇，
//  玩家的连续输入 input∈[-1,1] 实时驱动形变——聚合造山/俯冲海沟、张裂成裂谷。
//  场景只按「板块类型 + 输入」渲染物理上正确的地貌，是否匹配目标由 VC 判定。
//  真美术到位后（PR-7）把色块换成 plate_/mountain_/trench_/rift_ 贴图即可，接口不变。
//

import SpriteKit

enum PlateKind {
    case continental   // 大陆板块（厚、轻）
    case oceanic       // 海洋板块（薄、重）
}

/// 当前输入产生的地貌种类。
enum LandformKind {
    case none, mountain, trench, rift
}

enum PlateFormationStage: Int {
    case resting
    case moving
    case contact
    case deforming
    case formed
}

final class PlateWorkshopScene: SKScene {

    private(set) var leftType: PlateKind = .continental
    private(set) var rightType: PlateKind = .continental
    private(set) var input: CGFloat = 0     // -1 张裂 … 0 … +1 聚合
    var onFormationStageChanged: ((PlateFormationStage) -> Void)?
    private var lastReportedStage: PlateFormationStage?

    // 节点
    private let backgroundArtwork = SKSpriteNode()
    private let mantle = SKSpriteNode()
    private let leftPlate = SKSpriteNode()
    private let rightPlate = SKSpriteNode()
    private var mountain = SKShapeNode()
    private var trench = SKShapeNode()
    private let volcano = SKShapeNode()
    private let rift = SKSpriteNode()

    // 布局参数（相对屏幕，便于换分辨率）
    private var seamX: CGFloat { size.width / 2 }
    private var groundY: CGFloat { size.height * 0.42 }
    private var plateH: CGFloat { size.height * 0.16 }
    private var maxOverlap: CGFloat { size.width * 0.12 }
    private var maxGap: CGFloat { size.width * 0.22 }
    private var maxMountain: CGFloat { size.height * 0.26 }
    private var maxTrench: CGFloat { size.height * 0.18 }

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = .hex(0x1B1414)
        buildNodes()
        setTypes(left: .continental, right: .continental)
        setInput(0)
    }

    private func buildNodes() {
        if let image = UIImage(named: "bg_workshop_crust") {
            backgroundArtwork.texture = SKTexture(image: image)
            backgroundArtwork.size = size
            backgroundArtwork.position = CGPoint(x: size.width / 2, y: size.height / 2)
            backgroundArtwork.zPosition = -2
            addChild(backgroundArtwork)
        }

        // 地幔底
        mantle.color = .hex(0x5C160F)
        mantle.alpha = backgroundArtwork.texture == nil ? 1 : 0.84
        mantle.anchorPoint = .zero
        mantle.size = CGSize(width: size.width, height: groundY)
        mantle.position = .zero
        mantle.zPosition = 0
        addChild(mantle)

        // 岩浆缝（张裂时显现）
        rift.color = .hex(0xFF7A2A)
        rift.anchorPoint = CGPoint(x: 0.5, y: 0)
        rift.zPosition = 1
        addChild(rift)

        for plate in [leftPlate, rightPlate] {
            plate.anchorPoint = CGPoint(x: 0.5, y: 0)
            plate.size = CGSize(width: size.width * 0.5, height: plateH)
            plate.zPosition = 2
            addChild(plate)
        }

        mountain.zPosition = 3
        mountain.lineWidth = 0
        addChild(mountain)

        trench.zPosition = 3
        trench.lineWidth = 0
        trench.fillColor = .hex(0x0E0A0A)
        addChild(trench)

        volcano.zPosition = 4
        volcano.lineWidth = 0
        volcano.fillColor = .hex(0xFF9A3D)
        volcano.isHidden = true
        addChild(volcano)
    }

    // MARK: - 对外

    func setTypes(left: PlateKind, right: PlateKind) {
        leftType = left
        rightType = right
        leftPlate.color = Self.color(for: left)
        rightPlate.color = Self.color(for: right)
        setInput(input)   // 刷新
    }

    /// 设置连续输入并实时重绘。
    func setInput(_ value: CGFloat) {
        input = max(-1, min(1, value))
        layout()
        let stage = formationStage
        if stage != lastReportedStage {
            lastReportedStage = stage
            onFormationStageChanged?(stage)
        }
    }

    var formationStage: PlateFormationStage {
        let value = abs(input)
        switch value {
        case 0..<0.04: return .resting
        case 0..<0.20: return .moving
        case 0..<0.42: return .contact
        case 0..<0.68: return .deforming
        default: return .formed
        }
    }

    /// 当前产生的地貌种类（物理正确）。
    var producedLandform: LandformKind {
        if input > 0.02 {
            return (leftType == .continental && rightType == .continental) ? .mountain : .trench
        } else if input < -0.02 {
            return .rift
        }
        return .none
    }

    /// 当前地貌强度 0…1（对应目标容差判定）。
    var magnitude: CGFloat {
        switch producedLandform {
        case .mountain, .trench: return max(0, input)
        case .rift: return max(0, -input)
        case .none: return 0
        }
    }

    /// 操作过猛：抖动 + 闪红，教「渐进施力」。
    func flashFracture() {
        let shake = SKAction.sequence([
            .moveBy(x: 8, y: 0, duration: 0.04),
            .moveBy(x: -16, y: 0, duration: 0.08),
            .moveBy(x: 8, y: 0, duration: 0.04)
        ])
        leftPlate.run(shake)
        rightPlate.run(shake)
        let flash = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        flash.fillColor = UIColor.systemRed.withAlphaComponent(0.35)
        flash.lineWidth = 0
        flash.zPosition = 20
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
    }

    // MARK: - 布局/重绘

    private func layout() {
        let converge = max(0, input)
        let diverge = max(0, -input)

        // 板块位移：聚合→内移，张裂→外移
        let shift = converge * maxOverlap - diverge * maxGap
        leftPlate.position = CGPoint(x: size.width * 0.25 + shift, y: groundY)
        rightPlate.position = CGPoint(x: size.width * 0.75 - shift, y: groundY)

        // 岩浆缝
        let gap = diverge * maxGap * 2
        rift.size = CGSize(width: max(0, gap), height: plateH + diverge * maxMountain * 0.4)
        rift.position = CGPoint(x: seamX, y: groundY)
        rift.isHidden = diverge < 0.02

        // 山脉
        let land = producedLandform
        mountain.isHidden = land != .mountain
        trench.isHidden = land != .trench
        volcano.isHidden = land != .trench

        let top = groundY + plateH
        if land == .mountain {
            let h = converge * maxMountain
            let w = size.width * 0.22
            let p = CGMutablePath()
            p.move(to: CGPoint(x: seamX - w / 2, y: top))
            p.addLine(to: CGPoint(x: seamX, y: top + h))
            p.addLine(to: CGPoint(x: seamX + w / 2, y: top))
            p.closeSubpath()
            mountain.path = p
            mountain.fillColor = .hex(0x8B5A2B)
        } else if land == .trench {
            // 俯冲海沟：向下的 V 型缺口 + 一侧小火山
            let d = converge * maxTrench
            let w = size.width * 0.16
            let p = CGMutablePath()
            p.move(to: CGPoint(x: seamX - w / 2, y: top))
            p.addLine(to: CGPoint(x: seamX, y: top - d))
            p.addLine(to: CGPoint(x: seamX + w / 2, y: top))
            p.closeSubpath()
            trench.path = p

            let vh = converge * maxMountain * 0.5
            let vw = size.width * 0.1
            let vx = seamX + w * 0.9
            let vp = CGMutablePath()
            vp.move(to: CGPoint(x: vx - vw / 2, y: top))
            vp.addLine(to: CGPoint(x: vx, y: top + vh))
            vp.addLine(to: CGPoint(x: vx + vw / 2, y: top))
            vp.closeSubpath()
            volcano.path = vp
        }
    }

    private static func color(for kind: PlateKind) -> UIColor {
        switch kind {
        case .continental: return .hex(0x9C6B3A)
        case .oceanic: return .hex(0x2E5E7E)
        }
    }
}
