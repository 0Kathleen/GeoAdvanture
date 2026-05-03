//
//  LaboratoryIntroViewController.swift
//  GeoAdvanture
//

import UIKit
import SnapKit

class LaboratoryIntroViewController: UIViewController {

    // MARK: - UI
    private enum Layout {
        static let backgroundTop = 20
        static let backgroundLeading = 84
        static let backgroundTrailing = 68
        static let backgroundBottom = 17

        static let introTop = 188
        static let introLeading = 336
        static let introTrailing = 163

        static let buttonTop = 24
        static let buttonLeading = 248
        static let buttonTrailing = 315
        static let buttonWidth = 160
        static let buttonHeight = 45
    }
    
    private lazy var bottomBackgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "normalBackground"))
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "returnButton"), for: .normal)
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "LaborIntroBackground"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var introLabel: UILabel = {
        let label = UILabel()
        label.text = """
        你将收获：
        1. 认识高温、高压下物质的不同表现
        2. 理解地幔、外核、内核的环境差异
        3. 通过实验结果建立更直观的地层认知
        """
        label.font = UIFont(name: "SourceHanSerifCN-Medium", size: 16) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var enterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "titleBubble"), for: .normal)
        button.setTitle("开始锻造", for: .normal)
        button.titleLabel?.font = NotebookTypography.topTitleFont(size: 24)
        button.setTitleColor(UIColor(red: 0x52/255, green: 0x38/255, blue: 0x36/255, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(enterTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(bottomBackgroundImageView)
        view.addSubview(contentView)
        view.addSubview(closeButton)
        
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(introLabel)
        contentView.addSubview(enterButton)

        bottomBackgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(22)
            make.leading.equalToSuperview().offset(24)
            make.size.equalTo(CGSize(width: 48, height: 48))
        }
        contentView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.backgroundTop)
            make.leading.equalToSuperview().offset(Layout.backgroundLeading)
            make.trailing.equalToSuperview().offset(-Layout.backgroundTrailing)
            make.bottom.equalToSuperview().offset(-Layout.backgroundBottom)
        }
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        introLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.introTop)
            make.leading.equalToSuperview().offset(Layout.introLeading)
        }
        enterButton.snp.makeConstraints { make in
            make.top.equalTo(introLabel.snp.bottom).offset(Layout.buttonTop)
            make.leading.equalToSuperview().offset(Layout.buttonLeading)
            make.width.equalTo(Layout.buttonWidth)
            make.height.equalTo(Layout.buttonHeight)
        }
    }
    
    // MARK: - Action
    @objc private func enterTapped() {
        let labVC = LaboratoryViewController()
        labVC.modalPresentationStyle = .fullScreen
        labVC.modalTransitionStyle = .crossDissolve
        present(labVC, animated: true, completion: nil)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}
