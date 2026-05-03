//
//  LaboratoryConfigPanelView.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/2.
//

import UIKit
import SnapKit

protocol LaboratoryConfigPanelViewDelegate: AnyObject {
    func configPanelDidRequestLaunch(with sample: SampleData)
    func configPanelDidRequestBackToOverview()
}

final class LaboratoryConfigPanelView: UIVisualEffectView {
    
    weak var delegate: LaboratoryConfigPanelViewDelegate?

    // MARK: - Theme & Layout
    private enum Theme {
        static let panelCornerRadius: CGFloat = 28
        static let panelBorderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        static let panelShadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        static let titleColor = UIColor.white
        static let secondaryBodyColor = UIColor.white.withAlphaComponent(0.72)
        static let primaryButtonColor = UIColor.systemOrange
    }

    // MARK: - UI Components
    private lazy var configPanelBackgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0
        return imageView
    }()

    private lazy var configTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "调配属于自己的样本"
        label.font = .systemFont(ofSize: 22, weight: .heavy)
        label.textColor = Theme.titleColor
        return label
    }()

    private lazy var configHintLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "动动小手，左右拖拽滑块，创造一块专属于你的神奇样本！\n快来看看它能不能穿过重重考验，成功抵达地球的最深处吧！"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = Theme.secondaryBodyColor
        label.numberOfLines = 0
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let attributedString = NSMutableAttributedString(string: label.text!)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        label.attributedText = attributedString
        
        return label
    }()

    private lazy var densitySlider: UISlider = makeSlider(
        min: 1.0, max: 22.6, current: 8.0, tintColor: .systemBlue
    )

    private lazy var meltingPointSlider: UISlider = makeSlider(
        min: 0, max: 4000, current: 1500, tintColor: .systemRed
    )

    private lazy var strengthSlider: UISlider = makeSlider(
        min: 10, max: 500, current: 100, tintColor: .systemPurple
    )

    private lazy var densityValueLabel: UILabel = makeValueLabel()
    private lazy var meltingPointValueLabel: UILabel = makeValueLabel()
    private lazy var strengthValueLabel: UILabel = makeValueLabel()

    private lazy var launchButton: UIButton = makePrimaryButton(
        title: "开始投放",
        selector: #selector(startTest)
    )

    private lazy var backToOverviewButton: UIButton = makeTextButton(
        title: "返回总览",
        selector: #selector(backToOverviewTapped)
    )

    private lazy var hapticGenerator = UISelectionFeedbackGenerator()

    // MARK: - Init
    init() {
        super.init(effect: UIBlurEffect(style: .systemThinMaterialDark))
        translatesAutoresizingMaskIntoConstraints = false
        applyPanelStyle()
        setupUI()
        updateSliderLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI
    private func applyPanelStyle() {
        layer.cornerRadius = Theme.panelCornerRadius
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = Theme.panelBorderColor
        layer.shadowColor = Theme.panelShadowColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 12)
    }

    private func setupUI() {
        contentView.addSubview(configPanelBackgroundImageView)
        configPanelBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Left Side: Sliders
        let densityStack = createSliderRow(
            title: "样本密度",
            iconName: "scalemass.fill",
            slider: densitySlider,
            valueLabel: densityValueLabel
        )
        let meltingStack = createSliderRow(
            title: "常压熔点",
            iconName: "thermometer.sun.fill",
            slider: meltingPointSlider,
            valueLabel: meltingPointValueLabel
        )
        let strengthStack = createSliderRow(
            title: "抗压强度",
            iconName: "diamond.fill",
            slider: strengthSlider,
            valueLabel: strengthValueLabel
        )
        
        let leftStack = UIStackView(arrangedSubviews: [densityStack, meltingStack, strengthStack])
        leftStack.axis = .vertical
        leftStack.spacing = 24
        leftStack.distribution = .equalSpacing

        // Right Side: Info and Buttons
        let textStack = UIStackView(arrangedSubviews: [configTitleLabel, configHintLabel])
        textStack.axis = .vertical
        textStack.spacing = 16
        
        let buttonStack = UIStackView(arrangedSubviews: [launchButton, backToOverviewButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        
        let rightStack = UIStackView(arrangedSubviews: [textStack, UIView(), buttonStack])
        rightStack.axis = .vertical
        
        // Main Container
        let mainStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 40
        mainStack.distribution = .fillEqually

        contentView.addSubview(mainStack)

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(32)
        }

        launchButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }

    // MARK: - Actions
    @objc private func sliderValueChanged(_ sender: UISlider) {
        updateSliderLabels()

        let step: Float = (sender.maximumValue - sender.minimumValue) / 20.0
        let remainder = sender.value.truncatingRemainder(dividingBy: step)
        if remainder < step * 0.1 || remainder > step * 0.9 {
            hapticGenerator.selectionChanged()
        }
    }

    @objc private func startTest() {
        let sample = SampleData(
            density: Double(densitySlider.value),
            meltingPoint: Double(meltingPointSlider.value),
            strength: Double(strengthSlider.value)
        )
        delegate?.configPanelDidRequestLaunch(with: sample)
    }

    @objc private func backToOverviewTapped() {
        delegate?.configPanelDidRequestBackToOverview()
    }

    // MARK: - Helpers
    private func updateSliderLabels() {
        densityValueLabel.text = String(format: "%.1f g/cm³", densitySlider.value)
        meltingPointValueLabel.text = String(format: "%.0f °C", meltingPointSlider.value)
        strengthValueLabel.text = String(format: "%.0f GPa", strengthSlider.value)
    }

    private func makeValueLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .right
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        return label
    }

    private func makeSlider(min: Float, max: Float, current: Float, tintColor: UIColor) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = current
        slider.minimumTrackTintColor = tintColor
        slider.maximumTrackTintColor = .darkGray
        let thumbConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let thumbImage = UIImage(systemName: "circle.hexagongrid.fill", withConfiguration: thumbConfig)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)
        slider.setThumbImage(thumbImage, for: .normal)
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        return slider
    }

    private func createSliderRow(title: String, iconName: String, slider: UISlider, valueLabel: UILabel) -> UIStackView {
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = slider.minimumTrackTintColor
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .lightGray
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.widthAnchor.constraint(equalToConstant: 65).isActive = true

        let topRow = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), valueLabel])
        topRow.axis = .horizontal
        topRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [topRow, slider])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func makePrimaryButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Theme.primaryButtonColor
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    private func makeTextButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }
}
