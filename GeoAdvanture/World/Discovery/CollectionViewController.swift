//
//  CollectionViewController.swift
//  GeoAdvanture
//
//  图鉴页：网格展示全部藏品，已采集彩色可点、未采集置灰"?"。
//  数据来源：ContentStore(静态藏品定义) + GameProgressManager(采集进度，CoreData 持久化)。
//  真美术到位后（PR-7）把色块换成 collect_<id> 图标即可。
//

import UIKit
import SnapKit

final class CollectionViewController: UIViewController {

    private var collectibles: [Collectible] = []
    private var collectionView: UICollectionView!
    private let progressLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "图鉴"
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        collectibles = ContentStore.shared.collectibles
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        setupProgressLabel()
        setupGrid()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        updateProgressLabel()
    }

    // MARK: - 构建

    private func setupProgressLabel() {
        progressLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        progressLabel.textColor = UIColor(white: 0.85, alpha: 1)
        progressLabel.textAlignment = .center
        view.addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupGrid() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 14
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns + 1)
        let side = floor((UIScreen.main.bounds.width - totalSpacing) / columns)
        layout.itemSize = CGSize(width: side, height: side + 24)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CollectibleCell.self, forCellWithReuseIdentifier: CollectibleCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(progressLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func updateProgressLabel() {
        let gm = GameProgressManager.shared
        let got = collectibles.filter { gm.isCollected(id: $0.id) }.count
        progressLabel.text = "已收集 \(got) / \(collectibles.count)"
    }

    @objc private func closeTapped() { dismiss(animated: true) }
}

// MARK: - DataSource / Delegate

extension CollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectibles.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: CollectibleCell.reuseId, for: indexPath) as! CollectibleCell
        let item = collectibles[indexPath.item]
        cell.configure(with: item, collected: GameProgressManager.shared.isCollected(id: item.id))
        return cell
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = collectibles[indexPath.item]
        guard GameProgressManager.shared.isCollected(id: item.id) else { return }
        let alert = UIAlertController(title: item.name, message: item.funFact, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Cell

final class CollectibleCell: UICollectionViewCell {

    static let reuseId = "CollectibleCell"

    private let tile = UIView()
    private let glyph = UILabel()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        tile.layer.cornerRadius = 14
        tile.clipsToBounds = true
        contentView.addSubview(tile)
        tile.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(tile.snp.width)
        }

        glyph.font = .systemFont(ofSize: 44)
        glyph.textAlignment = .center
        tile.addSubview(glyph)
        glyph.snp.makeConstraints { $0.center.equalToSuperview() }

        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(tile.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: Collectible, collected: Bool) {
        if collected {
            tile.backgroundColor = Self.color(for: item.category)
            glyph.text = Self.glyph(for: item.category)
            nameLabel.text = item.name
            nameLabel.textColor = .white
        } else {
            tile.backgroundColor = UIColor(white: 0.2, alpha: 1)
            glyph.text = "?"
            nameLabel.text = "未收集"
            nameLabel.textColor = UIColor(white: 0.5, alpha: 1)
        }
    }

    private static func color(for category: String) -> UIColor {
        switch category {
        case "rock": return .systemBrown
        case "mineral": return .systemTeal
        case "fossil": return .systemIndigo
        default: return .systemGray
        }
    }

    private static func glyph(for category: String) -> String {
        switch category {
        case "rock": return "🪨"
        case "mineral": return "💎"
        case "fossil": return "🦴"
        default: return "📦"
        }
    }
}
