//
//  CarouselCell.swift
//  GeoAdvanture
//
//  介绍页轮播单元：优先加载 JSON 里的 imageURL，失败则回退本地 CarouseImage 占位。
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

    private var loadTask: URLSessionDataTask?

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
        loadTask?.cancel()
        loadTask = nil
        imageView.image = nil
    }

    func configure(slide: NotebookCarouselSlide?) {
        loadTask?.cancel()
        imageView.image = nil
        guard let slide else { return }

        if let urlStr = slide.imageURL, let url = URL(string: urlStr) {
            loadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let img = UIImage(data: data) else {
                    DispatchQueue.main.async { self?.applyFallback(slide.imageName) }
                    return
                }
                DispatchQueue.main.async { self.imageView.image = img }
            }
            loadTask?.resume()
        } else {
            applyFallback(slide.imageName)
        }
    }

    private func applyFallback(_ name: String?) {
        if let name, let img = UIImage(named: name) {
            imageView.image = img
        }
    }
}
