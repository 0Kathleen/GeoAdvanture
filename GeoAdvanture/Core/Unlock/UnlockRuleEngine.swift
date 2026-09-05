//
//  UnlockRuleEngine.swift
//  GeoAdvanture
//
//  解锁规则中枢：把「游戏事件」按 UnlockRules.json 的配置解锁对应内容。
//  修复历史问题：此前除 starter 外，没有任何游戏行为会解锁「关卡收获」。
//  现在通关地壳场景 / 抵达地心 / 打开地壳笔记本都会触发对应收获解锁。
//

import Foundation

extension Notification.Name {
    /// 有新内容被解锁时广播，userInfo: ["kind": String, "id": String]
    static let didUnlockContent = Notification.Name("didUnlockContent")
}

final class UnlockRuleEngine {

    static let shared = UnlockRuleEngine()

    private let rulesByEvent: [String: [UnlockTarget]]

    private init() {
        var map: [String: [UnlockTarget]] = [:]
        for rule in ContentStore.shared.unlockRules {
            map[rule.event, default: []].append(contentsOf: rule.unlock)
        }
        rulesByEvent = map

        #if DEBUG
        Self.validateReferences(map)
        #endif
    }

    /// 处理一个游戏事件，解锁其映射的全部内容（幂等）。
    func handle(_ event: String) {
        guard let targets = rulesByEvent[event] else { return }
        for t in targets {
            guard let kind = UnlockKind(rawValue: t.kind) else {
                print("⚠️ UnlockRuleEngine：未知的 kind \(t.kind)")
                continue
            }
            if ProgressStore.shared.unlock(kind, t.id) {
                print("🎁 解锁内容：\(t.kind)/\(t.id)（by \(event)）")
                NotificationCenter.default.post(
                    name: .didUnlockContent,
                    object: nil,
                    userInfo: ["kind": t.kind, "id": t.id]
                )
            }
        }
    }

    #if DEBUG
    /// 开发期校验：规则里引用的内容 id 必须真实存在，避免悬空引用。
    private static func validateReferences(_ map: [String: [UnlockTarget]]) {
        let valid = ContentStore.shared.allContentIds
        for (event, targets) in map {
            for t in targets where !valid.contains(t.id) {
                print("❗️ UnlockRules 悬空引用：事件 \(event) 指向不存在的 id \(t.id)")
            }
        }
    }
    #endif
}
