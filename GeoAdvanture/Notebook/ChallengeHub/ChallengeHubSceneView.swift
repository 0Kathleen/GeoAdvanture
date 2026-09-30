//
//  ChallengeHubSceneView.swift
//  GeoAdvanture
//
//  六类二级页共用的主题视觉舞台。美术资源可在后续直接替换中心视觉，
//  不影响路由、玩法和进度接口。
//

import UIKit
import SnapKit

final class ChallengeHubSceneView: UIView {

    private let definition: ChallengeHubDefinition
    private let poi: POI
    private let haloView = UIView()
    private let modelView = UIImageView()
    private var miniatureView: ChallengeHubMiniatureView?
    private let sceneTitleLabel = UILabel()
    private let hintLabel = UILabel()
    private let knowledgeToolLabel = UILabel()
    private var activeKnowledgeTool: KnowledgeToolDefinition?
    private var usesFullArtwork = false

    private struct Theme {
        let symbol: String
        let accent: UIColor
        let background: UIColor
        let hint: String
    }

    init(definition: ChallengeHubDefinition, poi: POI) {
        self.definition = definition
        self.poi = poi
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCompleted(_ completed: Bool, animated: Bool) {
        let updates = {
            self.modelView.tintColor = completed ? .systemGreen : self.theme.accent
            self.miniatureView?.setCompleted(completed)
            if let tool = self.activeKnowledgeTool {
                self.hintLabel.text = tool.overlayDescription
            } else {
                self.hintLabel.text = self.theme.hint
            }
        }
        if animated {
            UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: updates)
        } else {
            updates()
        }
    }

    func revealObservation() {
        haloView.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
        haloView.alpha = 0.45
        UIView.animate(
            withDuration: 0.55,
            delay: 0,
            usingSpringWithDamping: 0.62,
            initialSpringVelocity: 0.4,
            options: .curveEaseOut) {
                self.haloView.transform = .identity
                self.haloView.alpha = 1
                self.modelView.transform = CGAffineTransform(rotationAngle: .pi / 28)
                self.miniatureView?.transform = CGAffineTransform(rotationAngle: .pi / 42)
            } completion: { _ in
                UIView.animate(withDuration: 0.22) {
                    self.modelView.transform = .identity
                    self.miniatureView?.transform = .identity
                }
            }
    }

    func setKnowledgeTool(_ tool: KnowledgeToolDefinition?, active: Bool) {
        activeKnowledgeTool = active ? tool : nil
        knowledgeToolLabel.text = tool.map { "  \($0.title)已开启  " }
        knowledgeToolLabel.isHidden = !active
        hintLabel.text = active ? tool?.overlayDescription : theme.hint
        modelView.layer.shadowColor = active ? theme.accent.cgColor : UIColor.clear.cgColor
        modelView.layer.shadowRadius = active ? 16 : 0
        modelView.layer.shadowOpacity = active ? 0.9 : 0
        miniatureView?.layer.shadowColor = active ? theme.accent.cgColor : UIColor.clear.cgColor
        miniatureView?.layer.shadowRadius = active ? 16 : 0
        miniatureView?.layer.shadowOpacity = active ? 0.9 : 0
    }

    private var theme: Theme {
        switch definition.sceneKind {
        case "plateTerrain":
            return Theme(symbol: "mountain.2.fill", accent: .systemOrange,
                         background: UIColor(red: 0.84, green: 0.91, blue: 0.82, alpha: 1),
                         hint: "转动世界地貌模型，寻找三处缺失结构")
        case "specimenTable":
            return Theme(symbol: "seal.fill", accent: .systemBrown,
                         background: UIColor(red: 0.91, green: 0.84, blue: 0.72, alpha: 1),
                         hint: "检查岩壁样本，再进入采集操作")
        case "riftSection":
            return Theme(symbol: "arrow.left.and.right", accent: .systemTeal,
                         background: UIColor(red: 0.76, green: 0.89, blue: 0.87, alpha: 1),
                         hint: "观察地层向两侧拉开后的变化")
        case "mineralCabinet":
            return Theme(symbol: "diamond.fill", accent: .systemPurple,
                         background: UIColor(red: 0.87, green: 0.82, blue: 0.93, alpha: 1),
                         hint: "从晶体外形和光泽中寻找矿物线索")
        case "volcanoObservatory":
            return Theme(symbol: "flame.fill", accent: .systemRed,
                         background: UIColor(red: 0.94, green: 0.80, blue: 0.70, alpha: 1),
                         hint: "记录火山口、喷出物与周围地貌")
        default:
            return Theme(symbol: "drop.fill", accent: .systemOrange,
                         background: UIColor(red: 0.94, green: 0.75, blue: 0.58, alpha: 1),
                         hint: "沿通道观察地下物质如何抵达地表")
        }
    }

