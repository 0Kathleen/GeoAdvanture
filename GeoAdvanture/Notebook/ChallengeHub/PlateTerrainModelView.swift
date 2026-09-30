//
//  PlateTerrainModelView.swift
//  GeoAdvanture
//
//  地壳运动二级页的世界地貌视觉：与其他二级页保持一致，不在图片上重复任务入口。
//

import UIKit
import SnapKit

final class PlateTerrainModelView: UIView {

    struct TaskState {
        let id: String
        let title: String
        let symbol: String
        let completed: Bool
        let unlocked: Bool
    }

    private let oceanView = UIView()
    private let worldView = UIView()
    private let artworkView = UIImageView()
    private let instructionLabel = UILabel()
    private let knowledgeOverlay = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func render(tasks: [TaskState], animated: Bool) {
        instructionLabel.text = "板块彼此碰撞、俯冲或拉开，长期塑造出山脉、海沟与裂谷。"
        guard animated else { return }
        instructionLabel.alpha = 0.45
        UIView.animate(withDuration: 0.25) { self.instructionLabel.alpha = 1 }
    }

    func setKnowledgeOverlayVisible(_ visible: Bool, animated: Bool) {
        let updates = {
            self.knowledgeOverlay.alpha = visible ? 1 : 0
            self.knowledgeOverlay.transform = visible ? .identity : CGAffineTransform(scaleX: 0.94, y: 0.94)
        }
        if animated {
            if visible { knowledgeOverlay.isHidden = false }
            UIView.animate(withDuration: 0.24, animations: updates) { _ in
                self.knowledgeOverlay.isHidden = !visible
            }
        } else {
            knowledgeOverlay.isHidden = !visible
            updates()
        }
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.72, green: 0.87, blue: 0.88, alpha: 1)
        layer.cornerRadius = 28
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.withAlphaComponent(0.82).cgColor
        clipsToBounds = true

        oceanView.backgroundColor = UIColor(red: 0.29, green: 0.67, blue: 0.78, alpha: 1)
        addSubview(oceanView)
        oceanView.snp.makeConstraints { $0.edges.equalToSuperview() }

        artworkView.image = UIImage(named: "model_plate_terrain")
        artworkView.contentMode = .scaleAspectFill
        artworkView.clipsToBounds = true
        artworkView.layer.cornerRadius = 22
        artworkView.isHidden = artworkView.image == nil
        oceanView.addSubview(artworkView)
        artworkView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(18)
            make.bottom.equalToSuperview().inset(18)
        }

        worldView.backgroundColor = UIColor(red: 0.42, green: 0.68, blue: 0.39, alpha: 1)
        worldView.layer.cornerRadius = 90
        worldView.layer.borderWidth = 8
        worldView.layer.borderColor = UIColor(red: 0.90, green: 0.80, blue: 0.55, alpha: 0.72).cgColor
        worldView.isHidden = artworkView.image != nil
        oceanView.addSubview(worldView)
        worldView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(34)
            make.width.equalToSuperview().multipliedBy(0.83)
            make.height.equalTo(180)
        }

        let worldTitle = UILabel()
        worldTitle.text = "世界地貌微模型"
        worldTitle.font = .systemFont(ofSize: 21, weight: .heavy)
        worldTitle.textColor = .white
        worldTitle.textAlignment = .center
        worldView.addSubview(worldTitle)
        worldTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.centerX.equalToSuperview()
        }

        let plateLines = UIStackView()
        plateLines.axis = .horizontal
        plateLines.distribution = .fillEqually
        plateLines.spacing = 8
        worldView.addSubview(plateLines)
        plateLines.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(34)
            make.centerY.equalToSuperview().offset(16)
            make.height.equalTo(42)
        }
        ["大陆板块", "海洋板块", "大陆板块"].forEach { title in
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 11, weight: .bold)
            label.textColor = .white
            label.textAlignment = .center
            label.backgroundColor = title == "海洋板块"
                ? UIColor(red: 0.18, green: 0.39, blue: 0.55, alpha: 0.82)
                : UIColor(red: 0.45, green: 0.29, blue: 0.16, alpha: 0.82)
            label.layer.cornerRadius = 12
            label.clipsToBounds = true
            plateLines.addArrangedSubview(label)
        }

        knowledgeOverlay.axis = .horizontal
        knowledgeOverlay.distribution = .fillEqually
        knowledgeOverlay.spacing = 8
        ["→ 挤压 ←", "↘ 俯冲", "← 拉张 →"].forEach { text in
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 10, weight: .heavy)
            label.textColor = UIColor(red: 0.16, green: 0.29, blue: 0.42, alpha: 1)
            label.textAlignment = .center
            label.backgroundColor = UIColor.white.withAlphaComponent(0.84)
            label.layer.cornerRadius = 9
            label.clipsToBounds = true
            knowledgeOverlay.addArrangedSubview(label)
        }
        worldView.addSubview(knowledgeOverlay)
        knowledgeOverlay.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(34)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(22)
        }
        setKnowledgeOverlayVisible(false, animated: false)

        instructionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 2
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        instructionLabel.layer.cornerRadius = 11
        instructionLabel.clipsToBounds = true
        addSubview(instructionLabel)
        instructionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(34)
            make.height.greaterThanOrEqualTo(34)
        }
    }
}
