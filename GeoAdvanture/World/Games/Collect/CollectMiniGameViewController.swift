//
//  CollectMiniGameViewController.swift
//  GeoAdvanture
//
//  采集小操作(通用):collect 型 POI 采集前的「动手」环节,替代直接点一下就到手。
//   - .chisel 凿击(岩石):力度指针进绿区再敲,几下凿下样本;太猛会「碎裂」回退(失败即教学)。
//   - .polish 打磨(矿物):匀速拖动打磨,太快「过热」暂停;磨到 100% 露出标本。
//  完成后只上报 ChallengeResult，由 Step 6 统一成就卡负责展示与知识入账。
//

import UIKit
import SnapKit

final class CollectMiniGameViewController: UIViewController {

    enum Mode { case chisel, polish }

    private let poi: POI
    private let collectible: Collectible?
    private let mode: Mode
    private let onFinish: (ChallengeResult?) -> Void

    // 通用 UI
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let progressLabel = UILabel()
    private let banner = UILabel()

    // 凿击
    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0
    private let gaugeTrack = UIView()
    private let gaugeGreen = UIView()
    private let gaugeRed = UIView()
    private let gaugeIndicator = UIView()
    private let strikeButton = UIButton(type: .system)
    private let rockView = UIView()
    private let chiselBackgroundLayer = CAGradientLayer()
    private var chips = 0
    private let chipsTarget = 4

    // 打磨
    private let gemView = UIView()
    private let dustOverlay = UIView()
    private let polishBackgroundLayer = CAGradientLayer()
    private var polish: CGFloat = 0

    private var finished = false
    private var mistakes = 0

