//
//  DebugEntry.swift
//  GeoAdvanture
//
//  仅 DEBUG：在主窗口右下角注入一个悬浮「🐞」按钮，点开内容/进度调试台。
//  不侵入任何业务流程；Release 构建不包含本文件的任何代码。
//

#if DEBUG
import UIKit

enum DebugEntry {

    /// 在给定容器注入悬浮调试入口（幂等，重复调用只保留一个）。
    static func install(in container: UIView) {
        let tag = 999_777
        if container.viewWithTag(tag) != nil { return }

        let button = UIButton(type: .system)
        button.tag = tag
        button.setTitle("🐞", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        button.layer.cornerRadius = 24
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { _ in present() }, for: .touchUpInside)

        container.addSubview(button)
        container.bringSubviewToFront(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 48),
            button.heightAnchor.constraint(equalToConstant: 48),
            button.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -120)
        ])
    }

    private static func present() {
        guard let top = topViewController() else { return }
        let nav = UINavigationController(rootViewController: DebugContentViewController())
        nav.modalPresentationStyle = .fullScreen
        top.present(nav, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = root?.presentedViewController { root = presented }
        return root
    }
}
#endif
