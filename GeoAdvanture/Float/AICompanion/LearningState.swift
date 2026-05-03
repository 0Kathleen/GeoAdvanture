//
//  LearningState.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/26.
//

import Foundation

public enum LearningState: Equatable {
    /// 探索中：表现正常，静默陪伴
    case exploring
    /// 页面进入打招呼
    case greeting(message: String)
    /// 犹豫困惑：停留过久或无意义操作，触发轻量 L1 提示
    case confused(L1Tip: String)
    /// 挣扎错误：连续错误，触发 L2 大模型深度诊断
    case struggling(context: String, recentErrors: [String])
    /// 顿悟/熟练：操作成功，正向强化
    case proficient(encouragement: String)
}
