//
//  AIChatLayout.swift
//  GeoAdvanture
//
//

import UIKit

enum AIChatLayout {

    static var screenHorizontalInset: CGFloat { 0 }

    static var chatViewTop: CGFloat { 43 }
    static var chatViewLeading: CGFloat { 54 }
    static var chatViewTrailing: CGFloat { 34 }

    static var topAvatarSize: CGFloat { 70 }
    static var topAvatarTop: CGFloat { 32 }
    static var topAvatarLeading: CGFloat { 32 }

    static var titleLabelHieght: CGFloat { 20 }
    static var titleLabelleading: CGFloat { 20 }
    
    static var inputBarHeight: CGFloat { 52 }
    static var inputBarHorizontalInset: CGFloat { 20 }
    static var inputBarBottom: CGFloat { 10 }
    static var inputBarTop: CGFloat { 292 }

    static var textFieldHeight: CGFloat { 50 }
    static var textFieldCornerRadius: CGFloat { 20 }
    static var textFieldLeftPadding: CGFloat { 22 }
    static var textFieldToVoice: CGFloat { 15 }
    static var textFieldToSend: CGFloat { 12 }
    
    static var voiceIconSize: CGFloat { 50 }
    static var sendIconSize: CGSize { CGSize(width: 94, height: 52) }

    static var tableInset: CGFloat { 16 }
    static var tableBottom: CGFloat { 75 }
    static var aiRowHorizontalPadding: CGFloat { 32 }
    static var userRowHorizontalPadding: CGFloat { 22 }
}

// MARK: - 聊天气泡样式（无图片资源，纯代码绘制）

enum AIChatBubbleStyle {

    /// 机器人
    static let botFill = UIColor(red: 0xBC / 255, green: 0xE1 / 255, blue: 0xD8 / 255, alpha: 1)
    static let botStroke = UIColor(red: 0x90 / 255, green: 0xB3 / 255, blue: 0xAB / 255, alpha: 1)
    static let botStrokeWidth: CGFloat = 1
    static let botCornerRadius: CGFloat = 16

    /// 用户
    static let userFill = UIColor(red: 0xFA / 255, green: 0xA8 / 255, blue: 0x96 / 255, alpha: 1)
    static let userStroke = UIColor(red: 0xC7 / 255, green: 0x7B / 255, blue: 0x6E / 255, alpha: 1)
    static let userStrokeWidth: CGFloat = 1
    static let userCornerRadius: CGFloat = 20

    /// 阴影
    static let shadowColor = UIColor(white: 0, alpha: 1)
    static let shadowOpacity: Float = 0.25
    static let shadowOffset = CGSize(width: 0, height: 4)
    static let shadowRadius: CGFloat = 4
}

// MARK: - 输入与正文辅色

enum AIChatTextColors {

    /// 输入框内文字
    static let textField = UIColor(red: 0x93 / 255, green: 0x7D / 255, blue: 0x67 / 255, alpha: 1)
    static let textFieldPlaceholder: UIColor = {
        textField.withAlphaComponent(0.5)
    }()
    static let textSize: Int = 20
    static let textFont = "FZCKJW--GB1-0"
    
    static let messagePrimary = UIColor(white: 0.2, alpha: 1)
}

// MARK: - 通用阴影

enum AIChatShadow {

    static func apply(to layer: CALayer) {
        layer.shadowColor = AIChatBubbleStyle.shadowColor.cgColor
        layer.shadowOpacity = AIChatBubbleStyle.shadowOpacity
        layer.shadowOffset = AIChatBubbleStyle.shadowOffset
        layer.shadowRadius = AIChatBubbleStyle.shadowRadius
    }
}
