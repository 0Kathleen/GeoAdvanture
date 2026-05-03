//
//  NotebookMapViewController.swift
//  GeoAdvanture
//

import UIKit
import SnapKit

final class NotebookMapViewController: UIViewController {

    private let viewModel: NotebookViewModel
    
    // MARK: - UI
    private let mapImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "curstMap"))
        v.contentMode = .scaleAspectFit
        v.isUserInteractionEnabled = true
        return v
    }()
    
    private lazy var rockBtn: UIButton = createMapButton(imageName: "map_rock", action: #selector(rockTapped))
    private lazy var movementBtn: UIButton = createMapButton(imageName: "map_movement", action: #selector(movementTapped))
    private lazy var crackBtn: UIButton = createMapButton(imageName: "map_crack", action: nil)
    private lazy var diamondBtn: UIButton = createMapButton(imageName: "map_diamond", action: nil)
    private lazy var volcanoBtn: UIButton = createMapButton(imageName: "map_valcano", action: nil)
    private lazy var lavaBtn: UIButton = createMapButton(imageName: "map_lava", action: nil)
    
    // MARK: - Lifecycle
    init(viewModel: NotebookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(mapImageView)
        
        mapImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        mapImageView.addSubview(rockBtn)
        mapImageView.addSubview(movementBtn)
        mapImageView.addSubview(crackBtn)
        mapImageView.addSubview(diamondBtn)
        mapImageView.addSubview(volcanoBtn)
        mapImageView.addSubview(lavaBtn)
        
        rockBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NotebookLayout.Map.rockLeading)
            make.top.equalToSuperview().offset(NotebookLayout.Map.rockTop)
        }
        
        movementBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NotebookLayout.Map.movementLeading)
            make.top.equalToSuperview().offset(NotebookLayout.Map.movementTop)
        }
        
        crackBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NotebookLayout.Map.crackLeading)
            make.top.equalToSuperview().offset(NotebookLayout.Map.crackTop)
        }
        
        diamondBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NotebookLayout.Map.diamondLeading)
            make.top.equalToSuperview().offset(NotebookLayout.Map.diamondTop)
        }
        
        volcanoBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NotebookLayout.Map.volcanoLeading)
            make.top.equalToSuperview().offset(NotebookLayout.Map.volcanoTop)
        }
        
        lavaBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NotebookLayout.Map.lavaLeading)
            make.top.equalToSuperview().offset(NotebookLayout.Map.lavaTop)
        }
    }
    
    // MARK: - Helpers
    private func createMapButton(imageName: String, action: Selector?) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: imageName), for: .normal)
        if let action = action {
            btn.addTarget(self, action: action, for: .touchUpInside)
        }
        // 防止图片被拉伸，保留原始尺寸
        btn.imageView?.contentMode = .scaleAspectFit
        return btn
    }
    
    // MARK: - Actions
    @objc private func rockTapped() {
        print("【岩石探索】被点击，准备跳转游戏页面...")
        // TODO: 替换为实际的游戏页面跳转逻辑
        // let gameVC = RockExploreGameViewController()
        // present(gameVC, animated: true)
    }
    
    @objc private func movementTapped() {
        print("【地壳运动】被点击，准备跳转游戏页面...")
        let gameVC = CrustalMovementGameViewController()
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
}
