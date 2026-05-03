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
    
    private lazy var mapButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "mapButton"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        b.addTarget(self, action: #selector(mapTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        v.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideMap))
        v.addGestureRecognizer(tap)
        return v
    }()
    
    // 全局世界地图缩略图
    private let miniMapView = GlobalMapThumbnailView()
    
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
    
    private let resultLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        l.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.alpha = 0
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
        view.addSubview(mapButton)
        view.addSubview(dimmingView)
        view.addSubview(miniMapView)
        view.addSubview(resultLabel)
        
        crossSectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        mapButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(CGSize(width: 44, height: 44))
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
        
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        miniMapView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        miniMapView.isHidden = true
        miniMapView.alpha = 0
        
        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(miniMapView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.trailing.lessThanOrEqualToSuperview().inset(32)
        }
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func mapTapped() {
        if miniMapView.isHidden {
            showMap()
        } else {
            hideMap()
        }
    }
    
    @objc private func hideMap() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimmingView.alpha = 0
            self.miniMapView.alpha = 0
            self.miniMapView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.resultLabel.alpha = 0
        }) { _ in
            self.dimmingView.isHidden = true
            self.miniMapView.isHidden = true
        }
    }
    
    private func showMap() {
        dimmingView.isHidden = false
        miniMapView.isHidden = false
        miniMapView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.dimmingView.alpha = 1.0
            self.miniMapView.alpha = 1.0
            self.miniMapView.transform = .identity
        }, completion: nil)
    }
    
    @objc private func plateTypeChanged() {
        // 🟢 埋点：用户正常尝试不同板块
        LearningEventBus.shared.post(action: LearningAction(type: .validInteraction(target: "切换板块类型")))
        
        // 重置互动状态
        crossSectionView.resetPlates()
        miniMapView.resetHighlight()
        hideResultLabel()
        
        viewModel.leftPlateType = leftTypeControl.selectedSegmentIndex == 0 ? .continental : .oceanic
        viewModel.rightPlateType = rightTypeControl.selectedSegmentIndex == 0 ? .continental : .oceanic
        
        crossSectionView.updatePlateTypes(left: viewModel.leftPlateType, right: viewModel.rightPlateType)
    }
    
    private func showResultLabel(text: String) {
        resultLabel.text = " \(text) "
        UIView.animate(withDuration: 0.3) {
            self.resultLabel.alpha = 1.0
        }
    }
    
    private func hideResultLabel() {
        self.resultLabel.alpha = 0
    }
}

// MARK: - CrustCrossSectionViewDelegate
extension CrustalMovementGameViewController: CrustCrossSectionViewDelegate {
    
    func crossSectionView(_ view: CrustCrossSectionView, didPanWithOffset offset: CGFloat) {
        // 拖拽过程中的实时响应（如果需要可以做一些进度反馈）
    }
    
    func crossSectionViewDidEndPan(_ view: CrustCrossSectionView, finalOffset: CGFloat) {
        let result = viewModel.evaluateMovement(offset: finalOffset)
        
        let leftPlateName = viewModel.leftPlateType == .continental ? "大陆" : "大洋"
        let rightPlateName = viewModel.rightPlateType == .continental ? "大陆" : "大洋"
        
        guard result != .none else {
            // 未达阈值，弹回原位
            // 🟢 埋点：被判定为无效或错误的交互 (如大洋和大陆张裂等)
            LearningEventBus.shared.post(action: LearningAction(type: .error(source: leftPlateName, target: rightPlateName)))
            
            view.resetPlates()
            miniMapView.resetHighlight()
            hideResultLabel()
            return
        }
        
        // 🟢 埋点：成功的有效交互
        LearningEventBus.shared.post(action: LearningAction(type: .success(source: leftPlateName, target: rightPlateName)))
        
        view.playFormationAnimation(result: result)

        switch result {
        case .mountain(let location, let desc):
            showMap()
            miniMapView.highlightLocation(location)
            showResultLabel(text: desc)
        case .trench(let location, let desc):
            showMap()
            miniMapView.highlightLocation(location)
            showResultLabel(text: desc)
        case .rift(let location, let desc):
            showMap()
            miniMapView.highlightLocation(location)
            showResultLabel(text: desc)
        case .none:
            break
        }
    }
}
