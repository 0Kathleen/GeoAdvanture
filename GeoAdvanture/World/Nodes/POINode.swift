//
//  POINode.swift
//  GeoAdvanture
//
//  横版世界里的「现象点(POI)」占位节点：圆形图标 + 类型字形 + 头顶气泡(? / !) + 已发现✓。
//  真美术到位后（PR-7）把圆形换成 poi_<id> 图标、气泡换成动效即可，接口不变。
//  约定：节点原点在图标中心；由 WorldScene 放到地面上方。
//

import SpriteKit

final class POINode: SKNode {

    let poi: POI
    private(set) var discovered: Bool

    private let disc = SKShapeNode(circleOfRadius: 28)
    private let glyph = SKLabelNode()
    private let bubble = SKLabelNode()     // 头顶：未发现"?"，靠近"!"
    private let check = SKLabelNode()      // 已发现/已采集 ✓
    private var nearby = false

    /// 图标中心相对地面应抬高的距离（让 POI 立在地面上）。
    var groundOffset: CGFloat { 68 }

    init(poi: POI, discovered: Bool, collected: Bool) {
        self.poi = poi
        self.discovered = discovered || collected
        super.init()

        disc.fillColor = Self.color(for: poi.interactionType)
        disc.strokeColor = .white
        disc.lineWidth = 3
        disc.zPosition = 1
        addChild(disc)

        glyph.text = Self.glyph(for: poi.interactionType)
        glyph.fontSize = 26
        glyph.verticalAlignmentMode = .center
        glyph.horizontalAlignmentMode = .center
        glyph.zPosition = 2
        disc.addChild(glyph)

        bubble.fontName = "PingFangSC-Semibold"
        bubble.fontSize = 30
        bubble.fontColor = .white
        bubble.verticalAlignmentMode = .center
        bubble.horizontalAlignmentMode = .center
        bubble.position = CGPoint(x: 0, y: 52)
        bubble.zPosition = 3
        addChild(bubble)

        check.text = "✓"
        check.fontName = "PingFangSC-Semibold"
        check.fontSize = 22
        check.fontColor = .systemGreen
        check.position = CGPoint(x: 24, y: 24)
        check.zPosition = 4
        check.isHidden = !self.discovered
        addChild(check)

        if self.discovered { disc.alpha = 0.8 }
        updateBubble()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 玩家是否在附近：靠近时放大 + 头顶"!"提示。
    func setNearby(_ value: Bool) {
        guard value != nearby else { return }
        nearby = value
        removeAction(forKey: "nearbyScale")
        let scale = SKAction.scale(to: value ? 1.18 : 1.0, duration: 0.15)
        scale.timingMode = .easeOut
        run(scale, withKey: "nearbyScale")
        updateBubble()
    }

    /// 标记为已发现（打开发现卡后调用）。
    func markDiscovered() {
        guard !discovered else { updateBubble(); return }
        discovered = true
        disc.alpha = 0.85
        check.isHidden = false
        updateBubble()
    }

    private func updateBubble() {
        bubble.removeAction(forKey: "pulse")
        if nearby {
            bubble.text = "!"
            let up = SKAction.scale(to: 1.25, duration: 0.35)
            up.timingMode = .easeInEaseOut
            bubble.run(.repeatForever(.sequence([up, up.reversed()])), withKey: "pulse")
        } else if !discovered {
            bubble.text = "?"
            bubble.setScale(1.0)
        } else {
            bubble.text = ""
            bubble.setScale(1.0)
        }
    }

    // MARK: - 占位样式映射

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
