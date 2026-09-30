//
//  NotebookPageNavigation.swift
//  GeoAdvanture
//
//  知识本页面共用的刷新与定位协议。
//  容器只处理页签和路由；各页面自行解释定位目标并更新自己的局部 UI。
//

import Foundation

enum NotebookPage: Int, CaseIterable {
    case intro = 0
    case map = 1
    case summary = 2
    case explore = 3

    var title: String {
        switch self {
        case .intro: return "认识"
        case .map: return "闯关地图"
        case .summary: return "知识总结"
        case .explore: return "生活百科"
        }
    }
}

enum NotebookFocusTarget: Equatable {
    case inquiry(id: String)
    case poi(id: String)
    case knowledgeTopic(id: String)
}

struct NotebookNavigationRequest: Equatable {
    let page: NotebookPage
    let focus: NotebookFocusTarget?

    static func inquiry(_ id: String) -> Self {
        .init(page: .intro, focus: .inquiry(id: id))
    }

    static func poi(_ id: String) -> Self {
        .init(page: .map, focus: .poi(id: id))
    }

    static func knowledgeTopic(_ id: String) -> Self {
        .init(page: .summary, focus: .knowledgeTopic(id: id))
    }
}

protocol NotebookPageContent: AnyObject {
    /// 从关卡返回或学习进度变化时，仅刷新当前页面的动态内容。
    func refreshContent()

    /// 页面按稳定内容 ID 定位。返回 false 表示该目标不属于当前页或当前圈层。
    @discardableResult
    func focus(on target: NotebookFocusTarget, animated: Bool) -> Bool
}

extension NotebookPageContent {
    @discardableResult
    func focus(on target: NotebookFocusTarget, animated: Bool) -> Bool { false }
}

protocol NotebookPageNavigationDelegate: AnyObject {
    func notebookPageRequestsNavigation(_ request: NotebookNavigationRequest, animated: Bool)
}
