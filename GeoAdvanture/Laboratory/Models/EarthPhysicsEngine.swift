//
//  EarthPhysicsEngine.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/2.
//

import Foundation

/// 物质状态
enum MatterState {
    case solid
    case plastic
    case liquid
}

/// 地层环境数据模型
struct EarthLayerData {
    let depth: Double       // 深度 (km)
    let temperature: Double // 温度 (°C)
    let pressure: Double    // 压力 (GPa)
    let density: Double     // 密度 (g/cm³)
    let state: MatterState  // 固态/液态/塑性
}

/// 样本数据模型
struct SampleData {
    var density: Double       // 密度 (g/cm³)
    var meltingPoint: Double  // 常压熔点 (°C)
    var strength: Double      // 抗压强度 (GPa)
}

/// 地心物理引擎，提供基于 PREM 模型的环境数据
class EarthPhysicsEngine {
    
    // 基于 PREM 和 Stacey (1992) 模型的关键节点数据
    private let earthProfile: [EarthLayerData] = [
        EarthLayerData(depth: 0, temperature: 15, pressure: 0.0001, density: 2.7, state: .solid),
        EarthLayerData(depth: 35, temperature: 600, pressure: 1.0, density: 3.3, state: .solid), // 莫霍面
        EarthLayerData(depth: 660, temperature: 1600, pressure: 24.0, density: 4.4, state: .plastic), // 上下地幔边界
        EarthLayerData(depth: 2890, temperature: 3700, pressure: 136.0, density: 5.5, state: .plastic), // 核幔边界(地幔侧)
        EarthLayerData(depth: 2891, temperature: 3750, pressure: 136.0, density: 9.9, state: .liquid), // 核幔边界(外核侧)
        EarthLayerData(depth: 5150, temperature: 4300, pressure: 330.0, density: 12.2, state: .liquid), // 内外核边界
        EarthLayerData(depth: 6371, temperature: 5500, pressure: 360.0, density: 13.1, state: .solid) // 地心
    ]
    
    /// 获取指定深度的环境数据 (使用线性插值)
    /// - Parameter depth: 深度 (km)
    /// - Returns: 包含温度、压力、密度、状态的环境数据
    func getEnvironment(at depth: Double) -> EarthLayerData {
        let targetDepth = max(0, min(depth, 6371))
        
        // 寻找目标深度所在的区间
        var lowerNode = earthProfile.first!
        var upperNode = earthProfile.last!
        
        for i in 0..<earthProfile.count - 1 {
            if targetDepth >= earthProfile[i].depth && targetDepth <= earthProfile[i+1].depth {
                lowerNode = earthProfile[i]
                upperNode = earthProfile[i+1]
                break
            }
        }
        
        if lowerNode.depth == upperNode.depth {
            return lowerNode
        }
        
        // 线性插值比例
        let t = (targetDepth - lowerNode.depth) / (upperNode.depth - lowerNode.depth)
        
        let interpTemp = lowerNode.temperature + (upperNode.temperature - lowerNode.temperature) * t
        let interpPressure = lowerNode.pressure + (upperNode.pressure - lowerNode.pressure) * t
        let interpDensity = lowerNode.density + (upperNode.density - lowerNode.density) * t
        
        // 状态以 upperNode 为准（向下进入新地层时状态改变）
        let state = targetDepth > lowerNode.depth ? upperNode.state : lowerNode.state
        
        return EarthLayerData(
            depth: targetDepth,
            temperature: interpTemp,
            pressure: interpPressure,
            density: interpDensity,
            state: state
        )
    }
    
    /// 计算样本在当前压强下的实际熔点 (简化的 Simon-Glatzel 方程)
    /// - Parameters:
    ///   - baseMeltingPoint: 常压熔点 (°C)
    ///   - currentPressure: 当前环境压力 (GPa)
    /// - Returns: 实际熔点 (°C)
    func calculateActualMeltingPoint(baseMeltingPoint: Double, currentPressure: Double) -> Double {
        // 简化参数：假设压力每增加 1 GPa，熔点提升约 20°C (仅作科普演示用，真实情况更复杂)
        // 这样在 136 GPa (核幔边界) 时，熔点提升约 2720°C
        return baseMeltingPoint + currentPressure * 20.0
    }

    func layerName(for depth: Double) -> String {
        switch depth {
        case ..<35:
            return "地壳"
        case ..<2890:
            return "地幔"
        case ..<5150:
            return "外核"
        default:
            return "内核"
        }
    }
}
