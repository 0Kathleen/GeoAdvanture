//
//  ChallengeHubRouter.swift
//  GeoAdvanture
//
//  闯关地图到二级主题页的唯一装配入口。
//

import UIKit

enum ChallengeHubRouter {

    static func makeViewController(
        poiId: String,
        delegate: ChallengeHubViewControllerDelegate?) -> UIViewController? {
        guard let poi = ContentStore.shared.poi(id: poiId),
              let definition = ContentStore.shared.challengeHub(poiId: poiId) else {
            assertionFailure("POI \(poiId) 缺少二级主题页配置")
            return nil
        }

        let hub = ChallengeHubViewController(definition: definition, poi: poi)
        hub.delegate = delegate
        let controller: UIViewController = hub
        controller.modalPresentationStyle = .fullScreen
        return controller
    }
}