    private func setupUI() {
        backgroundColor = theme.background
        layer.cornerRadius = 28
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.withAlphaComponent(0.72).cgColor
        clipsToBounds = true

        let grid = ChallengeHubGridView(color: theme.accent.withAlphaComponent(0.12))
        addSubview(grid)
        grid.snp.makeConstraints { $0.edges.equalToSuperview() }

        knowledgeToolLabel.font = GeoTheme.Typography.caption(size: 10)
        knowledgeToolLabel.textColor = .white
        knowledgeToolLabel.textAlignment = .center
        knowledgeToolLabel.backgroundColor = GeoTheme.Color.blue.withAlphaComponent(0.90)
        knowledgeToolLabel.layer.cornerRadius = 9
        knowledgeToolLabel.clipsToBounds = true
        knowledgeToolLabel.isHidden = true
        addSubview(knowledgeToolLabel)
        knowledgeToolLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.height.equalTo(20)
        }

        haloView.backgroundColor = UIColor.white.withAlphaComponent(0.46)
        haloView.layer.cornerRadius = 105
        addSubview(haloView)
        haloView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-25)
            make.width.height.equalTo(210)
        }

        if let asset = definition.modelAsset, let image = UIImage(named: asset) {
            usesFullArtwork = true
            haloView.isHidden = true
            modelView.image = image
            modelView.tintColor = nil
            modelView.contentMode = .scaleAspectFill
            addSubview(modelView)
            modelView.snp.makeConstraints { $0.edges.equalToSuperview() }

            let scrim = UIView()
            // 保留各主题原有识别色：矿物紫、裂谷青、火山暖红等。
            scrim.backgroundColor = theme.background.withAlphaComponent(0.24)
            addSubview(scrim)
            scrim.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            let miniature = ChallengeHubMiniatureView(sceneKind: definition.sceneKind, accent: theme.accent)
            miniatureView = miniature
            addSubview(miniature)
            miniature.snp.makeConstraints { make in
                make.center.equalTo(haloView)
                make.width.equalTo(176)
                make.height.equalTo(142)
            }
        }

        sceneTitleLabel.text = definition.title
        sceneTitleLabel.font = GeoTheme.Typography.heading(size: 21)
        sceneTitleLabel.textColor = usesFullArtwork
            ? .white
            : GeoTheme.Color.ink
        sceneTitleLabel.layer.shadowColor = UIColor.black.cgColor
        sceneTitleLabel.layer.shadowOpacity = usesFullArtwork ? 0.55 : 0
        sceneTitleLabel.layer.shadowRadius = 4
        sceneTitleLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        sceneTitleLabel.textAlignment = .center
        sceneTitleLabel.isHidden = usesFullArtwork
        addSubview(sceneTitleLabel)
        sceneTitleLabel.snp.makeConstraints { make in
            if usesFullArtwork {
                make.top.equalToSuperview().offset(18)
            } else {
                make.top.equalTo(haloView.snp.bottom).offset(12)
            }
            make.leading.trailing.equalToSuperview().inset(20)
        }

        hintLabel.text = theme.hint
        hintLabel.font = GeoTheme.Typography.body(size: 13)
        hintLabel.textColor = usesFullArtwork ? .white : GeoTheme.Color.inkMuted
        hintLabel.layer.shadowColor = UIColor.black.cgColor
        hintLabel.layer.shadowOpacity = usesFullArtwork ? 0.55 : 0
        hintLabel.layer.shadowRadius = 3
        hintLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 2
        hintLabel.clipsToBounds = true
        if usesFullArtwork {
            hintLabel.backgroundColor = GeoTheme.Color.darkOverlay
            hintLabel.layer.cornerRadius = GeoTheme.Radius.control
        }
        addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            if usesFullArtwork {
                make.bottom.equalToSuperview().inset(16)
                make.height.greaterThanOrEqualTo(32)
            } else {
                make.top.equalTo(sceneTitleLabel.snp.bottom).offset(5)
            }
            make.leading.trailing.equalToSuperview().inset(24)
        }

        bringSubviewToFront(knowledgeToolLabel)
    }
}

private final class ChallengeHubMiniatureView: UIView {

    private let sceneKind: String
    private let accent: UIColor
    private var completed = false

