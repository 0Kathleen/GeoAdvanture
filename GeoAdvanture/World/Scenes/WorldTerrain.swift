//
//  WorldTerrain.swift
//  GeoAdvanture
//
//  横版世界的「阶梯下降剖面」地形模型（克制垂直版）。
//  一层由若干水平平台组成，自左向右逐级降低，相邻平台在衔接处用「攀爬点(梯子)」连接。
//  这样既有纵深探索感（越走越深，呼应「下潜」主题），又不需要跳跃/碰撞物理。
//  说明：一期由程序生成；后续可改为从 JSON 读取，接口不变。
//

import CoreGraphics

/// 一段可行走的水平平台。
struct TerrainPlatform {
    let index: Int
    let xStart: CGFloat
    let xEnd: CGFloat
    let y: CGFloat        // 平台表面高度（角色脚底所在的世界 y）

    var width: CGFloat { xEnd - xStart }
}

struct WorldTerrain {

    let platforms: [TerrainPlatform]
    /// 判定「已到平台端点、可攀爬」的水平容差。
    let reach: CGFloat = 74

    /// 生成一条自左向右逐级下降的阶梯地形（垂直范围收进单屏内，相机只需水平滚动）。
    static func descending(worldWidth: CGFloat, sceneHeight: CGFloat, count: Int = 4) -> WorldTerrain {
        let n = max(1, count)
        let seg = worldWidth / CGFloat(n)
        let yTop = sceneHeight * 0.58      // 起始（最高）平台
        let yBottom = sceneHeight * 0.24   // 末尾（最深）平台
        var ps: [TerrainPlatform] = []
        for i in 0..<n {
            let t = n == 1 ? 0 : CGFloat(i) / CGFloat(n - 1)
            let y = yTop - (yTop - yBottom) * t
            ps.append(TerrainPlatform(index: i, xStart: CGFloat(i) * seg, xEnd: CGFloat(i + 1) * seg, y: y))
        }
        return WorldTerrain(platforms: ps)
    }

    func platform(_ i: Int) -> TerrainPlatform? {
        platforms.indices.contains(i) ? platforms[i] : nil
    }

    /// 给定世界 x，返回该处平台表面高度（用于把 POI 放到地面上）。
    /// 平台在 x 轴上互不重叠且首尾相接，故任一 x 唯一落在某平台。
    func surfaceY(atX x: CGFloat) -> CGFloat {
        for p in platforms where x >= p.xStart && x <= p.xEnd { return p.y }
        return platforms.last?.y ?? 0
    }

    var first: TerrainPlatform { platforms.first! }
    var last: TerrainPlatform { platforms.last! }
    var count: Int { platforms.count }
}
