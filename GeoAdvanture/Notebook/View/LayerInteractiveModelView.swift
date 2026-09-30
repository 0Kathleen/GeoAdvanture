//
//  LayerInteractiveModelView.swift
//  GeoAdvanture
//
//  第一页左侧的可操作地球圈层模型：轻点认识圈层，左右拖动观察剖面。
//

import UIKit
import SnapKit

final class LayerInteractiveModelView: UIView {

    private let currentLayerId: String
    private let modelContainer = UIView()
    private let crustView = UIView()
    private let mantleView = UIView()
    private let outerCoreView = UIView()
    private let innerCoreView = UIView()
    private let surfaceMarker = UILabel()
    private let selectionLabel = UILabel()
    private let instructionLabel = UILabel()
    private var committedRotation: CGFloat = 0

    init(layerId: String) {
        currentLayerId = layerId
        super.init(frame: .zero)
        setupUI()
        updateSelection(layerId: layerId)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.98, green: 0.95, blue: 0.87, alpha: 0.72)
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.62, green: 0.48, blue: 0.34, alpha: 0.35).cgColor

        addSubview(modelContainer)
        modelContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 164, height: 164))
        }

        configureCircle(crustView, color: UIColor(red: 0.35, green: 0.55, blue: 0.48, alpha: 1), diameter: 156)
        configureCircle(mantleView, color: UIColor(red: 0.92, green: 0.47, blue: 0.25, alpha: 1), diameter: 132)
        configureCircle(outerCoreView, color: UIColor(red: 0.96, green: 0.70, blue: 0.22, alpha: 1), diameter: 76)
        configureCircle(innerCoreView, color: UIColor(red: 1.0, green: 0.90, blue: 0.53, alpha: 1), diameter: 38)

        surfaceMarker.text = "▲ 地表"
        surfaceMarker.font = .systemFont(ofSize: 10, weight: .bold)
        surfaceMarker.textColor = .white
        surfaceMarker.textAlignment = .center
        modelContainer.addSubview(surfaceMarker)
        surfaceMarker.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(1)
        }

        selectionLabel.numberOfLines = 2
        selectionLabel.textAlignment = .center
        selectionLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        selectionLabel.textColor = NotebookTypography.ListCell.titleColor
        addSubview(selectionLabel)
        selectionLabel.snp.makeConstraints { make in
            make.top.equalTo(modelContainer.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        instructionLabel.text = "轻点圈层查看 · 左右拖动模型"
        instructionLabel.font = .systemFont(ofSize: 10)
        instructionLabel.textColor = UIColor(white: 0.42, alpha: 1)
        instructionLabel.textAlignment = .center
        addSubview(instructionLabel)
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(selectionLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
        }

        modelContainer.isUserInteractionEnabled = true
        modelContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(modelTapped(_:))))
        modelContainer.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(modelPanned(_:))))
    }

    private func configureCircle(_ circle: UIView, color: UIColor, diameter: CGFloat) {
        circle.backgroundColor = color
        circle.layer.cornerRadius = diameter / 2
        circle.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        circle.layer.borderWidth = 1
        modelContainer.addSubview(circle)
        circle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: diameter, height: diameter))
        }
    }

    @objc private func modelTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: modelContainer)
        let center = CGPoint(x: modelContainer.bounds.midX, y: modelContainer.bounds.midY)
        let distance = hypot(point.x - center.x, point.y - center.y)
        let selected: String
        switch distance {
        case 0..<38: selected = "core"
        case 38..<66: selected = "mantle"
        case 66..<84: selected = "crust"
        default: return
        }
        updateSelection(layerId: selected)
    }

    @objc private func modelPanned(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: modelContainer)
        let angle = committedRotation + translation.x / 135
        modelContainer.transform = CGAffineTransform(rotationAngle: angle)
        if gesture.state == .ended || gesture.state == .cancelled {
            committedRotation = angle
        }
    }

    private func updateSelection(layerId: String) {
        let views: [(String, UIView)] = [
            ("crust", crustView), ("mantle", mantleView), ("core", outerCoreView)
        ]
        for (id, view) in views {
            let selected = id == layerId
            view.layer.borderWidth = selected ? 4 : 1
            view.layer.borderColor = selected
                ? UIColor.white.withAlphaComponent(0.95).cgColor
                : UIColor.white.withAlphaComponent(0.55).cgColor
        }
        innerCoreView.layer.borderWidth = layerId == "core" ? 3 : 1

        let prefix = layerId == currentLayerId ? "" : "顺便看看 · "
        switch layerId {
        case "mantle":
            selectionLabel.text = prefix + "地幔\n高温岩石能在漫长时间里缓慢变形"
        case "core":
            selectionLabel.text = prefix + "地核\n以铁、镍为主，和地球磁场密切相关"
        default:
            selectionLabel.text = prefix + "地壳\n最薄的外层，却记录着丰富的地表变化"
        }
    }
}
