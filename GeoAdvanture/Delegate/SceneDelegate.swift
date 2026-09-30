//
//  SceneDelegate.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/7/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let view = FlashingViewController()
        let navigation = UINavigationController(rootViewController: view)
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigation
        window?.makeKeyAndVisible()

        // AI 头像与 Debug 入口都挂在主 Window 的穿透 overlay 上，避免额外 UIWindow 拦截全屏触摸。
        if let window {
            AIAvatarWindowManager.shared.setup(hostWindow: window)
            #if DEBUG
            if let overlay = AIAvatarWindowManager.shared.overlayHostView {
                DebugEntry.install(in: overlay)
            }
            #endif
            // 启动页的唯一职责是进入首页。此时隐藏所有悬浮控件，避免
            // 它们参与首次触摸的命中测试；进入首页后再由启动页统一显示。
            AIAvatarWindowManager.shared.hide()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }


}
