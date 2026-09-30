//
//  PlayerNode.swift
//  GeoAdvanture
//
//  主角占位实现（胶囊 + 眼睛 + 行走上下起伏）。真美术到位后换成 player_idle/walk 序列帧。
//  约定：节点原点在角色中心；朝向用 xScale 翻转。
//

import SpriteKit

final class PlayerNode: SKNode {

    private let body: SKShapeNode
    private let bodyHeight: CGFloat
    private var walking = false

    init(color: UIColor, height: CGFloat = 120) {
        bodyHeight = height
        let width = height * 0.55
        body = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: width * 0.42)
        super.init()

        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 3
        addChild(body)

        // 眼睛（朝向 +x）
        let eyeWhite = SKShapeNode(circleOfRadius: height * 0.09)
        eyeWhite.fillColor = .white
        eyeWhite.strokeColor = .clear
        eyeWhite.position = CGPoint(x: width * 0.18, y: height * 0.22)
        body.addChild(eyeWhite)

        let pupil = SKShapeNode(circleOfRadius: height * 0.04)
        pupil.fillColor = .black
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: width * 0.24, y: height * 0.22)
        body.addChild(pupil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 角色高度（用于把脚底对齐地面）。
    var height: CGFloat { bodyHeight }

    /// 朝向：>=0 向右，<0 向左。
    func setFacing(_ dir: CGFloat) {
        guard dir != 0 else { return }
        xScale = dir >= 0 ? 1 : -1
    }

    /// 行走时轻微上下起伏（作用于 body，不影响节点定位）。
    func setWalking(_ moving: Bool) {
        guard moving != walking else { return }
        walking = moving
        body.removeAction(forKey: "bob")
        if moving {
            let up = SKAction.moveBy(x: 0, y: 8, duration: 0.16)
            up.timingMode = .easeInEaseOut
            let down = up.reversed()
            body.run(.repeatForever(.sequence([up, down])), withKey: "bob")
        } else {
            body.run(.moveTo(y: 0, duration: 0.1))
        }
    }
}
