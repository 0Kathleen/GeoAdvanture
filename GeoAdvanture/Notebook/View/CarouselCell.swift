//
//  CarouselCell.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/15.
//
import UIKit
import SnapKit

class CarouselCell: UICollectionViewCell {
    
    static let reuseId = "CarouselCell"

    private let imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = UIColor(white: 0.92, alpha: 1)
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    func configure(slide: NotebookCarouselSlide?) {
        imageView.image = nil
        guard let slide else { return }
        imageView.image = UIImage(named: slide.imageName)
    }
}
