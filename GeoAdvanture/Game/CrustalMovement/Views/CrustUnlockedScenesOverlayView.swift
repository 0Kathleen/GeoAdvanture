//
//  CrustUnlockedScenesOverlayView.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import UIKit
import SnapKit

protocol CrustUnlockedScenesOverlayViewDelegate: AnyObject {
    func unlockedScenesOverlayDidRequestClose()
}

class CrustUnlockedScenesOverlayView: UIVisualEffectView {
    
    weak var delegate: CrustUnlockedScenesOverlayViewDelegate?
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "已解锁场景"
        l.font = UIFont(name: "FZZJ-QNTJW--GB1-0", size: 32) ?? .systemFont(ofSize: 32, weight: .bold)
        l.textColor = UIColor(red: 0xF7/255.0, green: 0xDD/255.0, blue: 0xAA/255.0, alpha: 1.0)
        l.textAlignment = .center
        return l
    }()
    
    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "closeButton"), for: .normal)
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.clipsToBounds = false
        return sv
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 24
        sv.distribution = .fillEqually
        return sv
    }()
    
    init() {
        super.init(effect: UIBlurEffect(style: .systemThinMaterialDark))
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.trailing.equalToSuperview().inset(30)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40))
            make.height.equalToSuperview()
        }
    }
    
    @objc private func closeTapped() {
        delegate?.unlockedScenesOverlayDidRequestClose()
    }
    
    func display(scenes: [CrustUnlockedScene]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for scene in scenes {
            let card = CrustSceneCardView(scene: scene)
            stackView.addArrangedSubview(card)
        }
    }
}

class CrustSceneCardView: UIView {
    
    init(scene: CrustUnlockedScene) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        layer.cornerRadius = 16
        clipsToBounds = true
        
        let imgStack = UIStackView()
        imgStack.axis = .horizontal
        imgStack.spacing = 8
        imgStack.distribution = .fillEqually
        
        let imgView1 = UIImageView()
        imgView1.contentMode = .scaleAspectFill
        imgView1.clipsToBounds = true
        
        let imgView2 = UIImageView()
        imgView2.contentMode = .scaleAspectFill
        imgView2.clipsToBounds = true
        
        imgStack.addArrangedSubview(imgView1)
        imgStack.addArrangedSubview(imgView2)
        
        let titleLbl = UILabel()
        titleLbl.text = scene.title
        titleLbl.font = UIFont(name: "FZZJ-QNTJW--GB1-0", size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
        titleLbl.textColor = .white
        titleLbl.textAlignment = .center
        
        let descLbl = UILabel()
        descLbl.text = scene.description + "\n\n代表现实位置：" + scene.location
        descLbl.font = UIFont(name: "SourceHanSerifCN-Medium", size: 16) ?? .systemFont(ofSize: 14)
        descLbl.textColor = UIColor.white.withAlphaComponent(0.8)
        descLbl.numberOfLines = 0
        
        let lockOverlay = UIView()
        lockOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        lockIcon.tintColor = .white
        lockOverlay.addSubview(lockIcon)
        lockIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
        
        addSubview(imgStack)
        addSubview(titleLbl)
        addSubview(descLbl)
        addSubview(lockOverlay)
        
        self.snp.makeConstraints { make in
            make.width.equalTo(340)
        }
        
        imgStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(140)
        }
        
        titleLbl.snp.makeConstraints { make in
            make.top.equalTo(imgStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        descLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
        
        lockOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if scene.isUnlocked {
            imgView1.image = UIImage(named: scene.imageName) ?? UIImage(named: "岩浆") // Fallback
            imgView2.image = UIImage(named: scene.realImageName) ?? UIImage(named: "岩浆") // Fallback
            lockOverlay.isHidden = true
        } else {
            imgView1.backgroundColor = .darkGray
            imgView2.backgroundColor = .darkGray
            lockOverlay.isHidden = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
