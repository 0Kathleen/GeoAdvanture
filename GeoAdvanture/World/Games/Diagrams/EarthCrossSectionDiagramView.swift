//
//  EarthCrossSectionDiagramView.swift
//  GeoAdvanture
//
//  知识卡用的「地球分层剖面」示意图(代码绘制占位,图文混合)。
//  左侧同心圆剖面(地壳/地幔/外核/内核)+ 右侧图例。PR-7 可整体换成 AI 插画。
//

import UIKit

final class EarthCrossSectionDiagramView: UIView {

    private struct Band { let id: String; let name: String; let frac: CGFloat; let color: UIColor }

    /// 要高亮显示的圈层 id（crust / mantle / core）；nil 则不高亮。
    private let highlightLayerId: String?

    // 由外到内(frac = 相对最大半径的占比)
    private let bands: [Band] = [
        Band(id: "crust", name: "地壳", frac: 1.00, color: .hex(0x5E3C1E)),
        Band(id: "mantle", name: "地幔", frac: 0.90, color: .hex(0xC63A2A)),
        Band(id: "core", name: "地核", frac: 0.52, color: .hex(0x2E6FB0)),
        Band(id: "core", name: "内核", frac: 0.28, color: .hex(0xD8DCE3))
    ]

    init(highlightLayerId: String? = nil) {
        self.highlightLayerId = highlightLayerId
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.12, alpha: 1)
        layer.cornerRadius = 10
        clipsToBounds = true
        isOpaque = false
    }

    override init(frame: CGRect) {
        self.highlightLayerId = nil
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: rect.width * 0.32, y: rect.midY)
        let maxR = min(rect.height / 2 - 10, rect.width * 0.28)

        // 同心圆(从大到小叠画)
        for b in bands {
            let r = maxR * b.frac
            let path = UIBezierPath(arcCenter: center, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            b.color.setFill()
            path.fill()
            // 高亮当前层：描一圈亮边
            if highlightLayerId == b.id {
                UIColor.systemYellow.setStroke()
                path.lineWidth = 3
                path.stroke()
            }
        }

        // 右侧图例:色块 + 名称
        let legendX = rect.width * 0.62
        let rowH: CGFloat = 30
        let totalH = rowH * CGFloat(bands.count)
        var y = rect.midY - totalH / 2
        let attrs: [NSAttributedString.Key: Any] = [
            .font: GeoTheme.Typography.control(size: 14),
            .foregroundColor: UIColor.white
        ]
        for b in bands {
            let swatch = UIBezierPath(roundedRect: CGRect(x: legendX, y: y + 6, width: 16, height: 16), cornerRadius: 4)
            b.color.setFill()
            swatch.fill()
            (b.name as NSString).draw(at: CGPoint(x: legendX + 24, y: y + 6), withAttributes: attrs)
            y += rowH
        }
    }
}
