//
//  LaboratoryViewController.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/2.
//

import UIKit
import SpriteKit
import SnapKit

class LaboratoryViewController: UIViewController {

    // MARK: - Types
    private enum LaboratoryPageState {
        case overview
        case config
        case falling
        case result
    }

    private enum Theme {
        static let panelCornerRadius: CGFloat = 28
        static let panelBorderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        static let panelShadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        static let titleColor = UIColor.white
        static let bodyColor = UIColor.white.withAlphaComponent(0.88)
        static let secondaryBodyColor = UIColor.white.withAlphaComponent(0.72)
        static let metricColor = UIColor.cyan
        static let primaryButtonColor = UIColor.systemOrange
        static let secondaryButtonColor = UIColor.systemBlue
    }

    private enum Layout {
        static let horizontalInset: CGFloat = 22
        static let compactInset: CGFloat = 16
        static let closeButtonSize: CGFloat = 48
        static let primaryButtonHeight: CGFloat = 50
        static let resultButtonWidth: CGFloat = 140
        static let resultButtonHeight: CGFloat = 44
        static let samplePreviewHeight: CGFloat = 62
        static let infoPanelWidth: CGFloat = 300
        static let infoPanelMinHeight: CGFloat = 180
        static let dashboardButtonSize: CGFloat = 52
    }

    // MARK: - State
    private let physicsEngine = EarthPhysicsEngine()
    private var labScene: LaboratoryScene!
    private var pageState: LaboratoryPageState = .overview
    private var currentSample: SampleData?

    // MARK: - UI
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "normalBackground"))
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var skView: SKView = {
        let view = SKView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.ignoresSiblingOrder = true
        return view
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "returnButton"), for: .normal)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var consoleView: LaboratoryConsoleView = {
        let view = LaboratoryConsoleView()
        view.delegate = self
        return view
    }()

    private lazy var configPanelView: LaboratoryConfigPanelView = {
        let view = LaboratoryConfigPanelView()
        view.delegate = self
        return view
    }()

    private lazy var resultView: LaboratoryResultView = {
        let view = LaboratoryResultView()
        view.delegate = self
        return view
    }()
    
    private lazy var hapticGenerator = UISelectionFeedbackGenerator()
    private lazy var notificationHaptic = UINotificationFeedbackGenerator()

    override var prefersStatusBarHidden: Bool {
        true
    }
    
    // MARK: - setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScene()
        setupUI()
        setupConstraints()
        setupInitialState()
        
        let context = LevelContext(
            levelId: "laboratory",
            levelName: "地心实验室",
            targetGoal: "调配不同参数的样本，观察其在地球内部的物理变化"
        )
        LearningEventBus.shared.updateContext(context)
        LearningEventBus.shared.post(action: LearningAction(type: .enterPage))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        LearningEventBus.shared.post(action: LearningAction(type: .leavePage))
    }

    private func setupScene() {
        labScene = LaboratoryScene(size: CGSize(width: 365, height: view.bounds.height))
        labScene.scaleMode = .aspectFill
        labScene.labDelegate = self
        skView.presentScene(labScene)
    }

    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(skView)
        view.addSubview(closeButton)
        view.addSubview(consoleView)
        view.addSubview(configPanelView)
        view.addSubview(resultView)
    }

    private func setupConstraints() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(22)
            make.leading.equalToSuperview().offset(24)
            make.size.equalTo(CGSize(width: Layout.closeButtonSize, height: Layout.closeButtonSize))
        }
        skView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(100)
            make.width.equalTo(380)
            make.top.bottom.equalToSuperview()
        }
        consoleView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.width.equalTo(Layout.infoPanelWidth)
        }
        configPanelView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(600)
            make.height.greaterThanOrEqualTo(320)
        }
        resultView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(600)
            make.height.greaterThanOrEqualTo(320)
        }
    }

    private func setupInitialState() {
        applyState(.overview, animated: false)
    }

    // MARK: - UI Helpers
    private func applyPanelStyle(to view: UIVisualEffectView) {
        view.layer.cornerRadius = Theme.panelCornerRadius
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.panelBorderColor
        view.layer.shadowColor = Theme.panelShadowColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 18
        view.layer.shadowOffset = CGSize(width: 0, height: 12)
    }

    // MARK: - Action
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - State
    private func applyState(_ state: LaboratoryPageState, animated: Bool) {
        pageState = state

        let updates = {
            switch state {
            case .overview:
                self.consoleView.alpha = 1
                self.configPanelView.alpha = 0
                self.configPanelView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.resultView.alpha = 0
            case .config:
                self.consoleView.alpha = 1
                self.configPanelView.alpha = 1
                self.configPanelView.transform = .identity
                self.resultView.alpha = 0
            case .falling:
                self.consoleView.alpha = 1
                self.configPanelView.alpha = 0
                self.configPanelView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.resultView.alpha = 0
            case .result:
                self.consoleView.alpha = 1
                self.configPanelView.alpha = 0
                self.resultView.alpha = 1
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.35, animations: updates)
        } else {
            updates()
        }
    }
}

