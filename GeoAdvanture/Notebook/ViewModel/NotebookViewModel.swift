//
//  NotebookViewModel.swift
//  GeoAdvanture
//
//  负责对 NotebookContent 提供的数据进行二次处理与组装，为各个子页面提供渲染所需的干净数据结构。
//

import UIKit

// MARK: - View Data Structs

/// 书签 intro 数据
struct NotebookIntroViewData {
    let circleAttributedCaption: NSAttributedString?
    let carouselSlides: [NotebookCarouselSlide]
    let introListRows: [NoteModel]
}

/// 书签 map 数据
struct NotebookSubPageData {
    let titleText: String
    let layerName: String
}

// MARK: - ViewModel

class NotebookViewModel {
    
    private let layerIndex: Int
    
    init(layerIndex: Int) {
        self.layerIndex = layerIndex
    }
    
    private var knowledge: EarthLayerKnowledge? {
        NotebookContent.knowledge(forLayer: layerIndex)
    }
    
    var layerName: String {
        knowledge?.title ?? "—"
    }
    
    func fetchIntroData() -> NotebookIntroViewData {
        let slides = knowledge?.carouselSlides ?? []
        let rows = NotebookContent.kidIntroRows(forLayer: layerIndex, bidPrefix: "L\(layerIndex)_")
        
        let caption = NSMutableAttributedString()
        if let k = knowledge {
            let titleFont = NotebookTypography.topTitleFont(size: 32)
            let suffixFont = NotebookTypography.topTitleFont(size: 20)
            
            caption.append(NSAttributedString(string: k.title, attributes: [
                .font: titleFont,
                .foregroundColor: UIColor.label
            ]))
            caption.append(NSAttributedString(string: "--\(k.tagline)", attributes: [
                .font: suffixFont,
                .foregroundColor: UIColor.label
            ]))
        }
        
        return NotebookIntroViewData(
            circleAttributedCaption: caption.length > 0 ? caption : nil,
            carouselSlides: slides,
            introListRows: rows
        )
    }
    
    func fetchSubPageData(bookmarkIndex: Int) -> NotebookSubPageData {
        let titleText = (0..<NotebookContent.bookmarkTitles.count).contains(bookmarkIndex)
            ? NotebookContent.bookmarkTitles[bookmarkIndex]
            : "页面"
            
        return NotebookSubPageData(
            titleText: titleText,
            layerName: layerName
        )
    }
}
