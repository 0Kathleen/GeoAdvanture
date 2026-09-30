//
//  ParallaxBackgroundNode.swift
//  GeoAdvanture
//
//  三层视差背景（占位实现）。作为相机的子节点，随相机移动做出「远慢近快」的视差。
//  真美术到位后：把每层的占位形状换成 bg_<world>_far/_mid/_near 贴图即可，接口不变。
//

import SpriteKit

final class ParallaxBackgroundNode: SKNode {

    private struct Layer {
        let container: SKNode
        let factor: CGFloat   // 视差系数：越小越"远"、移动越慢
        let period: CGFloat   // 单块宽度（= 屏宽），用于无缝循环
    }

    private var layers: [Layer] = []
    private let screenSize: CGSize

    init(size: CGSize, palette: WorldPalette) {
        screenSize = size
        super.init()
        // 由远到近，zPosition 递增
        addLayer(color: palette.far,  factor: 0.2, z: -30, hillHeight: size.height * 0.22, hillCount: 2)
        addLayer(color: palette.mid,  factor: 0.5, z: -20, hillHeight: size.height * 0.16, hillCount: 3)
        addLayer(color: palette.near, factor: 0.8, z: -10, hillHeight: size.height * 0.10, hillCount: 4)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 相机移动时调用，制造视差滚动。
    func update(cameraX: CGFloat) {
        for l in layers {
            let shift = (cameraX * l.factor).truncatingRemainder(dividingBy: l.period)
            l.container.position = CGPoint(x: -shift, y: 0)
        }
    }

    // MARK: - 构建单层（3 块拼接实现无缝循环）

    private func addLayer(color: UIColor, factor: CGFloat, z: CGFloat, hillHeight: CGFloat, hillCount: Int) {
        let period = screenSize.width
        let container = SKNode()
        container.zPosition = z
        for i in -1...1 {
            let tile = makeTile(color: color, period: period, hillHeight: hillHeight, hillCount: hillCount, seed: i)
            tile.position = CGPoint(x: CGFloat(i) * period, y: 0)
            container.addChild(tile)
        }
        addChild(container)
        layers.append(Layer(container: container, factor: factor, period: period))
    }

    private func makeTile(color: UIColor, period: CGFloat, hillHeight: CGFloat, hillCount: Int, seed: Int) -> SKNode {
        let tile = SKNode()

        // 纯色底（覆盖整块，居中于相机坐标）
        let fill = SKSpriteNode(color: color, size: CGSize(width: period, height: screenSize.height))
        fill.position = .zero
        tile.addChild(fill)

        // 占位"山丘"，让视差滚动清晰可见（真美术会替换整层贴图）
        let hillColor = color.withAlphaComponent(0.55)
        let bottom = -screenSize.height / 2
        for h in 0..<hillCount {
            let width = period / CGFloat(hillCount) * 1.4
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -width / 2, y: 0))
            path.addQuadCurve(to: CGPoint(x: width / 2, y: 0),
                              controlPoint: CGPoint(x: 0, y: hillHeight))
            path.close()
            let hill = SKShapeNode(path: path.cgPath)
            hill.fillColor = hillColor
            hill.strokeColor = .clear
            let step = period / CGFloat(hillCount)
            let x = -period / 2 + step * (CGFloat(h) + 0.5) + CGFloat((seed &* 37 + h &* 13) % 20) - 10
            hill.position = CGPoint(x: x, y: bottom + screenSize.height * 0.18)
            tile.addChild(hill)
        }
        return tile
    }
}
