//
//  LaboratoryViewController.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/2.
//

import UIKit
import SpriteKit

class LaboratoryViewController: UIViewController {

    // MARK: - 视图组件
    private var skView: SKView!
    private var labScene: LaboratoryScene!
    
    // HUD 仪表盘
    private let hudVisualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let depthLabel = UILabel()
    private let tempLabel = UILabel()
    private let pressureLabel = UILabel()
    private let densityLabel = UILabel()
    
    // 底部控制台
    private let controlVisualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    // 滑块控件
    private let densitySlider = UISlider()
    private let meltingPointSlider = UISlider()
    private let strengthSlider = UISlider()
    
    // 滑块数值标签
    private let densityValueLabel = UILabel()
    private let meltingPointValueLabel = UILabel()
    private let strengthValueLabel = UILabel()
    
    private let startBtn = UIButton(type: .system)
    private let hapticGenerator = UISelectionFeedbackGenerator()
    private let notificationHaptic = UINotificationFeedbackGenerator()
    
    // 结果弹窗
    private let resultView = UIView()
    private let resultTitleLabel = UILabel()
    private let resultMessageLabel = UILabel()
    private let retryBtn = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpriteKitView()
        setupHUD()
        setupControlPanel()
        setupResultView()
        
        // 初始更新滑块标签
        updateSliderLabels()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Setup SpriteKit
    private func setupSpriteKitView() {
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)
        
        labScene = LaboratoryScene(size: skView.bounds.size)
        labScene.scaleMode = .aspectFill
        labScene.labDelegate = self
        skView.presentScene(labScene)
    }
    
    // MARK: - Setup HUD (顶部仪表盘)
    private func setupHUD() {
        hudVisualView.layer.cornerRadius = 16
        hudVisualView.clipsToBounds = true
        hudVisualView.layer.borderWidth = 1
        hudVisualView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        hudVisualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hudVisualView)
        
        NSLayoutConstraint.activate([
            hudVisualView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            hudVisualView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hudVisualView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hudVisualView.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        let stackView = UIStackView(arrangedSubviews: [depthLabel, tempLabel, pressureLabel, densityLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        hudVisualView.contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: hudVisualView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: hudVisualView.bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: hudVisualView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: hudVisualView.trailingAnchor, constant: -20)
        ])
        
        let font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        let color = UIColor.cyan
        
        [depthLabel, tempLabel, pressureLabel, densityLabel].forEach {
            $0.font = font
            $0.textColor = color
        }
        
        // 初始文本
        didUpdateEnvironment(depth: 0, temp: 15, pressure: 0.0001, density: 2.7)
    }
    
    // MARK: - Setup Control Panel (底部控制台)
    private func setupControlPanel() {
        controlVisualView.layer.cornerRadius = 24
        controlVisualView.clipsToBounds = true
        controlVisualView.layer.borderWidth = 1
        controlVisualView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        controlVisualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlVisualView)
        
        NSLayoutConstraint.activate([
            controlVisualView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            controlVisualView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            controlVisualView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            controlVisualView.heightAnchor.constraint(equalToConstant: 280)
        ])
        
        // 1. 密度滑块
        let densityStack = createSliderRow(
            title: "样本密度",
            iconName: "scalemass.fill",
            slider: densitySlider,
            valueLabel: densityValueLabel,
            min: 1.0, max: 22.6, current: 8.0,
            tintColor: .systemBlue
        )
        
        // 2. 熔点滑块
        let meltingStack = createSliderRow(
            title: "常压熔点",
            iconName: "thermometer.sun.fill",
            slider: meltingPointSlider,
            valueLabel: meltingPointValueLabel,
            min: 0, max: 4000, current: 1500,
            tintColor: .systemRed
        )
        
        // 3. 强度滑块
        let strengthStack = createSliderRow(
            title: "抗压强度",
            iconName: "diamond.fill",
            slider: strengthSlider,
            valueLabel: strengthValueLabel,
            min: 10, max: 500, current: 100,
            tintColor: .systemPurple
        )
        
        let mainStack = UIStackView(arrangedSubviews: [densityStack, meltingStack, strengthStack])
        mainStack.axis = .vertical
        mainStack.spacing = 15
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        controlVisualView.contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: controlVisualView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: controlVisualView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: controlVisualView.trailingAnchor, constant: -20)
        ])
        
        // 投放按钮
        startBtn.setTitle("开始投放", for: .normal)
        startBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        startBtn.backgroundColor = .systemOrange
        startBtn.setTitleColor(.white, for: .normal)
        startBtn.layer.cornerRadius = 12
        startBtn.translatesAutoresizingMaskIntoConstraints = false
        startBtn.addTarget(self, action: #selector(startTest), for: .touchUpInside)
        controlVisualView.contentView.addSubview(startBtn)
        
        NSLayoutConstraint.activate([
            startBtn.bottomAnchor.constraint(equalTo: controlVisualView.bottomAnchor, constant: -20),
            startBtn.leadingAnchor.constraint(equalTo: controlVisualView.leadingAnchor, constant: 20),
            startBtn.trailingAnchor.constraint(equalTo: controlVisualView.trailingAnchor, constant: -20),
            startBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createSliderRow(title: String, iconName: String, slider: UISlider, valueLabel: UILabel, min: Float, max: Float, current: Float, tintColor: UIColor) -> UIStackView {
        
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .lightGray
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.widthAnchor.constraint(equalToConstant: 65).isActive = true
        
        valueLabel.textColor = .white
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        valueLabel.textAlignment = .right
        valueLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = current
        slider.minimumTrackTintColor = tintColor
        slider.maximumTrackTintColor = .darkGray
        
        // 自定义滑块圆点
        let thumbConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let thumbImage = UIImage(systemName: "circle.hexagongrid.fill", withConfiguration: thumbConfig)?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
        slider.setThumbImage(thumbImage, for: .normal)
        
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        let topRow = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), valueLabel])
        topRow.axis = .horizontal
        topRow.spacing = 8
        
        let stack = UIStackView(arrangedSubviews: [topRow, slider])
        stack.axis = .vertical
        stack.spacing = 5
        
        return stack
    }
    
    // MARK: - Setup Result View (结果弹窗)
    private func setupResultView() {
        resultView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        resultView.layer.cornerRadius = 20
        resultView.layer.borderWidth = 2
        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.alpha = 0 // 初始隐藏
        view.addSubview(resultView)
        
        NSLayoutConstraint.activate([
            resultView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            resultView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
        resultTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        resultTitleLabel.textAlignment = .center
        resultTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        resultView.addSubview(resultTitleLabel)
        
        resultMessageLabel.font = UIFont.systemFont(ofSize: 16)
        resultMessageLabel.textColor = .lightGray
        resultMessageLabel.textAlignment = .center
        resultMessageLabel.numberOfLines = 0
        resultMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        resultView.addSubview(resultMessageLabel)
        
        retryBtn.setTitle("重置实验", for: .normal)
        retryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        retryBtn.backgroundColor = .systemBlue
        retryBtn.setTitleColor(.white, for: .normal)
        retryBtn.layer.cornerRadius = 12
        retryBtn.translatesAutoresizingMaskIntoConstraints = false
        retryBtn.addTarget(self, action: #selector(resetTest), for: .touchUpInside)
        resultView.addSubview(retryBtn)
        
        NSLayoutConstraint.activate([
            resultTitleLabel.topAnchor.constraint(equalTo: resultView.topAnchor, constant: 20),
            resultTitleLabel.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 20),
            resultTitleLabel.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -20),
            
            resultMessageLabel.topAnchor.constraint(equalTo: resultTitleLabel.bottomAnchor, constant: 15),
            resultMessageLabel.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 20),
            resultMessageLabel.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -20),
            
            retryBtn.topAnchor.constraint(equalTo: resultMessageLabel.bottomAnchor, constant: 25),
            retryBtn.bottomAnchor.constraint(equalTo: resultView.bottomAnchor, constant: -20),
            retryBtn.centerXAnchor.constraint(equalTo: resultView.centerXAnchor),
            retryBtn.widthAnchor.constraint(equalToConstant: 150),
            retryBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        updateSliderLabels()
        // 触觉反馈 (限制频率)
        let step: Float = (sender.maximumValue - sender.minimumValue) / 20.0
        let remainder = sender.value.truncatingRemainder(dividingBy: step)
        if remainder < step * 0.1 || remainder > step * 0.9 {
            hapticGenerator.selectionChanged()
        }
    }
    
    private func updateSliderLabels() {
        densityValueLabel.text = String(format: "%.1f g/cm³", densitySlider.value)
        meltingPointValueLabel.text = String(format: "%.0f °C", meltingPointSlider.value)
        strengthValueLabel.text = String(format: "%.0f GPa", strengthSlider.value)
    }
    
    @objc private func startTest() {
        let sample = SampleData(
            density: Double(densitySlider.value),
            meltingPoint: Double(meltingPointSlider.value),
            strength: Double(strengthSlider.value)
        )
        
        // 隐藏控制台，开始实验
        UIView.animate(withDuration: 0.3) {
            self.controlVisualView.alpha = 0
            self.controlVisualView.transform = CGAffineTransform(translationX: 0, y: 50)
        }
        
        labScene.startExperiment(with: sample)
    }
    
    @objc private func resetTest() {
        // 隐藏弹窗
        UIView.animate(withDuration: 0.3) {
            self.resultView.alpha = 0
            self.resultView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            // 恢复控制台
            self.showControlPanel()
            // 重置场景
            self.labScene.resetExperiment()
        }
    }
    
    // 供实验结束后调用，恢复控制台
    func showControlPanel() {
        UIView.animate(withDuration: 0.3) {
            self.controlVisualView.alpha = 1
            self.controlVisualView.transform = .identity
        }
    }
}

