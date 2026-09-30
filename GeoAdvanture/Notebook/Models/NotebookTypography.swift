//
//  NotebookTypography.swift
//  GeoAdvanture
//
//

import UIKit

/// App 级视觉规范。Round 1 先统一颜色、字体、间距、圆角和按钮，
/// 后续页面只引用语义 token，不再各自保存一套 RGB 与字号。
enum GeoTheme {
    enum Color {
        static let paper = UIColor(red: 0.97, green: 0.93, blue: 0.84, alpha: 1)
        static let paperMuted = UIColor(red: 0.91, green: 0.85, blue: 0.73, alpha: 1)
        static let ink = UIColor(red: 0x52 / 255, green: 0x38 / 255, blue: 0x36 / 255, alpha: 1)
        static let inkMuted = ink.withAlphaComponent(0.72)
        static let teal = UIColor(red: 0.27, green: 0.51, blue: 0.48, alpha: 1)
        static let clay = UIColor(red: 0.72, green: 0.38, blue: 0.25, alpha: 1)
        static let blue = UIColor(red: 0.24, green: 0.49, blue: 0.72, alpha: 1)
        /// 首页暖粉、浅紫背景上的功能强调色。
        static let mauve = UIColor(red: 0.38, green: 0.29, blue: 0.42, alpha: 1)
        static let blushControl = UIColor(red: 0.91, green: 0.80, blue: 0.84, alpha: 0.96)
        static let gold = UIColor(red: 0.90, green: 0.66, blue: 0.25, alpha: 1)
        static let success = UIColor(red: 0.35, green: 0.60, blue: 0.41, alpha: 1)
        static let warning = UIColor(red: 0.77, green: 0.46, blue: 0.13, alpha: 1)
        static let locked = UIColor(white: 0.55, alpha: 1)
        static let separator = ink.withAlphaComponent(0.16)
        static let paperCard = UIColor.white.withAlphaComponent(0.46)
        static let paperControl = UIColor.white.withAlphaComponent(0.68)
        static let darkSurface = UIColor(red: 0.18, green: 0.14, blue: 0.11, alpha: 1)
        static let lightText = UIColor(red: 1, green: 0.98, blue: 0.93, alpha: 1)
        static let darkOverlay = UIColor.black.withAlphaComponent(0.44)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    enum Radius {
        static let control: CGFloat = 12
        static let card: CGFloat = 16
        static let modal: CGFloat = 22
        static let capsule: CGFloat = 23
    }

    enum Typography {
        fileprivate static func loadFont(
            candidates: [String],
            size: CGFloat,
            fallbackWeight: UIFont.Weight
        ) -> UIFont {
            for name in candidates {
                if let font = UIFont(name: name, size: size) { return font }
            }
            return .systemFont(ofSize: size, weight: fallbackWeight)
        }

        static func brandTitle(size: CGFloat) -> UIFont {
            loadFont(candidates: ["FZZJ-QNTJW--GB1-0"], size: size, fallbackWeight: .semibold)
        }

        static func heading(size: CGFloat) -> UIFont {
            loadFont(candidates: ["FZCKJW--GB1-0"], size: size, fallbackWeight: .semibold)
        }

        static func body(size: CGFloat = 15) -> UIFont {
            loadFont(candidates: [
                "SourceHanSerifCN-Medium",
                "STSongti-SC-Medium",
                "Songti SC",
                "PingFangSC-Regular"
            ], size: size, fallbackWeight: .regular)
        }

        static func control(size: CGFloat = 15) -> UIFont {
            .systemFont(ofSize: size, weight: .semibold)
        }

        static func caption(size: CGFloat = 13) -> UIFont {
            .systemFont(ofSize: size, weight: .medium)
        }
    }

    enum ButtonStyle {
        case primary
        case paper
        case overlay
    }

    static func buttonConfiguration(
        title: String? = nil,
        systemImage: String? = nil,
        style: ButtonStyle
    ) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = systemImage.flatMap(UIImage.init(systemName:))
        configuration.imagePadding = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        configuration.cornerStyle = .capsule
        switch style {
        case .primary:
            configuration.baseForegroundColor = .white
            configuration.baseBackgroundColor = Color.teal
        case .paper:
            configuration.baseForegroundColor = Color.ink
            configuration.baseBackgroundColor = Color.paper.withAlphaComponent(0.94)
        case .overlay:
            configuration.baseForegroundColor = .white
            configuration.baseBackgroundColor = Color.darkOverlay
        }
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = Typography.control()
            return updated
        }
        return configuration
    }

    static func applyFloatingShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.20
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    static func applyReadableShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.52
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    static func applyPaperCard(to view: UIView, radius: CGFloat = Radius.card) {
        view.backgroundColor = Color.paperCard
        view.layer.cornerRadius = radius
        view.layer.borderWidth = 1
        view.layer.borderColor = Color.separator.cgColor
    }
}

enum NotebookTypography {
    static func topTitleFont(size: CGFloat) -> UIFont {
        GeoTheme.Typography.brandTitle(size: size)
    }

    // MARK: - 右侧列表 NoteCell
    enum ListCell {
        static let titleColor = GeoTheme.Color.ink
        static let bodyColor = GeoTheme.Color.ink

        static let titleFont = GeoTheme.Typography.heading(size: 18)
        static let bodyFont = GeoTheme.Typography.body()

        static let titleContentSpacing: CGFloat = 5
        static let titleInnerInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        static let contentTitleImageName = "contentTitle"
        static let outerInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        static func attributedBody(_ plainText: String) -> NSAttributedString {
            let ps = NSMutableParagraphStyle()
            ps.lineBreakMode = .byWordWrapping
            ps.lineSpacing = 6 // 增加行间距，使文本看起来更正常舒适
            return NSAttributedString(string: plainText, attributes: [
                .font: bodyFont,
                .foregroundColor: bodyColor,
                .paragraphStyle: ps
            ])
        }
    }
}
