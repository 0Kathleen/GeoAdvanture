//
//  WorldPalette.swift
//  GeoAdvanture
//
//  每层横版世界的占位配色（按 world.id）。真美术到位后（PR-7）可弃用或作兜底。
//  颜色对齐《美术风格与AIGC提示词》的四层色板。
//

import UIKit

struct WorldPalette {
    let sky: UIColor      // 背景天色
    let far: UIColor      // 远景视差层
    let mid: UIColor      // 中景视差层
    let near: UIColor     // 近景视差层
    let ground: UIColor   // 地面
    let player: UIColor   // 角色占位

    static func forWorld(_ id: String) -> WorldPalette {
        switch id {
        case "crust":
            return WorldPalette(sky: .hex(0xF6E3B8), far: .hex(0xE8C079), mid: .hex(0xC98A3B),
                                near: .hex(0x8B5A2B), ground: .hex(0x5E3C1E), player: .hex(0x2E6FB0))
        case "mantle":
            return WorldPalette(sky: .hex(0xF6B24A), far: .hex(0xE5533C), mid: .hex(0xC63A2A),
                                near: .hex(0x8E241B), ground: .hex(0x5C160F), player: .hex(0xFFE08A))
        case "outer_core":
            return WorldPalette(sky: .hex(0x2E6FB0), far: .hex(0x3A86C7), mid: .hex(0x2668A0),
                                near: .hex(0x184A78), ground: .hex(0x0E2E4E), player: .hex(0x38C6D9))
        case "inner_core":
            return WorldPalette(sky: .hex(0xD8DCE3), far: .hex(0xC0C6D0), mid: .hex(0xA7AEBC),
                                near: .hex(0x8A92A3), ground: .hex(0x5E6675), player: .hex(0xC8A64B))
        default:
            return WorldPalette(sky: .hex(0xF6E3B8), far: .hex(0xE8C079), mid: .hex(0xC98A3B),
                                near: .hex(0x8B5A2B), ground: .hex(0x5E3C1E), player: .hex(0x2E6FB0))
        }
    }
}

extension UIColor {
    /// 用 0xRRGGBB 十六进制创建颜色。
    static func hex(_ rgb: Int, alpha: CGFloat = 1) -> UIColor {
        UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    /// 提亮当前颜色（amount 0~1，按比例向白色插值）。
    func lighter(_ amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        let t = max(0, min(1, amount))
        return UIColor(red: r + (1 - r) * t, green: g + (1 - g) * t, blue: b + (1 - b) * t, alpha: a)
    }
}
