//
//  DeepDiveLabViewController.swift
//  GeoAdvanture
//
//  地幔 operate 游戏「深潜驾驶舱」：全程用「隔热/耐压」两根滑杆把样本压在安全包络内，
//  过圈层边界有骤升事件需预判调节。抵达地心 = 成功(按最差负荷评星)，失衡 = 熔毁/压碎。
//  两根滑杆共享功率预算(和 ≤ 1.3)，逼出「顾此失彼」的权衡。
//

import UIKit
import SpriteKit
import SnapKit

final class DeepDiveLabViewController: UIViewController, OperateGameViewController {

    private let poi: POI
    private weak var gameDelegate: OperateGameDelegate?

    private let skView = SKView()
    private var scene: DeepDiveLabScene!
    private var didPresent = false

    private let closeButton = UIButton(type: .system)
    private let depthLabel = UILabel()
    private let eventBanner = UILabel()
    private let heatBar = UIProgressView(progressViewStyle: .default)
    private let stressBar = UIProgressView(progressViewStyle: .default)
    private let heatTitle = UILabel()
    private let stressTitle = UILabel()
    private let insulationSlider = UISlider()
    private let resistSlider = UISlider()
    private let insulationTitle = UILabel()
    private let resistTitle = UILabel()

    private let budgetCap: Float = 1.3