// MARK: - LaboratorySceneDelegate
extension LaboratoryViewController: LaboratorySceneDelegate {
    func didUpdateEnvironment(depth: Double, temp: Double, pressure: Double, density: Double) {
        DispatchQueue.main.async {
            self.consoleView.updateMetrics(depth: depth, temp: temp, pressure: pressure, density: density)
        }
    }

    func didFinishExperiment(result: LaboratoryExperimentResult) {
        DispatchQueue.main.async {
            if result.outcome == .crystallized {
                self.notificationHaptic.notificationOccurred(.success)
                LearningEventBus.shared.post(action: LearningAction(type: .success(source: "实验室", target: "成功抵达地心")))
                LearningEventBus.shared.post(action: LearningAction(type: .stepCompleted))
            } else {
                self.notificationHaptic.notificationOccurred(.error)
                LearningEventBus.shared.post(action: LearningAction(type: .error(source: "实验室", target: "样本在\(result.reachedLayer)损毁")))
            }
            self.resultView.display(result: result)
            self.consoleView.appendHistoryLog(result: result)

            self.applyState(.result, animated: false)
            self.resultView.alpha = 0
            self.resultView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(
                withDuration: 0.5,
                delay: 0.5,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut
            ) {
                self.resultView.alpha = 1
                self.resultView.transform = .identity
            }
        }
    }
}

// MARK: - LaboratoryConfigPanelViewDelegate
extension LaboratoryViewController: LaboratoryConfigPanelViewDelegate {
    func configPanelDidRequestLaunch(with sample: SampleData) {
        LearningEventBus.shared.post(action: LearningAction(type: .validInteraction(target: "开始投放样本")))
        currentSample = sample
        applyState(.falling, animated: true)
        labScene.startExperiment(with: sample)
    }

    func configPanelDidRequestBackToOverview() {
        labScene.showOverview(animated: true)
        applyState(.overview, animated: true)
    }
}

// MARK: - LaboratoryResultViewDelegate
extension LaboratoryViewController: LaboratoryResultViewDelegate {
    func resultViewDidRequestRetry() {
        LearningEventBus.shared.post(action: LearningAction(type: .validInteraction(target: "再试一次")))
        guard let currentSample else { return }
        resultView.alpha = 0
        applyState(.falling, animated: true)
        labScene.startExperiment(with: currentSample)
    }

    func resultViewDidRequestReconfigure() {
        LearningEventBus.shared.post(action: LearningAction(type: .validInteraction(target: "重新调参")))
        labScene.resetExperiment()
        applyState(.config, animated: true)
    }
}

// MARK: - LaboratoryConsoleViewDelegate
extension LaboratoryViewController: LaboratoryConsoleViewDelegate {
    func consoleDidRequestConfigure() {
        applyState(.config, animated: true)
    }
}
