//
//  HomeModelDebugPanel.swift
//  GeoAdvanture
//
//  仅在 Debug 构建中使用的首页模型实时调参面板。
//

import UIKit
import SceneKit

struct HomeModelDebugValues {
    var position: SCNVector3
    var rotationDegrees: SCNVector3
    var scale: Float
}

final class HomeModelDebugPanel: UIView {
    var onLayerChanged: ((HomeLayer) -> Void)?
    var onStageChanged: ((Bool) -> Void)?
    var onValuesChanged: ((HomeModelDebugValues) -> Void)?
    var onReset: (() -> Void)?
    var onCopy: (() -> Void)?

    private enum Field: Int, CaseIterable {
        case rotationX, rotationY, rotationZ, positionX, positionY, scale

        var title: String {
            switch self {
            case .rotationX: return "角度 X"
            case .rotationY: return "角度 Y"
            case .rotationZ: return "角度 Z"
            case .positionX: return "位置 X"
            case .positionY: return "位置 Y"
            case .scale: return "模型大小"
            }
        }

        var range: ClosedRange<Float> {
            switch self {
            case .rotationX, .rotationY, .rotationZ: return -180...180
            case .positionX: return -3.2...3.2
            case .positionY: return -1.8...1.8
            case .scale: return 0.2...5.0
            }
        }
    }

    private let layerControl = UISegmentedControl(items: HomeLayer.allCases.map(\.title))
    private let stageControl = UISegmentedControl(items: ["合拢", "展开"])
    private let statusLabel = UILabel()
    private let scrollView = UIScrollView()
    private var sliders: [Field: UISlider] = [:]
    private var valueLabels: [Field: UILabel] = [:]
    private var isSynchronizing = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func setValues(_ values: HomeModelDebugValues) {
        isSynchronizing = true
        set(values.rotationDegrees.x, for: .rotationX)
        set(values.rotationDegrees.y, for: .rotationY)
        set(values.rotationDegrees.z, for: .rotationZ)
        set(values.position.x, for: .positionX)
        set(values.position.y, for: .positionY)
        set(values.scale, for: .scale)
        isSynchronizing = false
    }

    func setStageExpanded(_ expanded: Bool) {
        stageControl.selectedSegmentIndex = expanded ? 1 : 0
    }

    func showCopiedFeedback() {
        statusLabel.text = "参数已复制，也已打印到控制台"
    }

    private func configure() {
        backgroundColor = UIColor(white: 0.07, alpha: 0.90)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor

        let title = UILabel()
        title.text = "首页模型调试"
        title.textColor = .white
        title.font = .systemFont(ofSize: 16, weight: .bold)

        layerControl.selectedSegmentIndex = 0
        layerControl.addTarget(self, action: #selector(layerChanged), for: .valueChanged)
        stageControl.selectedSegmentIndex = 0
        stageControl.addTarget(self, action: #selector(stageChanged), for: .valueChanged)

        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, layerControl, stageControl])
        stack.axis = .vertical
        stack.spacing = 5
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for field in Field.allCases {
            stack.addArrangedSubview(makeRow(for: field))
        }

        let resetButton = makeButton(title: "恢复当前层", action: #selector(resetTapped))
        let copyButton = makeButton(title: "复制参数", action: #selector(copyTapped))
        let buttonRow = UIStackView(arrangedSubviews: [resetButton, copyButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 8
        stack.addArrangedSubview(buttonRow)

        statusLabel.text = "滑动后实时生效"
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textAlignment = .center
        stack.addArrangedSubview(statusLabel)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -10),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24)
        ])
    }

    private func makeRow(for field: Field) -> UIView {
        let name = UILabel()
        name.text = field.title
        name.textColor = UIColor.white.withAlphaComponent(0.84)
        name.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        name.widthAnchor.constraint(equalToConstant: 62).isActive = true

        let slider = UISlider()
        slider.minimumValue = field.range.lowerBound
        slider.maximumValue = field.range.upperBound
        slider.tag = field.rawValue
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        sliders[field] = slider

        let value = UILabel()
        value.textColor = .white
        value.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        value.textAlignment = .right
        value.widthAnchor.constraint(equalToConstant: 50).isActive = true
        valueLabels[field] = value

        let row = UIStackView(arrangedSubviews: [name, slider, value])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 7
        row.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return row
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func set(_ value: Float, for field: Field) {
        sliders[field]?.value = value
        updateValueLabel(for: field, value: value)
    }

    private func updateValueLabel(for field: Field, value: Float) {
        let format = field == .scale ? "%.2f" : "%.1f"
        valueLabels[field]?.text = String(format: format, value)
    }

    private func currentValues() -> HomeModelDebugValues {
        HomeModelDebugValues(
            position: SCNVector3(value(of: .positionX), value(of: .positionY), 0),
            rotationDegrees: SCNVector3(
                value(of: .rotationX), value(of: .rotationY), value(of: .rotationZ)),
            scale: value(of: .scale))
    }

    private func value(of field: Field) -> Float {
        sliders[field]?.value ?? 0
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        guard let field = Field(rawValue: sender.tag) else { return }
        updateValueLabel(for: field, value: sender.value)
        statusLabel.text = "滑动后实时生效"
        if !isSynchronizing {
            onValuesChanged?(currentValues())
        }
    }

    @objc private func layerChanged() {
        guard HomeLayer.allCases.indices.contains(layerControl.selectedSegmentIndex) else { return }
        onLayerChanged?(HomeLayer.allCases[layerControl.selectedSegmentIndex])
    }

    @objc private func stageChanged() {
        onStageChanged?(stageControl.selectedSegmentIndex == 1)
    }

    @objc private func resetTapped() {
        onReset?()
    }

    @objc private func copyTapped() {
        onCopy?()
    }
}
