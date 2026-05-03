//
//  CrustCrossSectionView.swift
//  GeoAdvanture
//

import UIKit
import SnapKit

protocol CrustCrossSectionViewDelegate: AnyObject {
    func crossSectionView(_ view: CrustCrossSectionView, didPanWithOffset offset: CGFloat)
    func crossSectionViewDidEndPan(_ view: CrustCrossSectionView, finalOffset: CGFloat)
}

final class CrustCrossSectionView: UIView {
    
    weak var delegate: CrustCrossSectionViewDelegate?
    
    // MARK: - Views
    private let skyBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        return v
    }()
    
    private let mantleBackgroundView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(named: "岩浆")
        v.contentMode = .scaleToFill
        v.clipsToBounds = true
        return v
    }()
    
    private let formationResultImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        v.clipsToBounds = false
        v.alpha = 0 // 默认隐藏
        return v
    }()
    
    // 左板块（图片）
    let leftPlateImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        v.clipsToBounds = false
        return v
    }()
    
    // 右板块（图片）
    let rightPlateImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        v.clipsToBounds = false
        return v
    }()
    
    // 把手和提示
    private let leftHandle: UIImageView = {
        let v = UIImageView(image: UIImage(named: "dragButton"))
        v.contentMode = .scaleAspectFit
        v.isUserInteractionEnabled = true
        return v
    }()
    
    private let rightHandle: UIImageView = {
        let v = UIImageView(image: UIImage(named: "dragButton"))
        v.contentMode = .scaleAspectFit
        v.isUserInteractionEnabled = true
        return v
    }()
    
    private let infoLabel: UILabel = {
        let l = UILabel()
        l.text = "横向拖拽把手模拟板块运动"
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowOpacity = 0.5
        l.layer.shadowOffset = CGSize(width: 1, height: 1)
        l.layer.shadowRadius = 2
        l.textAlignment = .center
        return l
    }()
    
    // MARK: - State
    private var currentOffset: CGFloat = 0
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private var isLeftContinental = true
    private var isRightContinental = false
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        clipsToBounds = true
        addSubview(skyBackgroundView)
        addSubview(mantleBackgroundView)
        addSubview(rightPlateImageView)
        addSubview(leftPlateImageView)
        addSubview(formationResultImageView)
        addSubview(leftHandle)
        addSubview(rightHandle)
        addSubview(infoLabel)
        
        skyBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.75)
        }
        
        mantleBackgroundView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.25)
        }
        
        leftPlateImageView.snp.makeConstraints { make in
            make.bottom.equalTo(mantleBackgroundView.snp.top).offset(80)
            make.leading.equalToSuperview()
            make.trailing.equalTo(self.snp.centerX)
            make.height.equalTo(220)
        }
        
        rightPlateImageView.snp.makeConstraints { make in
            make.bottom.equalTo(mantleBackgroundView.snp.top).offset(80)
            make.leading.equalTo(self.snp.centerX)
            make.trailing.equalToSuperview()
            make.height.equalTo(220)
        }
        
        leftHandle.snp.makeConstraints { make in
            make.centerX.equalTo(leftPlateImageView)
            make.top.equalTo(mantleBackgroundView.snp.top).offset(20)
            make.size.equalTo(CGSize(width: 60, height: 40))
        }
        
        rightHandle.snp.makeConstraints { make in
            make.centerX.equalTo(rightPlateImageView)
            make.top.equalTo(mantleBackgroundView.snp.top).offset(20)
            make.size.equalTo(CGSize(width: 60, height: 40))
        }
        
        formationResultImageView.snp.makeConstraints { make in
            make.bottom.equalTo(mantleBackgroundView.snp.top).offset(80)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(260)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
        
        // 默认应用一次图片
        updatePlateImages()
    }
    
    private func setupGestures() {
        let leftPan = UIPanGestureRecognizer(target: self, action: #selector(handleLeftPan(_:)))
        leftHandle.addGestureRecognizer(leftPan)
        
        let rightPan = UIPanGestureRecognizer(target: self, action: #selector(handleRightPan(_:)))
        rightHandle.addGestureRecognizer(rightPan)
    }
    
    // MARK: - Actions
    @objc private func handleLeftPan(_ gesture: UIPanGestureRecognizer) {
        processPan(gesture, isLeft: true)
    }
    
    @objc private func handleRightPan(_ gesture: UIPanGestureRecognizer) {
        processPan(gesture, isLeft: false)
    }
    
    private func processPan(_ gesture: UIPanGestureRecognizer, isLeft: Bool) {
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            hapticGenerator.prepare()
            
        case .changed:
            if isLeft {
                currentOffset = -translation.x
            } else {
                currentOffset = translation.x
            }
            
            // 实时跟随拖拽，做平移
            let shift = -currentOffset
            leftPlateImageView.transform = CGAffineTransform(translationX: shift, y: 0)
            rightPlateImageView.transform = CGAffineTransform(translationX: -shift, y: 0)
            
            delegate?.crossSectionView(self, didPanWithOffset: currentOffset)
            
        case .ended, .cancelled:
            delegate?.crossSectionViewDidEndPan(self, finalOffset: currentOffset)
            hapticGenerator.impactOccurred()
            
        default:
            break
        }
    }
    
    // MARK: - Public
    func resetPlates() {
        self.currentOffset = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.leftPlateImageView.transform = .identity
            self.rightPlateImageView.transform = .identity
            
            // 恢复板块图显示并隐藏结果图
            self.leftPlateImageView.alpha = 1.0
            self.rightPlateImageView.alpha = 1.0
            self.formationResultImageView.alpha = 0
            self.formationResultImageView.transform = .identity
        }, completion: nil)
    }
    
    func playFormationAnimation(result: GeologyFormationResult) {
        // 在开始新动画前重置结果图的显示状态
        formationResultImageView.alpha = 0
        formationResultImageView.transform = .identity
        
        UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseOut], animations: {
            switch result {
            case .mountain:
                // 对于造山运动，当都是大陆板块时显示「山脉」图片
                if self.isLeftContinental && self.isRightContinental {
                    self.formationResultImageView.image = UIImage(named: "山脉")
                    self.leftPlateImageView.alpha = 0
                    self.rightPlateImageView.alpha = 0
                    self.formationResultImageView.alpha = 1.0
                    // 给山脉图片加个一点点向上的弹性动画感
                    self.formationResultImageView.transform = CGAffineTransform(translationX: 0, y: -20)
                } else {
                    // 其他情况的回退形变
                    self.leftPlateImageView.transform = CGAffineTransform(translationX: -self.currentOffset, y: -20)
                        .concatenating(CGAffineTransform(scaleX: 1.0, y: 1.3))
                    self.rightPlateImageView.transform = CGAffineTransform(translationX: self.currentOffset, y: -20)
                        .concatenating(CGAffineTransform(scaleX: 1.0, y: 1.3))
                }
                
            case .trench:
                // 俯冲：一方发生旋转下沉
                if self.isLeftContinental && !self.isRightContinental {
                    self.leftPlateImageView.transform = CGAffineTransform(translationX: -self.currentOffset, y: -10)
                        .concatenating(CGAffineTransform(scaleX: 1.0, y: 1.1))
                    // 海洋俯冲
                    self.rightPlateImageView.transform = CGAffineTransform(translationX: self.currentOffset, y: 20)
                        .concatenating(CGAffineTransform(rotationAngle: -0.15))
                } else if !self.isLeftContinental && self.isRightContinental {
                    self.leftPlateImageView.transform = CGAffineTransform(translationX: -self.currentOffset, y: 20)
                        .concatenating(CGAffineTransform(rotationAngle: 0.15))
                    self.rightPlateImageView.transform = CGAffineTransform(translationX: self.currentOffset, y: -10)
                        .concatenating(CGAffineTransform(scaleX: 1.0, y: 1.1))
                } else {
                    self.rightPlateImageView.transform = CGAffineTransform(translationX: self.currentOffset, y: 20)
                        .concatenating(CGAffineTransform(rotationAngle: -0.15))
                }
                
            case .rift:
                // 拉伸裂谷：当都是大陆板块拉开时，在中间渐显「裂谷」图片
                if self.isLeftContinental && self.isRightContinental {
                    self.formationResultImageView.image = UIImage(named: "裂谷")
                    self.leftPlateImageView.alpha = 0
                    self.rightPlateImageView.alpha = 0
                    self.formationResultImageView.alpha = 1.0
                } else {
                    // 简单的互相平移拉远
                    self.leftPlateImageView.transform = CGAffineTransform(translationX: -self.currentOffset, y: 0)
                    self.rightPlateImageView.transform = CGAffineTransform(translationX: self.currentOffset, y: 0)
                }
                
            case .none:
                self.leftPlateImageView.transform = .identity
                self.rightPlateImageView.transform = .identity
            }
        }, completion: { _ in
            if case .mountain = result, self.isLeftContinental, self.isRightContinental {
                UIView.animate(withDuration: 0.3) {
                    self.formationResultImageView.transform = .identity
                }
            }
        })
    }
    
    func updatePlateTypes(left: CrustPlateType, right: CrustPlateType) {
        self.isLeftContinental = (left == .continental)
        self.isRightContinental = (right == .continental)
        
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.updatePlateImages()
        }, completion: nil)
    }
    
    private func updatePlateImages() {
        leftPlateImageView.image = UIImage(named: isLeftContinental ? "大陆板块" : "海洋板块")
        rightPlateImageView.image = UIImage(named: isRightContinental ? "大陆板块" : "海洋板块")
        
        
        
        leftPlateImageView.snp.updateConstraints { make in
            make.height.equalTo(isLeftContinental ? 260 : 180)
        }
        rightPlateImageView.snp.updateConstraints { make in
            make.height.equalTo(isRightContinental ? 260 : 180)
        }
        layoutIfNeeded()
    }
}
