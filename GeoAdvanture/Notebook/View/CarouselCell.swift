//
//  CarouselCell.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/15.
//
import UIKit
import SnapKit

final class CarouselCell: UICollectionViewCell {
    
    static let reuseId = "CarouselCell"

    private let imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = UIColor(white: 0.92, alpha: 1)
        return v
    }()

    private let spinner = UIActivityIndicatorView(style: .medium)

    private var imageLoadTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(spinner)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        imageView.image = nil
        spinner.stopAnimating()
    }

    func configure(slide: NotebookCarouselSlide?) {
        imageLoadTask?.cancel()
        imageLoadTask = nil
        imageView.image = nil
        spinner.stopAnimating()
        guard let slide else { return }
        spinner.startAnimating()
        imageLoadTask = NotebookImageLoader.loadImage(from: slide.imageURL) { [weak self] result in
            self?.spinner.stopAnimating()
            switch result {
            case .success(let img):
                self?.imageView.image = img
            case .failure:
                self?.imageView.image = nil
            }
        }
    }
}
