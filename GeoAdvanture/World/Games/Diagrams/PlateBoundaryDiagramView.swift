//
//  PlateBoundaryDiagramView.swift
//  GeoAdvanture
//
//  知识卡用的「板块边界」示意图(代码绘制占位,图文混合)。
//  三格并排:聚合造山 / 俯冲海沟 / 张裂裂谷。PR-7 可整体换成 AI 插画。
//

import UIKit

final class PlateBoundaryDiagramView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let cellW = rect.width / 3
        drawMountain(in: CGRect(x: 0, y: 0, width: cellW, height: rect.height), label: "碰撞→山脉")
        drawTrench(in: CGRect(x: cellW, y: 0, width: cellW, height: rect.height), label: "俯冲→海沟")
        drawRift(in: CGRect(x: cellW * 2, y: 0, width: cellW, height: rect.height), label: "张裂→裂谷")
    }

    private let crust = UIColor.hex(0x8B5A2B)
    private let ocean = UIColor.hex(0x2E5E7E)
    private let magma = UIColor.hex(0xFF7A2A)

    private func baseY(_ r: CGRect) -> CGFloat { r.maxY - 42 }

    private func drawMountain(in r: CGRect, label: String) {
        let by = baseY(r)
        crust.setFill()
        UIBezierPath(rect: CGRect(x: r.minX + 8, y: by, width: r.width - 16, height: 20)).fill()
        // 山峰
        let m = UIBezierPath()
        m.move(to: CGPoint(x: r.midX - 22, y: by))
        m.addLine(to: CGPoint(x: r.midX, y: by - 34))
        m.addLine(to: CGPoint(x: r.midX + 22, y: by))
        m.close()
        m.fill()
        drawArrows(r, by: by, inward: true)
        drawLabel(label, in: r)
    }

    private func drawTrench(in r: CGRect, label: String) {
        let by = baseY(r)
        crust.setFill()
        UIBezierPath(rect: CGRect(x: r.midX, y: by, width: r.width / 2 - 8, height: 20)).fill()
        ocean.setFill()
        UIBezierPath(rect: CGRect(x: r.minX + 8, y: by + 4, width: r.width / 2 - 8, height: 14)).fill()
        // 海沟缺口
        let t = UIBezierPath()
        t.move(to: CGPoint(x: r.midX - 10, y: by))
        t.addLine(to: CGPoint(x: r.midX, y: by + 24))
        t.addLine(to: CGPoint(x: r.midX + 8, y: by))
        t.close()
        UIColor.hex(0x0E0A0A).setFill()
        t.fill()
        drawArrows(r, by: by, inward: true)
        drawLabel(label, in: r)
    }

    private func drawRift(in r: CGRect, label: String) {
        let by = baseY(r)
        crust.setFill()
        UIBezierPath(rect: CGRect(x: r.minX + 6, y: by, width: r.width / 2 - 14, height: 20)).fill()
        UIBezierPath(rect: CGRect(x: r.midX + 8, y: by, width: r.width / 2 - 14, height: 20)).fill()
        // 岩浆缝
        magma.setFill()
        UIBezierPath(rect: CGRect(x: r.midX - 8, y: by - 8, width: 16, height: 28)).fill()
        drawArrows(r, by: by, inward: false)
        drawLabel(label, in: r)
    }

    private func drawArrows(_ r: CGRect, by: CGFloat, inward: Bool) {
        UIColor.white.setStroke()
        let y = by - 44
        let cx = r.midX
        for sign in [CGFloat(-1), 1] {
            let path = UIBezierPath()
            let startX = inward ? cx + sign * 40 : cx + sign * 14
            let endX = inward ? cx + sign * 16 : cx + sign * 42
            path.move(to: CGPoint(x: startX, y: y))
            path.addLine(to: CGPoint(x: endX, y: y))
            path.lineWidth = 2
            path.stroke()
            // 箭头
            let head = UIBezierPath()
            head.move(to: CGPoint(x: endX, y: y))
            head.addLine(to: CGPoint(x: endX - sign * 6, y: y - 4))
            head.move(to: CGPoint(x: endX, y: y))
            head.addLine(to: CGPoint(x: endX - sign * 6, y: y + 4))
            head.lineWidth = 2
            head.stroke()
        }
    }

    private func drawLabel(_ text: String, in r: CGRect) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: GeoTheme.Typography.control(size: 12),
            .foregroundColor: UIColor.white
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: r.midX - size.width / 2, y: r.maxY - 18), withAttributes: attrs)
    }
}
