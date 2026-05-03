//
//  GlobalMapThumbnailView.swift
//  GeoAdvanture
//

import UIKit
import SnapKit

final class GlobalMapThumbnailView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "🌍 世界板块微缩图"
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .darkGray
        l.textAlignment = .center
        return l
    }()
    
    private let mapImageView: UIImageView = {
        let v = UIImageView()
        v.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        // TODO: 替换为真实的世界地图素材
        // v.image = UIImage(named: "world_map_thumbnail")
        return v
    }()
    
    private let highlightPoint: UIView = {
        let v = UIView()
        v.backgroundColor = .red
        v.layer.cornerRadius = 6
        v.alpha = 0
        return v
    }()
    
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .bold)
        l.textColor = .white
        l.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        l.alpha = 0
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        layer.cornerRadius = 12
        
        addSubview(titleLabel)
        addSubview(mapImageView)
        mapImageView.addSubview(highlightPoint)
        mapImageView.addSubview(locationLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
        }
        
        mapImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }
    
    /// 高亮对应地标
    func highlightLocation(_ locationName: String) {
        // 根据名称写死坐标占位（后续可根据真实地图的比例调整）
        var relativePoint = CGPoint(x: 0.5, y: 0.5)
        
        switch locationName {
        case "喜马拉雅山脉":
            relativePoint = CGPoint(x: 0.7, y: 0.4)
        case "马里亚纳海沟":
            relativePoint = CGPoint(x: 0.85, y: 0.5)
        case "安第斯山脉":
            relativePoint = CGPoint(x: 0.25, y: 0.7)
        case "东非大裂谷":
            relativePoint = CGPoint(x: 0.55, y: 0.6)
        case "大西洋中脊":
            relativePoint = CGPoint(x: 0.4, y: 0.5)
        default:
            relativePoint = CGPoint(x: 0.5, y: 0.5)
        }
        
        locationLabel.text = " \(locationName) "
        
        // 布局前强制刷新以获取真实 bounds
        mapImageView.layoutIfNeeded()
        let width = mapImageView.bounds.width
        let height = mapImageView.bounds.height
        
        let targetX = width > 0 ? width * relativePoint.x : 100
        let targetY = height > 0 ? height * relativePoint.y : 50
        
        highlightPoint.snp.remakeConstraints { make in
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.center.equalTo(CGPoint(x: targetX, y: targetY))
        }
        
        locationLabel.snp.remakeConstraints { make in
            make.bottom.equalTo(highlightPoint.snp.top).offset(-4)
            make.centerX.equalTo(highlightPoint)
            make.height.equalTo(20)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.highlightPoint.alpha = 1.0
            self.locationLabel.alpha = 1.0
        }
    }
    
    func resetHighlight() {
        UIView.animate(withDuration: 0.3) {
            self.highlightPoint.alpha = 0
            self.locationLabel.alpha = 0
        }
    }
}
