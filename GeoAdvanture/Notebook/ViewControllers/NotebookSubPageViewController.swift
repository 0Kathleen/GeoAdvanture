//
//  NotebookSubPageViewController.swift
//  GeoAdvanture
//
//

import UIKit
import SnapKit

final class NotebookSubPageViewController: UIViewController {

    private let bookmarkIndex: Int
    private let viewModel: NotebookViewModel

    init(bookmarkIndex: Int, viewModel: NotebookViewModel) {
        self.bookmarkIndex = bookmarkIndex
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let data = viewModel.fetchSubPageData(bookmarkIndex: bookmarkIndex)

        let titleLabel = UILabel()
        titleLabel.font = NotebookTypography.ListCell.titleFont
        titleLabel.textColor = NotebookTypography.ListCell.titleColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.text = data.titleText

        let hint = UILabel()
        hint.font = NotebookTypography.ListCell.bodyFont
        hint.textColor = NotebookTypography.ListCell.bodyColor
        hint.numberOfLines = 0
        hint.textAlignment = .center
        hint.text = "当前圈层：\(data.layerName)\n\n此处为独立页面占位，可接入闯关地图、关卡收获、拓展园地等模块。"

        view.addSubview(titleLabel)
        view.addSubview(hint)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        hint.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
