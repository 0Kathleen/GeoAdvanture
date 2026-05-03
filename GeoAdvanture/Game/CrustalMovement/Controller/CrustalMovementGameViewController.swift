//
//  CrustalMovementGameViewController.swift
//  GeoAdvanture
//

import UIKit
import SnapKit

final class CrustalMovementGameViewController: UIViewController {

    private let viewModel = CrustMovementViewModel()
    
    // MARK: - UI Components
    
    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "closeButton"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var unlockScenesButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setBackgroundImage(UIImage(named: "mapButton"), for: .normal)
        b.setTitle("解锁场景 0/4", for: .normal)
        b.setTitleColor(UIColor(red: 0xF7/255.0, green: 0xDD/255.0, blue: 0xAA/255.0, alpha: 1.0), for: .normal)
        b.titleLabel?.font = UIFont(name: "FZZJ-QNTJW--GB1-0", size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
        b.addTarget(self, action: #selector(unlockScenesTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var unlockedScenesOverlay: CrustUnlockedScenesOverlayView = {
        let v = CrustUnlockedScenesOverlayView()
        v.delegate = self
        v.isHidden = true
        v.alpha = 0
        return v
    }()
    
    // 沉浸互动切面
    private let crossSectionView = CrustCrossSectionView()
    
    // 板块类型切换控制台
    private lazy var controlPanel: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        v.layer.cornerRadius = 12
        return v
    }()
    
    private lazy var leftTypeControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["大陆板块", "海洋板块"])
        sc.selectedSegmentIndex = 0 // 默认大陆
        sc.backgroundColor = .white
        sc.addTarget(self, action: #selector(plateTypeChanged), for: .valueChanged)
        return sc
    }()
    
    private lazy var rightTypeControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["大陆板块", "海洋板块"])
        sc.selectedSegmentIndex = 1 // 默认海洋
        sc.backgroundColor = .white
        sc.addTarget(self, action: #selector(plateTypeChanged), for: .valueChanged)
        return sc
    }()
    
    private let resultContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.alpha = 0
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(red: 0xF7/255.0, green: 0xDD/255.0, blue: 0xAA/255.0, alpha: 0.5).cgColor
        return v
    }()
    
    private let resultLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "SourceHanSerifCN-Medium", size: 15) ?? .systemFont(ofSize: 15, weight: .medium)
        l.textColor = UIColor(red: 0xF7/255.0, green: 0xDD/255.0, blue: 0xAA/255.0, alpha: 1.0)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        
        setupLayout()
        crossSectionView.delegate = self
        
        // 初始化板块形态
        plateTypeChanged()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 🟢 埋点：更新学习上下文并上报进入页面
        let context = LevelContext(
            levelId: "game_crust",
            levelName: "地壳运动探险",
            targetGoal: "通过拖拽模拟板块运动，理解碰撞与张裂如何形成山脉、海沟或裂谷。"
        )
        LearningEventBus.shared.updateContext(context)
        LearningEventBus.shared.post(action: LearningAction(type: .enterPage))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 🟢 埋点：上报离开页面，停止状态机计时
        LearningEventBus.shared.post(action: LearningAction(type: .leavePage))
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(crossSectionView)
        view.addSubview(controlPanel)
        controlPanel.addSubview(leftTypeControl)
        controlPanel.addSubview(rightTypeControl)
        view.addSubview(closeButton)
        view.addSubview(unlockScenesButton)
        view.addSubview(resultContainer)
        resultContainer.addSubview(resultLabel)
        view.addSubview(unlockedScenesOverlay)
        
        crossSectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        unlockScenesButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(62)
            make.width.equalTo(206)
        }
        
        controlPanel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
        
        leftTypeControl.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(8)
            make.width.equalTo(130)
        }
        
        rightTypeControl.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(8)
            make.width.equalTo(130)
        }
        
        resultContainer.snp.makeConstraints { make in
            make.top.equalTo(unlockScenesButton.snp.bottom).offset(12)
            make.trailing.equalTo(unlockScenesButton)
            make.width.lessThanOrEqualTo(240)
        }
        
        resultLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16))
        }
        
        unlockedScenesOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func unlockScenesTapped() {
        LearningEventBus.shared.post(action: LearningAction(type: .validInteraction(target: "查看已解锁场景")))
        unlockedScenesOverlay.isHidden = false
        unlockedScenesOverlay.display(scenes: viewModel.unlockedScenes)
        
        UIView.animate(withDuration: 0.3) {
            self.unlockedScenesOverlay.alpha = 1.0
        }
    }
    
    private func updateUnlockButtonTitle() {
        unlockScenesButton.setTitle("解锁场景 \(viewModel.unlockedCount)/4", for: .normal)
    }
    
    @objc private func plateTypeChanged() {
        // 🟢 埋点：用户正常尝试不同板块
        LearningEventBus.shared.post(action: LearningAction(type: .validInteraction(target: "切换板块类型")))
        
        // 重置互动状态
        crossSectionView.resetPlates()
        hideResultLabel()
        
        viewModel.leftPlateType = leftTypeControl.selectedSegmentIndex == 0 ? .continental : .oceanic
        viewModel.rightPlateType = rightTypeControl.selectedSegmentIndex == 0 ? .continental : .oceanic
        
        crossSectionView.updatePlateTypes(left: viewModel.leftPlateType, right: viewModel.rightPlateType)
    }
    
    private func showResultLabel(text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let attrString = NSAttributedString(string: text, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: "SourceHanSerifCN-Medium", size: 15) ?? .systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: UIColor(red: 0xF7/255.0, green: 0xDD/255.0, blue: 0xAA/255.0, alpha: 1.0)
        ])
        resultLabel.attributedText = attrString
        
        UIView.animate(withDuration: 0.3) {
            self.resultContainer.alpha = 1.0
        }
        
        // Auto hide after some time
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            self?.hideResultLabel()
        }
    }
    
    private func hideResultLabel() {
        UIView.animate(withDuration: 0.3) {
            self.resultContainer.alpha = 0
        }
    }
}