    init(sceneKind: String, accent: UIColor) {
        self.sceneKind = sceneKind
        self.accent = accent
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCompleted(_ completed: Bool) {
        self.completed = completed
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        switch sceneKind {
        case "specimenTable": drawSpecimens(context, rect)
        case "riftSection": drawRift(context, rect)
        case "mineralCabinet": drawCrystals(context, rect)
        case "volcanoObservatory": drawVolcano(context, rect)
        default: drawMagma(context, rect)
        }
        if completed {
            context.setStrokeColor(UIColor.systemGreen.cgColor)
            context.setLineWidth(4)
            context.strokeEllipse(in: rect.insetBy(dx: 5, dy: 5))
        }
    }

    private func drawSpecimens(_ context: CGContext, _ rect: CGRect) {
        context.setFillColor(UIColor(red: 0.43, green: 0.27, blue: 0.15, alpha: 1).cgColor)
        context.fill(CGRect(x: 10, y: rect.height * 0.70, width: rect.width - 20, height: 13))
        let colors: [UIColor] = [.systemBrown, UIColor(red: 0.40, green: 0.42, blue: 0.46, alpha: 1), .systemOrange]
        for index in 0..<3 {
            let x = 24 + CGFloat(index) * 48
            context.setFillColor(colors[index].cgColor)
            context.move(to: CGPoint(x: x, y: rect.height * 0.68))
            context.addLine(to: CGPoint(x: x + 12, y: rect.height * 0.37))
            context.addLine(to: CGPoint(x: x + 38, y: rect.height * 0.48))
            context.addLine(to: CGPoint(x: x + 42, y: rect.height * 0.68))
            context.closePath()
            context.fillPath()
        }
    }

    private func drawRift(_ context: CGContext, _ rect: CGRect) {
        context.setFillColor(UIColor(red: 0.48, green: 0.31, blue: 0.20, alpha: 1).cgColor)
        context.move(to: CGPoint(x: 4, y: rect.height * 0.45))
        context.addLine(to: CGPoint(x: rect.width * 0.40, y: rect.height * 0.51))
        context.addLine(to: CGPoint(x: rect.width * 0.47, y: rect.height * 0.75))
        context.addLine(to: CGPoint(x: rect.width * 0.58, y: rect.height * 0.75))
        context.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.51))
        context.addLine(to: CGPoint(x: rect.width - 4, y: rect.height * 0.43))
        context.addLine(to: CGPoint(x: rect.width - 4, y: rect.height * 0.88))
        context.addLine(to: CGPoint(x: 4, y: rect.height * 0.88))
        context.closePath()
        context.fillPath()
        drawArrow(context, from: CGPoint(x: rect.width * 0.38, y: 28), to: CGPoint(x: rect.width * 0.14, y: 28))
        drawArrow(context, from: CGPoint(x: rect.width * 0.66, y: 28), to: CGPoint(x: rect.width * 0.90, y: 28))
    }

    private func drawCrystals(_ context: CGContext, _ rect: CGRect) {
        let xs: [CGFloat] = [0.22, 0.47, 0.70]
        let heights: [CGFloat] = [0.48, 0.68, 0.54]
        for index in xs.indices {
            let x = rect.width * xs[index]
            let baseY = rect.height * 0.82
            let topY = baseY - rect.height * heights[index]
            context.setFillColor(accent.withAlphaComponent(0.72 + CGFloat(index) * 0.08).cgColor)
            context.move(to: CGPoint(x: x - 18, y: baseY))
            context.addLine(to: CGPoint(x: x - 13, y: topY + 16))
            context.addLine(to: CGPoint(x: x, y: topY))
            context.addLine(to: CGPoint(x: x + 14, y: topY + 16))
            context.addLine(to: CGPoint(x: x + 19, y: baseY))
            context.closePath()
            context.fillPath()
        }
    }

    private func drawVolcano(_ context: CGContext, _ rect: CGRect) {
        context.setFillColor(UIColor(red: 0.35, green: 0.23, blue: 0.18, alpha: 1).cgColor)
        context.move(to: CGPoint(x: 13, y: rect.height * 0.84))
        context.addLine(to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.21))
        context.addLine(to: CGPoint(x: rect.width - 13, y: rect.height * 0.84))
        context.closePath()
        context.fillPath()
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineWidth(8)
        context.move(to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.74))
        context.addLine(to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.27))
        context.strokePath()
        context.setFillColor(UIColor.white.withAlphaComponent(0.64).cgColor)
        context.fillEllipse(in: CGRect(x: rect.width * 0.35, y: 2, width: rect.width * 0.30, height: 30))
    }

    private func drawMagma(_ context: CGContext, _ rect: CGRect) {
        context.setStrokeColor(UIColor.systemOrange.cgColor)
        context.setLineWidth(19)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.82))
        context.addCurve(to: CGPoint(x: rect.width * 0.69, y: rect.height * 0.17),
                         control1: CGPoint(x: rect.width * 0.58, y: rect.height * 0.70),
                         control2: CGPoint(x: rect.width * 0.40, y: rect.height * 0.38))
        context.strokePath()
        context.setStrokeColor(UIColor.systemYellow.cgColor)
        context.setLineWidth(7)
        context.move(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.82))
        context.addCurve(to: CGPoint(x: rect.width * 0.69, y: rect.height * 0.17),
                         control1: CGPoint(x: rect.width * 0.58, y: rect.height * 0.70),
                         control2: CGPoint(x: rect.width * 0.40, y: rect.height * 0.38))
        context.strokePath()
    }

    private func drawArrow(_ context: CGContext, from: CGPoint, to: CGPoint) {
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(4)
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
        let direction: CGFloat = to.x < from.x ? -1 : 1
        context.move(to: to)
        context.addLine(to: CGPoint(x: to.x - direction * 10, y: to.y - 7))
        context.move(to: to)
        context.addLine(to: CGPoint(x: to.x - direction * 10, y: to.y + 7))
        context.strokePath()
    }
}

private final class ChallengeHubGridView: UIView {
    private let gridColor: UIColor

    init(color: UIColor) {
        gridColor = color
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(gridColor.cgColor)
        context.setLineWidth(1)
        stride(from: CGFloat(0), through: rect.width, by: 34).forEach { x in
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
        }
        stride(from: CGFloat(0), through: rect.height, by: 34).forEach { y in
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
        }
        context.strokePath()
    }
}