    init(poi: POI, mode: Mode, onFinish: @escaping (ChallengeResult?) -> Void) {
        self.poi = poi
        self.mode = mode
        self.collectible = poi.collectibleId.flatMap { ContentStore.shared.collectible(id: $0) }
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GeoTheme.Color.darkSurface
        setupCommonHUD()
        switch mode {
        case .chisel: setupChisel()
        case .polish: setupPolish()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showTipCard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chiselBackgroundLayer.frame = view.bounds
        polishBackgroundLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: 通用 HUD

    private func setupCommonHUD() {
        closeButton.configuration = GeoTheme.buttonConfiguration(
            title: "返回探索站",
            systemImage: "chevron.left",
            style: .overlay)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        titleLabel.text = poi.title
        titleLabel.font = GeoTheme.Typography.heading(size: 20)
        titleLabel.textColor = GeoTheme.Color.lightText
        view.addSubview(titleLabel)

        instructionLabel.font = GeoTheme.Typography.body(size: 14)
        instructionLabel.textColor = GeoTheme.Color.lightText.withAlphaComponent(0.85)
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        view.addSubview(instructionLabel)

        progressLabel.font = GeoTheme.Typography.control(size: 15)
        progressLabel.textColor = .white
        progressLabel.textAlignment = .center
        view.addSubview(progressLabel)

        banner.font = GeoTheme.Typography.heading(size: 20)
        banner.textAlignment = .center
        banner.alpha = 0
        view.addSubview(banner)

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.height.equalTo(38)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
        }
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        banner.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressLabel.snp.bottom).offset(24)
        }
    }

    private func flashBanner(_ text: String, color: UIColor) {
        banner.text = text
        banner.textColor = color
        banner.alpha = 1
        banner.transform = .identity
        UIView.animate(withDuration: 0.7, animations: {
            self.banner.alpha = 0
            self.banner.transform = CGAffineTransform(translationX: 0, y: -20)
        })
    }

    // MARK: 凿击

    private func setupChisel() {
        instructionLabel.text = "力度指针进入绿区时敲击,几下把样本凿下来;红区太用力会碎裂。"

        chiselBackgroundLayer.colors = [
            UIColor(red: 0.95, green: 0.89, blue: 0.77, alpha: 1).cgColor,
            UIColor(red: 0.80, green: 0.88, blue: 0.82, alpha: 1).cgColor
        ]
        chiselBackgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        chiselBackgroundLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(chiselBackgroundLayer, at: 0)
        titleLabel.textColor = GeoTheme.Color.ink
        instructionLabel.textColor = GeoTheme.Color.inkMuted
        progressLabel.textColor = GeoTheme.Color.clay

        rockView.backgroundColor = .hex(0x6E4A2A)
        rockView.layer.cornerRadius = 16
        rockView.layer.borderWidth = 3
        rockView.layer.borderColor = UIColor.hex(0x9C6B3A).cgColor
        view.addSubview(rockView)

        gaugeTrack.backgroundColor = GeoTheme.Color.ink.withAlphaComponent(0.72)
        gaugeTrack.layer.cornerRadius = 8
        gaugeTrack.clipsToBounds = true
        view.addSubview(gaugeTrack)

        gaugeGreen.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.55)
        gaugeTrack.addSubview(gaugeGreen)
        gaugeRed.backgroundColor = UIColor.systemRed.withAlphaComponent(0.55)
        gaugeTrack.addSubview(gaugeRed)

        gaugeIndicator.backgroundColor = .white
        gaugeIndicator.layer.cornerRadius = 3
        gaugeTrack.addSubview(gaugeIndicator)

        strikeButton.setTitle("敲击", for: .normal)
        strikeButton.setTitleColor(.white, for: .normal)
        strikeButton.titleLabel?.font = GeoTheme.Typography.control(size: 19)
        strikeButton.backgroundColor = GeoTheme.Color.clay
        strikeButton.layer.cornerRadius = 40
        strikeButton.addTarget(self, action: #selector(strikeTapped), for: .touchUpInside)
        view.addSubview(strikeButton)

        rockView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.width.equalTo(160)
            make.height.equalTo(120)
        }
        gaugeTrack.snp.makeConstraints { make in
            make.top.equalTo(rockView.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(40)
            make.height.equalTo(16)
        }
        strikeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.width.height.equalTo(80)
        }

        updateChipsLabel()
    }

    private func startChiselLoop() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick() {
        phase += 0.03
        layoutGauge()
    }

    private func layoutGauge() {
        let w = gaugeTrack.bounds.width
        guard w > 0 else { return }
        // 绿区 [0.55,0.8]、红区 [0.85,1.0]
        gaugeGreen.frame = CGRect(x: w * 0.55, y: 0, width: w * 0.25, height: gaugeTrack.bounds.height)
        gaugeRed.frame = CGRect(x: w * 0.85, y: 0, width: w * 0.15, height: gaugeTrack.bounds.height)
        let v = currentGauge()
        gaugeIndicator.frame = CGRect(x: max(0, v * w - 3), y: -2, width: 6, height: gaugeTrack.bounds.height + 4)
    }

    private func currentGauge() -> CGFloat { (sin(phase) + 1) / 2 }

    @objc private func strikeTapped() {
        let v = currentGauge()
        if v >= 0.55 && v <= 0.8 {
            chips += 1
            flashBanner("好!", color: .systemGreen)
            let squash = CGAffineTransform(scaleX: 1.06, y: 0.9)
            UIView.animate(withDuration: 0.08, animations: { self.rockView.transform = squash }) { _ in
                UIView.animate(withDuration: 0.12) { self.rockView.transform = .identity }
            }
            rockView.alpha = max(0.4, 1 - CGFloat(chips) / CGFloat(chipsTarget) * 0.5)
            if chips >= chipsTarget { succeed() }
        } else if v > 0.85 {
            mistakes += 1
            chips = max(0, chips - 1)
            flashBanner("太用力,险些碎裂!", color: .systemRed)
            shakeRock()
        } else {
            flashBanner("力度不够", color: .systemYellow)
        }
        updateChipsLabel()
    }

    private func shakeRock() {
        let a = CAKeyframeAnimation(keyPath: "position.x")
        a.values = [0, 8, -8, 6, -6, 0].map { rockView.center.x + $0 }
        a.duration = 0.3
        rockView.layer.add(a, forKey: "shake")
    }

    private func updateChipsLabel() {
        progressLabel.text = "凿取进度 \(chips)/\(chipsTarget)"
    }

    // MARK: 打磨

    private func setupPolish() {
        instructionLabel.text = "在标本上来回拖动打磨,匀速最好;拖太快会过热。磨到 100% 即可采集。"

        polishBackgroundLayer.colors = [
            UIColor(red: 0.89, green: 0.84, blue: 0.96, alpha: 1).cgColor,
            UIColor(red: 0.96, green: 0.90, blue: 0.78, alpha: 1).cgColor
        ]
        polishBackgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        polishBackgroundLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(polishBackgroundLayer, at: 0)
        titleLabel.textColor = GeoTheme.Color.ink
        instructionLabel.textColor = GeoTheme.Color.inkMuted
        progressLabel.textColor = GeoTheme.Color.clay

        gemView.backgroundColor = UIColor(red: 0.48, green: 0.68, blue: 0.88, alpha: 1)
        gemView.layer.cornerRadius = 18
        gemView.transform = CGAffineTransform(rotationAngle: .pi / 4)
        view.addSubview(gemView)

        dustOverlay.backgroundColor = UIColor(red: 0.67, green: 0.63, blue: 0.68, alpha: 1)
        dustOverlay.layer.cornerRadius = 18
        view.addSubview(dustOverlay)

        gemView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(48)
            make.width.height.equalTo(140)
        }
        dustOverlay.snp.makeConstraints { make in
            make.center.equalTo(gemView)
            make.width.height.equalTo(150)
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePolishPan(_:)))
        view.addGestureRecognizer(pan)
        updatePolishLabel()
    }

    @objc private func handlePolishPan(_ gr: UIPanGestureRecognizer) {
        guard !finished else { return }
        switch gr.state {
        case .changed:
            let speed = abs(gr.velocity(in: view).x) + abs(gr.velocity(in: view).y)
            if speed > 2600 {
                mistakes += 1
                flashBanner("过热!慢一点", color: .systemRed)
                return
            }
            let d = gr.translation(in: view)
            let dist = sqrt(d.x * d.x + d.y * d.y)
            gr.setTranslation(.zero, in: view)
            polish = min(1, polish + dist / 1400)
            dustOverlay.alpha = 1 - polish
            updatePolishLabel()
            if polish >= 1 { succeed() }
        default:
            break
        }
    }

    private func updatePolishLabel() {
        progressLabel.text = "打磨进度 \(Int(polish * 100))%"
    }

    // MARK: 提示卡

    private func showTipCard() {
        let tipLines: [String]
        switch mode {
        case .chisel:
            tipLines = ["取下一份完整岩石样本。",
                        "指针进入绿色区时点击“敲击”。",
                        "避开红区；力度过大会损伤样本。"]
        case .polish:
            tipLines = ["清除岩屑，让晶体完整显露。",
                        "在晶体表面保持匀速来回拖动。",
                        "速度过快会过热，温度升高时先停一下。"]
        }
        let card = GameInfoCardView(style: .tip,
                                    title: "怎么采集:\(poi.title)",
                                    lines: tipLines,
                                    buttonTitle: "开始")
        card.onDismiss = { [weak self] in
            guard let self = self else { return }
            if self.mode == .chisel { self.startChiselLoop() }
        }
        card.present(in: view)
    }

    // MARK: 结束

    private func succeed() {
        guard !finished else { return }
        finished = true
        displayLink?.invalidate()
        displayLink = nil
        let taskId = ContentStore.shared.challengeHub(poiId: poi.id)?.taskIds.first ?? "collect_task_sample"
        let artifactIds = collectible.map { [$0.id] } ?? []
        onFinish(ChallengeResult(
            challengeId: poi.id,
            completedTaskIds: [taskId],
            observationIds: artifactIds,
            earnedArtifactIds: artifactIds,
            score: mistakes == 0 ? 3 : (mistakes <= 2 ? 2 : 1)))
    }

    @objc private func closeTapped() {
        guard !finished else { return }
        finished = true
        onFinish(nil)
    }
}
