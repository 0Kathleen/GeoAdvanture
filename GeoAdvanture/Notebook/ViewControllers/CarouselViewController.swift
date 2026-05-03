//
//  CarouselViewController.swift
//  GeoAdvanture
//
//

import UIKit
import SnapKit

class CarouselViewController: UIViewController, UIScrollViewDelegate {

    private let imageURL: URL
    private let caption: String

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let captionTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = true
        tv.backgroundColor = UIColor(white: 0.97, alpha: 1)
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = .darkGray
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.layer.cornerRadius = 8
        tv.clipsToBounds = true
        return tv
    }()

    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let imageContainer = UIView()
    private var contentStack: UIStackView!

    init(imageURL: URL, caption: String) {
        self.imageURL = imageURL
        self.caption = caption
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(white: 0.94, alpha: 1)

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.addSubview(imageView)

        captionTextView.text = caption

        imageContainer.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(220)
        }

        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        contentStack = UIStackView(arrangedSubviews: [imageContainer, captionTextView])
        contentStack.axis = .horizontal
        contentStack.spacing = 12
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        view.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }

        captionTextView.snp.makeConstraints { make in
            make.width.equalTo(contentStack.snp.width).multipliedBy(0.38).priority(.high)
            make.width.greaterThanOrEqualTo(140)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(scrollView)
        }

        loadImage()
        updateLayoutForTraitCollection()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageInScrollViewIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayoutForTraitCollection()
    }

    private func updateLayoutForTraitCollection() {
        let narrow = traitCollection.horizontalSizeClass == .compact && view.bounds.width < 600
        contentStack.axis = narrow ? .vertical : .horizontal
        captionTextView.snp.remakeConstraints { make in
            if narrow {
                make.height.greaterThanOrEqualTo(120)
            } else {
                make.width.equalTo(contentStack.snp.width).multipliedBy(0.38).priority(.high)
                make.width.greaterThanOrEqualTo(140)
            }
        }
    }

    private func loadImage() {
        loadingIndicator.startAnimating()
        NotebookImageLoader.loadImage(from: imageURL) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                switch result {
                case .success(let img):
                    self.imageView.image = img
                    self.scrollView.zoomScale = 1
                    self.layoutImageInScrollViewIfNeeded()
                case .failure:
                    self.imageView.image = nil
                    self.captionTextView.text = "图片加载失败。\n\n" + self.caption
                }
            }
        }
    }

    private func layoutImageInScrollViewIfNeeded() {
        guard let img = imageView.image else { return }
        let scrollW = scrollView.bounds.width
        let scrollH = scrollView.bounds.height
        guard scrollW > 1, scrollH > 1 else { return }
        let scale = min(scrollW / img.size.width, scrollH / img.size.height)
        let w = img.size.width * scale
        let h = img.size.height * scale
        imageView.frame = CGRect(x: 0, y: 0, width: w, height: h)
        scrollView.contentSize = CGSize(width: w, height: h)
        scrollView.zoomScale = 1
        centerZoomedImageInsets()
    }

    private func centerZoomedImageInsets() {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}

enum NotebookImageLoader {

    private static let cache = NSCache<NSURL, UIImage>()

    @discardableResult
    static func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) -> URLSessionDataTask? {
        if let cached = cache.object(forKey: url as NSURL) {
            DispatchQueue.main.async {
                completion(.success(cached))
            }
            return nil
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data, let img = UIImage(data: data) else {
                DispatchQueue.main.async { completion(.failure(URLError(.cannotDecodeContentData))) }
                return
            }
            cache.setObject(img, forKey: url as NSURL)
            DispatchQueue.main.async { completion(.success(img)) }
        }
        task.resume()
        return task
    }
}
