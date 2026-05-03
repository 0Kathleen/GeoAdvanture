//
//  NotebookLayout.swift
//  GeoAdvanture
//
//  笔记本页布局常量（相对各容器，与文案分离）
//

import UIKit

enum NotebookResourceNames {
    static let background = "normalBackground"
    static let notebook = "noteBook"
    static let titleBubble = "titleBubble"
    static let realImageCircleFrame = "realImgeCircle"
    static let leftHeaderImageLayer1 = "layer1_leftImage"
    static let bookmarkSelected = ["bookMark1_left", "bookMark2_left", "bookMark3_left", "bookMark4_left"]
    static let bookmarkNormal = ["bookMark1_right", "bookMark2_right", "bookMark3_right", "bookMark4_right"]
}

enum NotebookLayout {
    static let backgroundInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    static let notebookInsets = UIEdgeInsets(top: 18, left: 73, bottom: 8, right: 32)

    static let topCenterTitleTop: CGFloat = 8

    static let bookmarkBarTop: CGFloat = 23
    static let bookmarkBarLeading: CGFloat = 730
    static let bookmarkBarSize = CGSize(width: 40, height: 330)

    static let bookmarkSize = CGSize(width: 32, height: 80)
    static let bookmarkVerSpacing: CGFloat = 5
    static let bookmarkHoriSpacing: CGFloat = 4

    static var mainContentLeading: CGFloat = 25
    static var mainContentTop: CGFloat = 28
    static var mainContentTrail: CGFloat = 12
    static var mainContentBottom: CGFloat = 25
    static var leftContentWidth: CGFloat = 260
    static let contentHorizontalInset: CGFloat = 22

    static let leftViewSize = CGSize(width: 280, height: 260)
    static let circleDiameter: CGFloat = 140
    static let circleBottomOffset: CGFloat = 12
    static let circleTop: CGFloat = 160
    
    // MARK: - 地图页面布局 (书签 1)
    enum Map {
        static let rockLeading: CGFloat = 293
        static let rockTop: CGFloat = 48
        
        static let movementLeading: CGFloat = 54
        static let movementTop: CGFloat = 211
        
        static let crackLeading: CGFloat = 364
        static let crackTop: CGFloat = 166
        
        static let diamondLeading: CGFloat = 243
        static let diamondTop: CGFloat = 242
        
        static let volcanoLeading: CGFloat = 478
        static let volcanoTop: CGFloat = 43
        
        static let lavaLeading: CGFloat = 430
        static let lavaTop: CGFloat = 281
    }
}

