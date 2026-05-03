//
//  NotebookIntroViewController.swift
//  GeoAdvanture
//

import UIKit
import SnapKit

class NotebookIntroViewController: UIViewController {

    private let viewModel: NotebookViewModel
    private let cellId = "NoteCell"
    private var dataSource: [NoteModel] = []

    private var carouselTimer: Timer?
    private var carouselItems: [NotebookCarouselSlide] = []
    private var carouselIndex: Int = 0

    private let leftNotebookContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private let leftHeaderImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: NotebookResourceNames.leftHeaderImageLayer1))
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let circleFrameImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: NotebookResourceNames.realImageCircleFrame))
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let circleCaptionLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.allowsSelection = true
        cv.register(CarouselCell.self, forCellWithReuseIdentifier: CarouselCell.reuseId)
        return cv
    }()

    private let rightNotebookContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.register(NoteCell.self, forCellReuseIdentifier: cellId)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 180
        tv.showsVerticalScrollIndicator = true
        return tv
    }()

    // MARK: - init
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
        configureForLayer()
    }

    deinit {
        carouselTimer?.invalidate()
    }

    // MARK: - configure
    private func configureForLayer() {
        let data = viewModel.fetchIntroData()
        
        carouselItems = data.carouselSlides
        circleCaptionLabel.attributedText = data.circleAttributedCaption
        dataSource = data.introListRows
        
        carouselCollectionView.reloadData()
        startCarouselIfNeeded()
        tableView.reloadData()
    }

    private func startCarouselIfNeeded() {
        carouselTimer?.invalidate()
        carouselTimer = nil
        guard carouselItems.count > 1 else { return }
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let next = (self.carouselIndex + 1) % self.carouselItems.count
            self.carouselIndex = next
            let x = CGFloat(next) * self.carouselCollectionView.bounds.width
            self.carouselCollectionView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
        }
    }
    
    // MARK: - layout
    private func setupLayout() {
        view.addSubview(leftNotebookContainerView)
        leftNotebookContainerView.addSubview(leftHeaderImageView)
        leftNotebookContainerView.addSubview(carouselCollectionView)
        leftNotebookContainerView.addSubview(circleFrameImageView)
        leftNotebookContainerView.addSubview(circleCaptionLabel)

        view.addSubview(rightNotebookContainerView)
        rightNotebookContainerView.addSubview(tableView)

        leftNotebookContainerView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(NotebookLayout.leftContentWidth)
        }
        leftHeaderImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(NotebookLayout.leftViewSize.height)
        }
        circleFrameImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(NotebookLayout.circleTop)
            make.leading.equalToSuperview()
            make.size.equalTo(CGSize(width: NotebookLayout.circleDiameter + 18, height: NotebookLayout.circleDiameter + 18))
        }
        carouselCollectionView.snp.makeConstraints { make in
            make.center.equalTo(circleFrameImageView)
            make.size.equalTo(CGSize(width: NotebookLayout.circleDiameter, height: NotebookLayout.circleDiameter))
        }
        carouselCollectionView.clipsToBounds = true
        carouselCollectionView.layer.cornerRadius = NotebookLayout.circleDiameter / 2

        circleCaptionLabel.snp.makeConstraints { make in
            make.top.equalTo(circleFrameImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.lessThanOrEqualToSuperview()
        }

        rightNotebookContainerView.snp.makeConstraints { make in
            make.leading.equalTo(leftNotebookContainerView.snp.trailing).offset(NotebookLayout.contentHorizontalInset)
            make.top.trailing.bottom.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableView
extension NotebookIntroViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! NoteCell
        cell.configure(model: dataSource[indexPath.row])
        return cell
    }
}

// MARK: - Carousel
extension NotebookIntroViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        max(1, carouselItems.count)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCell.reuseId, for: indexPath) as! CarouselCell
        let slide: NotebookCarouselSlide? = indexPath.item < carouselItems.count ? carouselItems[indexPath.item] : nil
        cell.configure(slide: slide)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < carouselItems.count else { return }
        let item = carouselItems[indexPath.item]
        let detail = CarouselViewController(imageURL: item.imageURL, caption: item.caption)
        let nav = UINavigationController(rootViewController: detail)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === carouselCollectionView, scrollView.bounds.width > 0 else { return }
        carouselIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
    }
}
