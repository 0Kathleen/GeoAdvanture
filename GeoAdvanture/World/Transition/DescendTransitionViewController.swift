//
//  DescendTransitionViewController.swift
//  GeoAdvanture
//
//  层间「下潜过场」(几何占位):探测舱下落 + 深度数字滚动 + 下一层名浮现。
//  真美术到位后(PR-7)把小球换成 descend_capsule 逐帧、背景换成过场插画即可,接口不变。
//

import UIKit
import SnapKit

final class DescendTransitionViewController: UIViewController {

    var onComplete: (() -> Void)?

    private let toWorld: WorldLayer
    private let fromDepthKm: Int
    private let toDepthKm: Int

    private let capsule = UIView()
    private let depthLabel = UILabel()
    private let arriveLabel = UILabel()
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private let duration: CFTimeInterval = 1.6

    init(fromTitle: String, toWorld: WorldLayer) {
        self.toWorld = toWorld
        self.fromDepthKm = Self.depthStart(of: toWorld.index)      // 上一层的深度终点
        self.toDepthKm = Self.depthStart(of: toWorld.index + 1)    // 到达层的深度终点
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        let palette = WorldPalette.forWorld(toWorld.id)
        view.backgroundColor = palette.sky

        capsule.backgroundColor = palette.player
        capsule.layer.cornerRadius = 22
        capsule.layer.borderWidth = 3
        capsule.layer.borderColor = UIColor.white.cgColor
        view.addSubview(capsule)

        depthLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        depthLabel.textColor = .white
        depthLabel.textAlignment = .center
        view.addSubview(depthLabel)

        arriveLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        arriveLabel.textColor = .white
        arriveLabel.textAlignment = .center
        arriveLabel.text = "抵达 · \(toWorld.title)"
        arriveLabel.alpha = 0
        view.addSubview(arriveLabel)

        capsule.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
            make.width.height.equalTo(44)
        }
        depthLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
        }
        arriveLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 舱体下落
        UIView.animate(withDuration: duration - 0.2, delay: 0, options: .curveEaseIn) {
            self.capsule.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height - 200)
        }
        // 层名浮现
        UIView.animate(withDuration: 0.5, delay: duration - 0.6, options: .curveEaseOut) {
            self.arriveLabel.alpha = 1
        }
        // 深度数字滚动
        startTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick() {
        let t = min(1, (CACurrentMediaTime() - startTime) / duration)
        let km = Int(Double(fromDepthKm) + Double(toDepthKm - fromDepthKm) * t)
        depthLabel.text = "深度 \(km) km"
        if t >= 1 {
            displayLink?.invalidate()
            displayLink = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.onComplete?()
            }
        }
    }

    /// 各层深度终点(km),用于过场数字滚动。
    private static func depthStart(of index: Int) -> Int {
        switch index {
        case 0: return 0
        case 1: return 35
        case 2: return 2900
        case 3: return 5100
        default: return 6371
        }
    }
}
