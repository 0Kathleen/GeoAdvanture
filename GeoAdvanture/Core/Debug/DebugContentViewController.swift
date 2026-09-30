//
//  DebugContentViewController.swift
//  GeoAdvanture
//
//  PR-1 验收页（仅 DEBUG）：把 ContentStore 加载到的世界/POI/藏品/仪器，
//  以及 ProgressStore 的进度状态直观列出，并提供发现/采集/通关/重置的自测按钮，
//  用于验证「数据地基 + 进度层」是否正确、且重启后仍保留。
//

#if DEBUG
import UIKit

final class DebugContentViewController: UIViewController {

    // MARK: 行模型
    private struct Row {
        let title: String
        let subtitle: String
        let action: (() -> Void)?
        init(_ title: String, _ subtitle: String = "", action: (() -> Void)? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.action = action
        }
    }
    private struct Section {
        let header: String
        let rows: [Row]
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [Section] = []

    // MARK: 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "内容 / 进度 调试台"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh, target: self, action: #selector(reload)
        )
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close, target: self, action: #selector(closeSelf)
            )
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        reload()
    }

    // MARK: 组装数据
    @objc private func reload() {
        let content = ContentStore.shared
        let progress = GameProgressManager.shared
        var result: [Section] = []

        // 概要
        result.append(Section(header: "概要（ContentStore 加载结果）", rows: [
            Row("圈层 layers", "\(content.layers.count)"),
            Row("世界 worlds", "\(content.worlds.count)"),
            Row("POI", "\(content.pois.count)"),
            Row("藏品 collectibles", "\(content.collectibles.count)"),
            Row("仪器 instruments", "\(content.instruments.count)"),
            Row("学习专题 knowledgeTopics", "\(content.allKnowledgeTopicIds.count)"),
            Row("关卡二级页 challengeHubs", "\(content.learningData.challengeHubs.count)"),
            Row("迁移任务 transferChallenges", "\(content.learningData.transferChallenges.count)"),
            Row("综合任务 integratedMissions", "\(content.learningData.integratedMissions.count)")
        ]))

        // Step 1：知识学习状态（已发现 → 已理解 → 会应用）
        for layer in content.learningData.layers where !layer.knowledgeTopics.isEmpty {
            let rows: [Row] = layer.knowledgeTopics.map { topic in
                let state = progress.knowledgeProgress(id: topic.id)
                let stage: String
                switch state.stage {
                case .locked: stage = "🔒未发现"
                case .discovered: stage = "①已发现"
                case .understood: stage = "②已理解"
                case .applied: stage = "③会应用"
                }
                let unread = state.hasUnreadContent ? " · 🆕未读" : ""
                return Row("\(topic.title)  (\(topic.id))", "\(stage) · best=\(state.bestScore)\(unread)")
            }
            result.append(Section(header: "知识掌握 · \(layer.layerId)", rows: rows))
        }

        // 世界（含通关/可进入状态）
        let worldRows: [Row] = content.worlds.map { w in
            let completed = progress.isWorldCompleted(id: w.id)
            let canEnter = progress.canEnterWorld(w)
            let req: String
            switch w.completionRequirement.kind {
            case .completePOIs:
                req = "完成 " + (w.completionRequirement.poiIds?.joined(separator: ",") ?? "-")
            case .discoverAllPOIs:
                req = "发现本层全部 POI"
            }
            let stage = w.isComingSoon ? "🚧二期占位" : "①一期"
            let flags = "\(completed ? "✅已通关" : "⬜未通关")  \(canEnter ? "🔓可进入" : "🔒锁")"
            return Row("[\(w.index)] \(w.title)  (\(w.id))  \(stage)",
                       "宽\(w.widthScreens)屏 · 通关条件：\(req)\n\(flags)")
        }
        result.append(Section(header: "世界 Worlds", rows: worldRows))

        // 每层的 POI
        for w in content.worlds {
            let rows: [Row] = content.pois(worldId: w.id).map { p in
                let discovered = progress.isPOIDiscovered(id: p.id)
                var meta = "类型：\(p.interactionType.rawValue) · x=\(p.x)"
                if let ref = p.interactionRef { meta += " · ref=\(ref)" }
                if let c = p.collectibleId { meta += " · 掉落=\(c)" }
                if let inst = p.requiresInstrument { meta += " · 需仪器=\(inst)" }
                meta += "\n\(discovered ? "✅已发现" : "⬜未发现")"
                return Row("\(p.title)  (\(p.id))", meta)
            }
            result.append(Section(header: "POI · \(w.title)", rows: rows))
        }

        // 藏品
        let collectRows: [Row] = content.collectibles.map { c in
            let got = progress.isCollected(id: c.id)
            return Row("\(c.name)  (\(c.id))",
                       "\(c.category) · \(c.worldId)  \(got ? "✅已采集" : "⬜未采集")")
        }
        result.append(Section(header: "藏品 Collectibles", rows: collectRows))

        // 仪器
        let instrRows: [Row] = content.instruments.map { i in
            let owned = progress.hasInstrument(id: i.id)
            return Row("\(i.name)  (\(i.id))", "\(i.perceptionTag)  \(owned ? "✅已获得" : "⬜未获得")")
        }
        result.append(Section(header: "仪器 Instruments（一期占位）", rows: instrRows))

        // 进入横版世界（PR-2）
        let worldRowsEnter: [Row] = content.worlds.map { w in
            let subtitle = w.isComingSoon ? "🚧 二期占位（不可进入）" : "▶️ 点击进入"
            return Row("进入世界：\(w.title)", subtitle) { [weak self] in
                guard !w.isComingSoon else { return }
                self?.enterWorld(id: w.id)
            }
        }
        result.append(Section(header: "横版世界 PR-2（占位美术，可走动/相机跟随/视差）", rows: worldRowsEnter))

        // 自测操作（验证写读一致 + 重启保留）
        result.append(Section(header: "自测操作（点后立即刷新；可杀进程重开验证保留）", rows: [
            Row("① 发现 POI：岩石采集场", "markPOIDiscovered(poi_crust_rock)") { [weak self] in
                GameProgressManager.shared.markPOIDiscovered(id: "poi_crust_rock"); self?.reload()
            },
            Row("② 采集藏品：火成岩", "collect(collect_igneous)") { [weak self] in
                GameProgressManager.shared.collect(id: "collect_igneous"); self?.reload()
            },
            Row("③ 通关：地壳", "completeWorld(crust) → 地幔应变可进入") { [weak self] in
                GameProgressManager.shared.completeWorld(id: "crust"); self?.reload()
            },
            Row("④ 通关：地幔", "completeWorld(mantle)") { [weak self] in
                GameProgressManager.shared.completeWorld(id: "mantle"); self?.reload()
            },
            Row("⑤ 板块知识：已发现", "recordEvidence(poi_crust_plate)") { [weak self] in
                LearningProgressCoordinator.shared.recordEvidence(sourceId: "poi_crust_plate"); self?.reload()
            },
            Row("⑥ 板块知识：已理解", "recordUnderstanding(harvest_movement)") { [weak self] in
                LearningProgressCoordinator.shared.recordUnderstanding(topicId: "harvest_movement", score: 100); self?.reload()
            },
            Row("⑦ 板块知识：会应用", "recordApplication(harvest_movement)") { [weak self] in
                LearningProgressCoordinator.shared.recordApplication(topicId: "harvest_movement", score: 100); self?.reload()
            },
            Row("↺ 仅重置地壳进度", "清除地壳 POI / 关卡 / 知识 / 收藏 / 通关") { [weak self] in
                self?.confirmCrustReset()
            },
            Row("⚠️ 重置全部进度", "resetAllProgress()") { [weak self] in
                self?.confirmReset()
            }
        ]))

        sections = result
        tableView.reloadData()
    }

    private func confirmCrustReset() {
        let alert = UIAlertController(
            title: "重置地壳进度？",
            message: "只清空地壳关卡、知识和收藏记录，不影响其他圈层。",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "重置", style: .destructive) { [weak self] _ in
            GameProgressManager.shared.resetProgress(worldId: "crust")
            self?.reload()
        })
        present(alert, animated: true)
    }

    private func confirmReset() {
        let alert = UIAlertController(title: "重置全部进度？", message: "将清空 CoreData 中的解锁/世界/设置。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "重置", style: .destructive) { [weak self] _ in
            GameProgressManager.shared.resetAllProgress()
            self?.reload()
        })
        present(alert, animated: true)
    }

    private func enterWorld(id: String) {
        guard let vc = WorldViewController(worldId: id) else { return }
        present(vc, animated: true)
    }

    @objc private func closeSelf() {
        dismiss(animated: true)
    }
}

// MARK: - UITableView
extension DebugContentViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = row.subtitle
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = row.action != nil ? .disclosureIndicator : .none
        cell.selectionStyle = row.action != nil ? .default : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].rows[indexPath.row].action?()
    }
}
#endif
