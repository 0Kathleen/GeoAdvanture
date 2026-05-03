//
//  LaboratoryConsoleView.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/2.
//


import UIKit
import SnapKit

protocol LaboratoryConsoleViewDelegate: AnyObject {
    func consoleDidRequestConfigure()
}

class LaboratoryConsoleView: UIVisualEffectView {
    
    weak var delegate: LaboratoryConsoleViewDelegate?

    // MARK: - Theme & Layout
    private enum Theme {
        static let panelCornerRadius: CGFloat = 28
        static let panelBorderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        static let panelShadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        static let titleColor = UIColor.white
        static let bodyColor = UIColor.white.withAlphaComponent(0.88)
        static let primaryButtonColor = UIColor.systemOrange
    }

    // MARK: - UI
    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["仪表盘", "历史数据"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.3)
        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
        sc.setTitleTextAttributes(normalTextAttributes, for: .normal)
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .bold)]
        sc.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    // Content Views
    private lazy var dashboardContainer = UIView()
    private lazy var historyContainer = UIView()

    // Dashboard Items
    private lazy var depthLabel: UILabel = makeMetricLabel(title: "深度", unit: "km")
    private lazy var tempLabel: UILabel = makeMetricLabel(title: "温度", unit: "°C")
    private lazy var pressureLabel: UILabel = makeMetricLabel(title: "压力", unit: "GPa")
    private lazy var densityLabel: UILabel = makeMetricLabel(title: "环境密度", unit: "g/cm³")
    
    private lazy var configureButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("开始投放", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Theme.primaryButtonColor
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.addTarget(self, action: #selector(configureTapped), for: .touchUpInside)
        return button
    }()

    // Process & History Items
    private lazy var historyStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    // MARK: - Init
    init() {
        super.init(effect: UIBlurEffect(style: .systemThinMaterialDark))
        translatesAutoresizingMaskIntoConstraints = false
        applyPanelStyle()
        setupUI()
        updateMetrics(depth: 0, temp: 15, pressure: 0.0001, density: 2.7) // Default values
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
        contentView.addSubview(segmentedControl)
        contentView.addSubview(dashboardContainer)
        contentView.addSubview(historyContainer)

        setupDashboardUI()
        setupHistoryUI()

        segmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }

        let containers = [dashboardContainer, historyContainer]
        for container in containers {
            container.snp.makeConstraints { make in
                make.top.equalTo(segmentedControl.snp.bottom).offset(16)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }

        // Default visibility
        dashboardContainer.isHidden = false
        historyContainer.isHidden = true
    }

    private func setupDashboardUI() {
        let leftStack = UIStackView(arrangedSubviews: [depthLabel, pressureLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 20
        leftStack.distribution = .fillEqually

        let rightStack = UIStackView(arrangedSubviews: [tempLabel, densityLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 20
        rightStack.distribution = .fillEqually

        let metricsStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        metricsStack.axis = .horizontal
        metricsStack.spacing = 20
        metricsStack.distribution = .fillEqually

        dashboardContainer.addSubview(metricsStack)
        dashboardContainer.addSubview(configureButton)

        metricsStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        configureButton.snp.makeConstraints { make in
            make.top.equalTo(metricsStack.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    private func setupHistoryUI() {
        let scrollView = UIScrollView()
        historyContainer.addSubview(scrollView)
        scrollView.addSubview(historyStackView)

        let emptyLabel = makeSectionBodyLabel(text: "还没有历史记录，完成一次实验后会显示在这里。")
        emptyLabel.tag = 999
        historyStackView.addArrangedSubview(emptyLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20))
        }
        historyStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    // MARK: - Actions
    @objc private func segmentChanged() {
        dashboardContainer.isHidden = segmentedControl.selectedSegmentIndex != 0
        historyContainer.isHidden = segmentedControl.selectedSegmentIndex != 1
    }

    @objc private func configureTapped() {
        delegate?.consoleDidRequestConfigure()
    }

    // MARK: - Public
    func updateMetrics(depth: Double, temp: Double, pressure: Double, density: Double) {
        let titleColor = UIColor.white.withAlphaComponent(0.6)
        let valueColor = UIColor.white
        let titleFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let valueFont = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        let unitFont = UIFont.systemFont(ofSize: 12, weight: .medium)

        func setMetric(label: UILabel, title: String, valueStr: String, unit: String) {
            let mutableStr = NSMutableAttributedString()
            
            let titleAttr = NSAttributedString(string: title + "\n", attributes: [.foregroundColor: titleColor, .font: titleFont])
            let valueAttr = NSAttributedString(string: valueStr + " ", attributes: [.foregroundColor: valueColor, .font: valueFont])
            let unitAttr = NSAttributedString(string: unit, attributes: [.foregroundColor: titleColor, .font: unitFont])
            
            mutableStr.append(titleAttr)
            mutableStr.append(valueAttr)
            mutableStr.append(unitAttr)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            mutableStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutableStr.length))
            
            label.attributedText = mutableStr
        }

        setMetric(label: depthLabel, title: "深度", valueStr: String(format: "%.0f", depth), unit: "km")
        setMetric(label: tempLabel, title: "温度", valueStr: String(format: "%.0f", temp), unit: "°C")
        setMetric(label: pressureLabel, title: "压力", valueStr: String(format: "%.3f", pressure), unit: "GPa")
        setMetric(label: densityLabel, title: "环境密度", valueStr: String(format: "%.1f", density), unit: "g/cm³")
    }

    func appendHistoryLog(result: LaboratoryExperimentResult) {
        if let emptyLabel = historyStackView.arrangedSubviews.first(where: { $0.tag == 999 }) {
            emptyLabel.removeFromSuperview()
        }

        let cardView = UIView()
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

        let iconLabel = UILabel()
        iconLabel.text = result.outcome == .crystallized ? "✅" : "❌"
        iconLabel.font = .systemFont(ofSize: 20)

        let titleLabel = UILabel()
        titleLabel.text = result.outcome == .crystallized ? "成功到达地心" : "在\(result.reachedLayer)被摧毁"
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = result.outcome == .crystallized ? .systemGreen : .systemRed

        let descLabel = UILabel()
        descLabel.text = String(
            format: "密度:%.1f | 熔点:%.0f | 强度:%.0f\n深度: %d km\n形态: %@",
            result.sample.density, result.sample.meltingPoint, result.sample.strength,
            Int(result.reachedDepth), result.finalForm
        )
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        descLabel.numberOfLines = 0

        let headerStack = UIStackView(arrangedSubviews: [iconLabel, titleLabel, UIView()])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [headerStack, descLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 8

        cardView.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        historyStackView.insertArrangedSubview(cardView, at: 0)
    }

    // MARK: - Helpers
    private func makeMetricLabel(title: String, unit: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }

    private func makeSectionBodyLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.bodyColor
        label.numberOfLines = 0
        return label
    }
}
