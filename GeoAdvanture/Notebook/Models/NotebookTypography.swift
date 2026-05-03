//
//  NotebookTypography.swift
//  GeoAdvanture
//
//

import UIKit

enum NotebookTypography {

    private static func loadFont(candidates: [String], size: CGFloat, fallbackWeight: UIFont.Weight) -> UIFont {
        for name in candidates {
            if let font = UIFont(name: name, size: size) {
                return font
            }
        }
        return .systemFont(ofSize: size, weight: fallbackWeight)
    }

    static func topTitleFont(size: CGFloat) -> UIFont {
        loadFont(candidates: ["FZZJ-QNTJW--GB1-0"], size: size, fallbackWeight: .medium)
    }

    // MARK: - 右侧列表 NoteCell
    enum ListCell {
        static let titleColor = UIColor(red: 0x52 / 255, green: 0x38 / 255, blue: 0x36 / 255, alpha: 1)
        static let bodyColor = UIColor(red: 0x53 / 255, green: 0x39 / 255, blue: 0x36 / 255, alpha: 1)

        static let titleFont: UIFont = {
            loadFont(candidates: ["FZCKJW--GB1-0"], size: 16, fallbackWeight: .medium)
        }()

        static let bodyFont: UIFont = {
            loadFont(candidates: [
                "STSongti-SC-Regular",
                "STSongti-SC-Medium",
                "STSongti-TC-Regular",
                "Songti SC",
                "Songti TC",
                "PingFangSC-Regular"
            ], size: 12, fallbackWeight: .regular)
        }()

        static let titleContentSpacing: CGFloat = 5
        static let titleInnerInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        static let contentTitleImageName = "contentTitle"
        static let outerInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        static func attributedBody(_ plainText: String) -> NSAttributedString {
            let ps = NSMutableParagraphStyle()
            ps.lineBreakMode = .byWordWrapping
            return NSAttributedString(string: plainText, attributes: [
                .font: bodyFont,
                .foregroundColor: bodyColor,
                .paragraphStyle: ps
            ])
        }
    }
}
