//
//  NotebookLifeEncyclopediaViewController.swift
//  GeoAdvanture
//
//  拓展页：把圈层知识放进居住、材料、能源和安全等生活情境中。
//

import UIKit
import SnapKit

final class NotebookLifeEncyclopediaViewController: UIViewController {

    private struct Entry {
        let title: String
        let kicker: String
        let body: String
        let symbol: String
        let imageAsset: String
        let color: UIColor
    }

    private let viewModel: NotebookViewModel
    private var entries: [Entry] = []
    private var buttons: [UIButton] = []
    private var selectedIndex = 0

    private let detailSymbol = UIImageView()
    private let detailImage = UIImageView()
    private let detailKicker = UILabel()
    private let detailTitle = UILabel()
    private let detailBody = UILabel()
    private let detailPanel = UIView()

    init(viewModel: NotebookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        entries = makeEntries(layerId: viewModel.layerId)
        setupUI()
        renderSelection(animated: false)
    }

    private func setupUI() {
        let title = UILabel()
        title.text = "原来地质就在身边"
        title.font = GeoTheme.Typography.heading(size: 22)
        title.textColor = GeoTheme.Color.ink

        let subtitle = UILabel()
        subtitle.text = "选择一个生活场景，看看“\(viewModel.layerName)”怎样影响我们。"
        subtitle.font = GeoTheme.Typography.body(size: 12)
        subtitle.textColor = GeoTheme.Color.inkMuted

        let headerCopy = UIStackView(arrangedSubviews: [title, subtitle])
        headerCopy.axis = .horizontal
        headerCopy.alignment = .firstBaseline
        headerCopy.spacing = 14

        let selectors = UIStackView()
        selectors.axis = .horizontal
        selectors.spacing = 9
        selectors.distribution = .fillEqually
        for (index, entry) in entries.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle("  \(entry.title)", for: .normal)
            button.setImage(UIImage(systemName: entry.symbol), for: .normal)
            button.titleLabel?.font = GeoTheme.Typography.control(size: 12)
            button.layer.cornerRadius = GeoTheme.Radius.control
            button.layer.borderWidth = 1
            button.addTarget(self, action: #selector(entryTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            selectors.addArrangedSubview(button)
        }

        GeoTheme.applyPaperCard(to: detailPanel, radius: GeoTheme.Radius.modal)

        let visual = UIView()
        visual.backgroundColor = GeoTheme.Color.paperMuted.withAlphaComponent(0.38)
        visual.layer.cornerRadius = GeoTheme.Radius.card
        visual.clipsToBounds = true
        detailImage.contentMode = .scaleAspectFill
        detailSymbol.contentMode = .scaleAspectFit
        visual.addSubview(detailImage)
        visual.addSubview(detailSymbol)
        detailImage.snp.makeConstraints { $0.edges.equalToSuperview() }
        detailSymbol.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(92)
        }

        detailKicker.font = GeoTheme.Typography.control(size: 12)
        detailTitle.font = GeoTheme.Typography.heading(size: 24)
        detailTitle.textColor = GeoTheme.Color.ink
        detailBody.font = GeoTheme.Typography.body(size: 14)
        detailBody.textColor = GeoTheme.Color.inkMuted
        detailBody.numberOfLines = 0