// MARK: - CrustCrossSectionViewDelegate
extension CrustalMovementGameViewController: CrustCrossSectionViewDelegate {
    
    func crossSectionView(_ view: CrustCrossSectionView, didPanWithOffset offset: CGFloat) {
        // 拖拽过程中的实时响应
    }
    
    func crossSectionViewDidEndPan(_ view: CrustCrossSectionView, finalOffset: CGFloat) {
        let result = viewModel.evaluateMovement(offset: finalOffset)
        
        let leftPlateName = viewModel.leftPlateType == .continental ? "大陆" : "大洋"
        let rightPlateName = viewModel.rightPlateType == .continental ? "大陆" : "大洋"
        
        guard result != .none else {
            // 🟢 埋点：被判定为无效或错误的交互
            LearningEventBus.shared.post(action: LearningAction(type: .error(source: leftPlateName, target: rightPlateName)))
            view.resetPlates()
            hideResultLabel()
            return
        }
        
        // 🟢 埋点：成功的有效交互
        LearningEventBus.shared.post(action: LearningAction(type: .success(source: leftPlateName, target: rightPlateName)))
        
        viewModel.unlockScene(for: result)
        updateUnlockButtonTitle()
        
        if viewModel.unlockedCount == 4 {
            LearningEventBus.shared.post(action: LearningAction(type: .success(source: "地壳探险", target: "解锁全场景")))
        }
        
        view.playFormationAnimation(result: result)

        switch result {
        case .mountain(_, let desc), .trench(_, let desc), .rift(_, let desc):
            showResultLabel(text: desc)
        case .none:
            break
        }
    }
}

// MARK: - CrustUnlockedScenesOverlayViewDelegate
extension CrustalMovementGameViewController: CrustUnlockedScenesOverlayViewDelegate {
    func unlockedScenesOverlayDidRequestClose() {
        UIView.animate(withDuration: 0.3, animations: {
            self.unlockedScenesOverlay.alpha = 0
        }) { _ in
            self.unlockedScenesOverlay.isHidden = true
        }
    }
}
