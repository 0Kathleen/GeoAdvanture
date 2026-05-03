//
//  MedalViewController.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/3.
//

import UIKit
import SnapKit

class MedalViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "我的奖章"
        l.font = UIFont(name: "FZZJ-QNTJW--GB1-0", size: 32) ?? .systemFont(ofSize: 32, weight: .bold)
        l.textColor = UIColor(red: 0x52/255, green: 0x38/255, blue: 0x36/255, alpha: 1)
        l.textAlignment = .center
        return l
    }()
    
    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "returnButton") ?? UIImage(systemName: "xmark.circle.fill"), for: .normal)
        b.tintColor = .darkGray
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 24
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 32, bottom: 40, right: 32)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.showsVerticalScrollIndicator = false
        cv.register(MedalCell.self, forCellWithReuseIdentifier: "MedalCell")
        return cv
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "normalBackground"))
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(collectionView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(22)
            make.leading.equalToSuperview().offset(24)
            make.size.equalTo(CGSize(width: 48, height: 48))
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension MedalViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MedalManager.shared.medals.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MedalCell", for: indexPath) as! MedalCell
        let medal = MedalManager.shared.medals[indexPath.item]
        cell.configure(with: medal)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 卡片大小，屏幕宽的一半减去间距
        let width = (collectionView.bounds.width - 64 - 24) / 2
        return CGSize(width: width, height: 140)
    }
}

class MedalCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 8
        return v
    }()
    
    private let medalImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.clipsToBounds = true
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "FZZJ-QNTJW--GB1-0", size: 20) ?? .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(red: 0x52/255, green: 0x38/255, blue: 0x36/255, alpha: 1)
        return l
    }()
    
    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "SourceHanSerifCN-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(red: 0x83/255, green: 0x69/255, blue: 0x66/255, alpha: 1)
        l.numberOfLines = 0
        return l
    }()
    
    private let lockIcon: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "lock.fill"))
        v.tintColor = .lightGray
        v.contentMode = .scaleAspectFit
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(medalImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descLabel)
        containerView.addSubview(lockIcon)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        medalImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalTo(medalImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
        
        lockIcon.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(16)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }
    
    func configure(with medal: MedalModel) {
        titleLabel.text = medal.name
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        descLabel.attributedText = NSAttributedString(string: medal.description, attributes: [
            .paragraphStyle: paragraphStyle
        ])
        
        if medal.isUnlocked {
            medalImageView.image = UIImage(named: medal.imageName)?.withRenderingMode(.alwaysOriginal) ?? UIImage(systemName: "seal.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            lockIcon.isHidden = true
            medalImageView.alpha = 1.0
            containerView.alpha = 1.0
        } else {
            medalImageView.image = UIImage(named: medal.imageName)?.withRenderingMode(.alwaysTemplate) ?? UIImage(systemName: "seal")
            medalImageView.tintColor = .lightGray
            lockIcon.isHidden = false
            medalImageView.alpha = 0.3
            containerView.alpha = 0.7
        }
    }
}
