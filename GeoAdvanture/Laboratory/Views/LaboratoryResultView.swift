//
//  LaboratoryResultView.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/2.
//

import UIKit
import SnapKit

protocol LaboratoryResultViewDelegate: AnyObject {
    func resultViewDidRequestRetry()
    func resultViewDidRequestReconfigure()
}

final class LaboratoryResultView: UIVisualEffectView {
    
    weak var delegate: LaboratoryResultViewDelegate?

    // MARK: - Theme & Layout
    private enum Theme {
        static let panelCornerRadius: CGFloat = 28
        static let panelBorderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        static let panelShadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        static let titleColor = UIColor.white
        static let primaryButtonColor = UIColor.systemOrange
        static let secondaryButtonColor = UIColor.systemBlue
        /// 左侧「到达位置 / 最终形态」区域固定高度，避免被右侧整体拉高后两行之间被撑开
        static let detailLeftStackHeight: CGFloat = 148
    }

    // MARK: - UI Components
    private lazy var resultPanelBackgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0
        return imageView
    }()

    private lazy var resultTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .heavy)
        label.textAlignment = .left
        return label
    }()

    private lazy var resultParameterLabel: UILabel = makeResultLabel()
    private lazy var resultReachedLabel: UILabel = makeResultLabel()
    private lazy var resultFinalLabel: UILabel = makeResultLabel()

    private lazy var retryBtn: UIButton = makePrimaryButton(
        title: "再试一次",
        selector: #selector(retryCurrentSample)
    )

    private lazy var reconfigureBtn: UIButton = makeTextButton(
        title: "重新调参",
        selector: #selector(resetTest)
    )

    // MARK: - Init
    init() {
        super.init(effect: UIBlurEffect(style: .systemThinMaterialDark))
        translatesAutoresizingMaskIntoConstraints = false
        applyPanelStyle()
        setupUI()
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
        contentView.addSubview(resultPanelBackgroundImageView)
        resultPanelBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Left Side: Process Details
        let detailStack = UIStackView(arrangedSubviews: [resultReachedLabel, resultFinalLabel])
        detailStack.axis = .vertical
        detailStack.spacing = 6
        detailStack.alignment = .fill
        detailStack.distribution = .fill

        // Right Side: Title, Parameters, Actions
        let titleStack = UIStackView(arrangedSubviews: [resultTitleLabel, resultParameterLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 16
        
        let buttonStack = UIStackView(arrangedSubviews: [retryBtn, reconfigureBtn])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        
        let rightStack = UIStackView(arrangedSubviews: [titleStack, buttonStack, UIView()])
        rightStack.axis = .vertical
        rightStack.spacing = 30
        
        // Main Container
        let mainStack = UIStackView(arrangedSubviews: [detailStack, rightStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 40
        mainStack.distribution = .fillEqually
        mainStack.alignment = .top

        contentView.addSubview(mainStack)

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(32)
        }

        detailStack.snp.makeConstraints { make in
            make.height.equalTo(Theme.detailLeftStackHeight)
        }

        retryBtn.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }

    // MARK: - Public
    func display(result: LaboratoryExperimentResult) {
        switch result.outcome {
        case .crystallized:
            resultTitleLabel.text = "🎉 实验成功！"
            resultTitleLabel.textColor = .systemGreen
            layer.borderColor = UIColor.systemGreen.cgColor
            
            resultParameterLabel.text = String(
                format: "使用参数\n密度 %.1f g/cm³\n熔点 %.0f °C\n强度 %.0f GPa",
                result.sample.density,
                result.sample.meltingPoint,
                result.sample.strength
            )
        default:
            resultTitleLabel.text = "💥 实验失败"
            resultTitleLabel.textColor = .systemRed
            layer.borderColor = UIColor.systemRed.cgColor
            
            let hint: String
            if result.finalForm.contains("熔化") || result.finalForm.contains("液态") {
                hint = "哎呀！这里太热啦，你的样本像冰淇淋一样化掉了 \n\n💡 小贴士：试着把【熔点】调高一点点，让它更耐热吧！"
            } else if result.finalForm.contains("碎") || result.finalForm.contains("破裂") {
                hint = "砰！这里的压力太大了，你的样本被压得粉碎 \n\n💡 小贴士：试着增加【强度】，让它变得更坚固！"
            } else if result.finalForm.contains("停滞") || result.finalForm.contains("悬浮") || result.finalForm.contains("之上") {
                hint = "哎呀被卡住了！下面的岩浆太稠密，你的样本挤不进去 \n\n💡 小贴士：试着把【密度】调大一点，让它变得更重更结实！"
            } else {
                hint = "哎呀，差一点点就成功了！地球内部的环境真是太厉害了 \n\n💡 小贴士：重新调整一下参数，再挑战一次吧！"
            }
            resultParameterLabel.text = hint
        }

        func makeHighlightString(title: String, value: String) -> NSAttributedString {
            let titleAttr = NSAttributedString(
                string: title,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.88)
                ]
            )
            let valueAttr = NSAttributedString(
                string: value,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.systemOrange
                ]
            )
            let combined = NSMutableAttributedString()
            combined.append(titleAttr)
            combined.append(valueAttr)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            combined.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: combined.length))
            
            return combined
        }

        resultReachedLabel.attributedText = makeHighlightString(title: "到达位置：\n", value: "\(result.reachedLayer) (约 \(Int(result.reachedDepth)) km)")
        resultFinalLabel.attributedText = makeHighlightString(title: "最终形态：\n", value: result.finalForm)
    }

    // MARK: - Actions
    @objc private func retryCurrentSample() {
        delegate?.resultViewDidRequestRetry()
    }

    @objc private func resetTest() {
        delegate?.resultViewDidRequestReconfigure()
    }

    // MARK: - Helpers
    private func makeResultLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.88)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
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