        let copy = UIStackView(arrangedSubviews: [detailKicker, detailTitle, detailBody])
        copy.axis = .vertical
        copy.spacing = 8
        detailPanel.addSubview(visual)
        detailPanel.addSubview(copy)
        visual.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(16)
            make.width.equalToSuperview().multipliedBy(0.43)
        }
        copy.snp.makeConstraints { make in
            make.leading.equalTo(visual.snp.trailing).offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        view.addSubview(headerCopy)
        view.addSubview(selectors)
        view.addSubview(detailPanel)
        headerCopy.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(16)
        }
        selectors.snp.makeConstraints { make in
            make.top.equalTo(headerCopy.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        detailPanel.snp.makeConstraints { make in
            make.top.equalTo(selectors.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }

    @objc private func entryTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        renderSelection(animated: true)
    }

    private func renderSelection(animated: Bool) {
        guard entries.indices.contains(selectedIndex) else { return }
        let entry = entries[selectedIndex]
        buttons.enumerated().forEach { index, button in
            let selected = index == selectedIndex
            button.backgroundColor = selected ? entry.color : GeoTheme.Color.paperCard
            button.setTitleColor(selected ? .white : GeoTheme.Color.ink, for: .normal)
            button.tintColor = selected ? .white : GeoTheme.Color.inkMuted
            button.layer.borderColor = selected ? UIColor.clear.cgColor : GeoTheme.Color.separator.cgColor
        }
        let updates = {
            let photo = UIImage(named: entry.imageAsset)
            self.detailImage.image = photo
            self.detailImage.isHidden = photo == nil
            self.detailSymbol.image = UIImage(systemName: entry.symbol)
            self.detailSymbol.tintColor = entry.color
            self.detailSymbol.isHidden = photo != nil
            self.detailKicker.text = entry.kicker
            self.detailKicker.textColor = entry.color
            self.detailTitle.text = entry.title
            self.detailBody.text = entry.body
        }
        if animated {
            UIView.transition(with: detailPanel, duration: 0.22, options: .transitionCrossDissolve, animations: updates)
        } else {
            updates()
        }
    }

    private func makeEntries(layerId: String) -> [Entry] {
        switch layerId {
        case "mantle":
            return [
                Entry(title: "地热能源", kicker: "地下热量怎样被利用？", body: "地下热水和蒸汽可以供暖、发电。它们不是来自地心火焰，而是来自地球内部保存和产生的热量。", symbol: "bolt.fill", imageAsset: "life_mantle_geothermal", color: .systemOrange),
                Entry(title: "火山岛", kicker: "海上为什么会长出岛屿？", body: "一些岩浆穿过海洋板块喷出，反复堆积后能露出海面，形成新的火山岛。", symbol: "water.waves", imageAsset: "life_mantle_volcanic_island", color: .systemTeal),
                Entry(title: "板块旅行", kicker: "大陆真的会移动吗？", body: "地幔岩石虽然大部分是固体，却能在漫长时间里缓慢变形，使地表板块不断改变位置。", symbol: "arrow.left.and.right", imageAsset: "life_mantle_plate_motion", color: .systemBrown),
                Entry(title: "宝石旅程", kicker: "深处形成的晶体如何来到地表？", body: "高温高压能帮助一些矿物结晶，快速上升的岩浆会把深部物质带向较浅的位置。", symbol: "diamond.fill", imageAsset: "life_mantle_deep_crystal", color: .systemPurple)
            ]
        case "core":
            return [
                Entry(title: "指南针", kicker: "指针为什么总指向北方？", body: "地球外核中运动的液态金属帮助产生地磁场，指南针会沿着磁场方向转动。", symbol: "location.north.fill", imageAsset: "life_core_compass", color: .systemBlue),
                Entry(title: "保护地球", kicker: "看不见的磁场有什么用？", body: "地磁场能让许多来自太阳的带电粒子偏转，像一把巨大的隐形保护伞。", symbol: "shield.fill", imageAsset: "life_core_magnetosphere", color: .systemTeal),
                Entry(title: "寻找地核", kicker: "没人到过地核，怎么知道它存在？", body: "科学家比较地震波穿过地球后的速度和路线，由此推断外核是液态、内核是固态。", symbol: "waveform.path", imageAsset: "life_core_seismic_wave", color: .systemIndigo),
                Entry(title: "南北极光", kicker: "天空彩带和地核有关吗？", body: "太阳粒子沿地磁场进入极区高空，与大气碰撞时会形成绚丽的极光。", symbol: "sparkles", imageAsset: "life_core_aurora", color: .systemPurple)
            ]
        default:
            return [
                Entry(title: "房屋与道路", kicker: "建筑材料从哪里来？", body: "砂石、黏土、石灰岩和花岗岩都来自地壳。认识岩石性质，才能把材料用在合适的位置。", symbol: "house.fill", imageAsset: "life_crust_building", color: .systemBrown),
                Entry(title: "地震安全", kicker: "为什么有些地方更容易地震？", body: "许多强地震发生在板块边界附近。了解断层和地层，可以帮助城市选择更安全的建设方式。", symbol: "waveform.path.ecg", imageAsset: "life_crust_earthquake_safety", color: .systemRed),
                Entry(title: "手机里的矿物", kicker: "电子产品也与地质有关？", body: "手机中的玻璃、金属和电池材料来自不同矿物。开采后还需要分类回收，减少新的资源消耗。", symbol: "iphone", imageAsset: "life_crust_phone_minerals", color: .systemTeal),
                Entry(title: "肥沃的土壤", kicker: "火山旁为什么适合种植？", body: "火山岩风化后会释放多种矿物成分，经过很长时间可以形成肥沃土壤，但活火山附近也需要防灾。", symbol: "leaf.fill", imageAsset: "life_crust_volcanic_soil", color: .systemGreen)
            ]
        }
    }
}

extension NotebookLifeEncyclopediaViewController: NotebookPageContent {
    func refreshContent() {}
}
