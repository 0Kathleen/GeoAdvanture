//
//  HomeLayerModel.swift
//  GeoAdvanture
//
//  首页三层地球模型的资源映射与展示参数。
//

import UIKit

enum HomeLayer: Int, CaseIterable {
    case crust = 1
    case mantle = 2
    case core = 3

    var title: String {
        switch self {
        case .crust: return "地壳"
        case .mantle: return "地幔"
        case .core: return "地核"
        }
    }

    var resourceName: String {
        switch self {
        case .crust: return "earth+globe+3d+model_simplified"
        case .mantle: return "rock+sphere+3d+model_simplified"
        case .core: return "fiery+lava+sphere+3d+model_simplified"
        }
    }

    var lightweightBaseColorName: String {
        switch self {
        case .crust: return "home_crust_basecolor"
        case .mantle: return "home_mantle_basecolor"
        case .core: return "home_core_basecolor"
        }
    }

    var lightweightNormalName: String {
        switch self {
        case .crust: return "home_crust_normal"
        case .mantle: return "home_mantle_normal"
        case .core: return "home_core_normal"
        }
    }

    var tintColor: UIColor {
        switch self {
        case .crust:
            return UIColor(red: 0.29, green: 0.66, blue: 0.82, alpha: 1)
        case .mantle:
            return UIColor(red: 0.88, green: 0.46, blue: 0.24, alpha: 1)
        case .core:
            return UIColor(red: 1.00, green: 0.73, blue: 0.23, alpha: 1)
        }
    }

    /// 在首页调试面板中确认的模型默认观察角度，单位为度。
    var defaultRotationDegrees: (x: Float, y: Float, z: Float) {
        switch self {
        case .crust: return (-77.3, 10.0, -2.0)
        case .mantle: return (-2.7, -26.7, 69.3)
        case .core: return (-5.3, 58.7, 2.7)
        }
    }

    /// 三个 AIGC 模型会先分别归一化；组合时再恢复圈层间的视觉比例。
    var assembledScale: Float {
        switch self {
        case .crust: return 5.0
        case .mantle: return 5.0
        case .core: return 2.5
        }
    }

    /// 展开后保持与合拢状态相同的模型大小。
    var expandedScale: Float {
        assembledScale
    }

    var expandedX: Float {
        switch self {
        case .crust: return -2.8
        case .mantle: return 0
        case .core: return 2.8
        }
    }
}