// MARK: - LaboratorySceneDelegate
extension LaboratoryViewController: LaboratorySceneDelegate {
    func didUpdateEnvironment(depth: Double, temp: Double, pressure: Double, density: Double) {
        DispatchQueue.main.async {
            self.depthLabel.text    = String(format: "当前深度: %04.0f km", depth)
            self.tempLabel.text     = String(format: "环境温度: %04.0f °C", temp)
            self.pressureLabel.text = String(format: "静水压力: %06.2f GPa", pressure)
            self.densityLabel.text  = String(format: "地层密度: %04.1f g/cm³", density)
        }
    }
    
    func didFinishExperiment(success: Bool, reason: String) {
        DispatchQueue.main.async {
            // 震动反馈
            if success {
                self.notificationHaptic.notificationOccurred(.success)
                self.resultTitleLabel.text = "实验成功！"
                self.resultTitleLabel.textColor = .systemGreen
                self.resultView.layer.borderColor = UIColor.systemGreen.cgColor
            } else {
                self.notificationHaptic.notificationOccurred(.error)
                self.resultTitleLabel.text = "实验失败"
                self.resultTitleLabel.textColor = .systemRed
                self.resultView.layer.borderColor = UIColor.systemRed.cgColor
            }
            
            self.resultMessageLabel.text = reason
            
            // 显示弹窗
            self.resultView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                self.resultView.alpha = 1
                self.resultView.transform = .identity
            }
        }
    }
}