    init(poi: POI, delegate: OperateGameDelegate) {
        self.poi = poi
        self.gameDelegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)
        setupHUD()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skView.frame = view.bounds
        if !didPresent, view.bounds.width > 0 {
            didPresent = true
            scene = DeepDiveLabScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            scene.diveDelegate = self
            scene.insulation = CGFloat(insulationSlider.value)
            scene.resist = CGFloat(resistSlider.value)
            skView.presentScene(scene)
            showTipCard()   // 读完提示卡再开始下潜
        }
    }

    // MARK: 提示卡 / 知识卡

    private func showTipCard() {
        let card = GameInfoCardView(
            style: .tip,
            title: "怎么玩:深潜驾驶舱",
            lines: [
                "样本会自动向地心下沉,你负责让它活着到底。",
                "拖「🔥隔热」抵御高温,拖「🧱耐压」抵御高压。",
                "两者共享功率、不能同时拉满——按当前圈层取舍。",
                "别让热 / 压负荷条涨满;过圈层边界时环境会骤升,要提前调。"
            ],
            buttonTitle: "开始下潜")
        card.onDismiss = { [weak self] in self?.scene?.startDive() }
        card.present(in: view)
    }

    private func showKnowledgeCard(stars: Int) {
        let card = GameInfoCardView(
            style: .knowledge,
            title: "你学到了:地球的分层与极端环境",
            lines: [
                "从地壳→地幔→外核→内核,越往深处温度和压力越高。",
                "浅处高温威胁大,越深压力威胁越大——所以要动态换防。",
                "地幔是能极缓慢流动的固态岩石;外核是液态金属;内核因超高压保持固态。",
                "地球像洋葱一样分层,每层的温压条件造就了不同的状态。"
            ],
            buttonTitle: "完成",
            illustration: EarthCrossSectionDiagramView())
        card.onDismiss = { [weak self] in
            guard let self = self else { return }
            self.gameDelegate?.operateGameDidFinish(poiId: self.poi.id, success: true, stars: stars)
        }
        card.present(in: view)
    }

    // MARK: 构建

    private func setupHUD() {
        closeButton.setTitle("‹ 返回", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeButton.layer.cornerRadius = 16
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        depthLabel.font = .systemFont(ofSize: 17, weight: .bold)
        depthLabel.textColor = .white
        depthLabel.textAlignment = .center
        view.addSubview(depthLabel)

        eventBanner.font = .systemFont(ofSize: 15, weight: .bold)
        eventBanner.textColor = .systemYellow
        eventBanner.textAlignment = .center
        eventBanner.alpha = 0
        view.addSubview(eventBanner)

        configureBar(heatBar, tint: .systemOrange)
        configureBar(stressBar, tint: .systemTeal)
        configureBarTitle(heatTitle, text: "热负荷")
        configureBarTitle(stressTitle, text: "压力负荷")
        view.addSubview(heatTitle); view.addSubview(heatBar)
        view.addSubview(stressTitle); view.addSubview(stressBar)

        configureSlider(insulationSlider, value: 0.3)
        configureSlider(resistSlider, value: 0.3)
        insulationSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        resistSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        configureBarTitle(insulationTitle, text: "🔥 隔热")
        configureBarTitle(resistTitle, text: "🧱 耐压")
        view.addSubview(insulationTitle); view.addSubview(insulationSlider)
        view.addSubview(resistTitle); view.addSubview(resistSlider)

        layoutHUD()
    }

    private func configureBar(_ bar: UIProgressView, tint: UIColor) {
        bar.progressTintColor = tint
        bar.trackTintColor = UIColor(white: 0.25, alpha: 1)
        bar.progress = 0
        bar.layer.cornerRadius = 4
        bar.clipsToBounds = true
    }

    private func configureBarTitle(_ label: UILabel, text: String) {
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(white: 0.85, alpha: 1)
    }

    private func configureSlider(_ slider: UISlider, value: Float) {
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = value
    }

    private func layoutHUD() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(34)
        }
        depthLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
        }
        eventBanner.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        // 负荷条(顶部)
        heatTitle.snp.makeConstraints { make in
            make.top.equalTo(eventBanner.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(20)
        }
        heatBar.snp.makeConstraints { make in
            make.centerY.equalTo(heatTitle)
            make.leading.equalTo(heatTitle.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(10)
        }
        stressTitle.snp.makeConstraints { make in
            make.top.equalTo(heatTitle.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
        }
        stressBar.snp.makeConstraints { make in
            make.centerY.equalTo(stressTitle)
            make.leading.equalTo(stressTitle.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(10)
        }
        // 滑杆(底部)
        resistSlider.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.leading.equalToSuperview().offset(80)
            make.trailing.equalToSuperview().offset(-24)
        }
        resistTitle.snp.makeConstraints { make in
            make.centerY.equalTo(resistSlider)
            make.leading.equalToSuperview().offset(16)
        }
        insulationSlider.snp.makeConstraints { make in
            make.bottom.equalTo(resistSlider.snp.top).offset(-18)
            make.leading.equalToSuperview().offset(80)
            make.trailing.equalToSuperview().offset(-24)
        }
        insulationTitle.snp.makeConstraints { make in
            make.centerY.equalTo(insulationSlider)
            make.leading.equalToSuperview().offset(16)
        }
    }

    // MARK: 交互

    @objc private func sliderChanged(_ slider: UISlider) {
        // 功率预算:两杆之和 ≤ budgetCap，逼出权衡
        let other = (slider === insulationSlider) ? resistSlider : insulationSlider
        if slider.value + other.value > budgetCap {
            other.setValue(budgetCap - slider.value, animated: true)
        }
        scene?.insulation = CGFloat(insulationSlider.value)
        scene?.resist = CGFloat(resistSlider.value)
    }

    @objc private func closeTapped() {
        gameDelegate?.operateGameDidFinish(poiId: poi.id, success: false, stars: 0)
    }
}

// MARK: - DeepDiveLabSceneDelegate

extension DeepDiveLabViewController: DeepDiveLabSceneDelegate {

    func diveDidUpdate(_ t: DiveTelemetry) {
        depthLabel.text = "\(t.layerName)  ·  深度 \(t.depthKm) km"
        heatBar.setProgress(Float(t.heat), animated: false)
        stressBar.setProgress(Float(t.stress), animated: false)
        heatBar.progressTintColor = t.heat > 0.8 ? .systemRed : .systemOrange
        stressBar.progressTintColor = t.stress > 0.8 ? .systemRed : .systemTeal
        if let event = t.event {
            eventBanner.text = event
            if eventBanner.alpha < 1 { UIView.animate(withDuration: 0.2) { self.eventBanner.alpha = 1 } }
        } else if eventBanner.alpha > 0 {
            UIView.animate(withDuration: 0.3) { self.eventBanner.alpha = 0 }
        }
    }

    func diveDidFinish(success: Bool, reachedLayer: String, stars: Int) {
        if success {
            // 成功先弹知识卡,读完再报成功
            showKnowledgeCard(stars: stars)
            return
        }
        let alert = UIAlertController(title: "样本损毁", message: "\(reachedLayer)。调整隔热/耐压再试一次。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "再试一次", style: .default) { [weak self] _ in
            self?.restart()
        })
        alert.addAction(UIAlertAction(title: "退出", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.gameDelegate?.operateGameDidFinish(poiId: self.poi.id, success: false, stars: 0)
        })
        present(alert, animated: true)
    }

    private func restart() {
        let newScene = DeepDiveLabScene(size: view.bounds.size)
        newScene.scaleMode = .resizeFill
        newScene.diveDelegate = self
        newScene.insulation = CGFloat(insulationSlider.value)
        newScene.resist = CGFloat(resistSlider.value)
        skView.presentScene(newScene)
        scene = newScene
        newScene.startDive()
    }
}
