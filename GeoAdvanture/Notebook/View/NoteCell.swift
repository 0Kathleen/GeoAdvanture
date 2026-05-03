//
//  NoteCell.swift
//  GeoAdvanture
//
//

import UIKit
import SnapKit

class NoteCell: UITableViewCell {

    private let titleBackgroundImageView = UIImageView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        let style = NotebookTypography.ListCell.self
        titleBackgroundImageView.contentMode = .scaleAspectFit
        titleBackgroundImageView.clipsToBounds = true
        titleBackgroundImageView.image = UIImage(named: style.contentTitleImageName)

        titleLabel.font = style.titleFont
        titleLabel.textColor = style.titleColor
        titleLabel.numberOfLines = 0

        contentLabel.numberOfLines = 0

        contentView.addSubview(titleBackgroundImageView)
        titleBackgroundImageView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)

        let outer = style.outerInsets
        titleBackgroundImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(outer.top)
            make.leading.equalToSuperview().offset(outer.left)
            make.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(style.titleInnerInsets)
        }

        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleBackgroundImageView.snp.bottom).offset(style.titleContentSpacing)
            make.leading.equalToSuperview().offset(outer.left)
            make.trailing.equalToSuperview().inset(outer.right)
            make.bottom.equalToSuperview().inset(outer.bottom)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        contentLabel.text = nil
        contentLabel.attributedText = nil
    }

    func configure(model: NoteModel) {
        titleLabel.text = model.title
        contentLabel.attributedText = NotebookTypography.ListCell.attributedBody(model.content)
    }
}
