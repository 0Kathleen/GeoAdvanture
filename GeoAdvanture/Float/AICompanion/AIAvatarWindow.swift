//
//  AIAvatarWindowManager.swift
//  AIAvatarWindow.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/26.
//

import UIKit

/// 全屏悬浮层：只拦截子控件上的触摸，其余区域穿透给下层业务视图。
/// 必须挂在主 Window 上；单独 UIWindow 的 hitTest 穿透在 iOS 上不可靠。
class PassThroughOverlayView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}

///
/// 单例模式
/// 将 AI 头像悬浮层挂在主 Window 最上层，避免额外 UIWindow 吞掉全屏触摸。
///
public class AIAvatarWindowManager {

    public static let shared = AIAvatarWindowManager()

    private var overlayView: PassThroughOverlayView?
    private weak var hostWindow: UIWindow?
    private var isInitialized = false

    private init() {}

    public func setup(hostWindow: UIWindow) {
        guard !isInitialized else { return }
        self.hostWindow = hostWindow

        let overlay = AIAvatarOverlayView(frame: hostWindow.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = true
        hostWindow.addSubview(overlay)
        hostWindow.bringSubviewToFront(overlay)

        overlayView = overlay
        isInitialized = true
    }

    public func show() {
        overlayView?.isHidden = false
        if let hostWindow, let overlayView {
            hostWindow.bringSubviewToFront(overlayView)
        }
    }

    public func hide() {
        overlayView?.isHidden = true
    }

    /// 供 Debug 入口等悬浮控件挂载（与 AI 头像同一穿透层）。
    var overlayHostView: UIView? { overlayView }
}

///
/// AI 头像 + 提示气泡，挂载在主 Window 的穿透 overlay 上。
///
final class AIAvatarOverlayView: PassThroughOverlayView {
    private let avatarButton = UIButton(type: .custom)
    private var isDragging = false

    private let bubbleView = UIImageView()
    private let bubbleLabel = UILabel()
    private var bubbleHideTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAvatarButton()
        setupBubbleView()
        bindViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var windowSafeAreaInsets: UIEdgeInsets {
        (window ?? superview as? UIWindow)?.safeAreaInsets ?? safeAreaInsets
    }

    private func bindViewModel() {
        AICompanionViewModel.shared.onStateChanged = { [weak self] state in
            self?.handleStateChange(state)
        }
    }

    private func handleStateChange(_ state: LearningState) {
        switch state {
        case .exploring:
            hideBubble()
            startBreathingAnimation()

        case .greeting(let message):
            showBubble(text: message, type: .proficient)
            startBreathingAnimation()

        case .confused(let tip):
            showBubble(text: tip, type: .confused)
            startThinkingAnimation()

        case .struggling:
            showBubble(text: "我在思考怎么帮你...", type: .struggling)
            startThinkingAnimation()

        case .proficient(let encouragement):
            showBubble(text: encouragement, type: .proficient)
            startCelebratingAnimation()
        }
    }

    private func setupBubbleView() {
        bubbleView.image = UIImage(named: "smallBackView")
        bubbleView.contentMode = .scaleToFill
        bubbleView.isUserInteractionEnabled = false

        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.15
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 4)
        bubbleView.layer.shadowRadius = 6
        bubbleView.alpha = 0

        bubbleLabel.font = GeoTheme.Typography.body(size: 14)
        bubbleLabel.textColor = GeoTheme.Color.ink
        bubbleLabel.numberOfLines = 0
        bubbleLabel.textAlignment = .center

        bubbleView.addSubview(bubbleLabel)
        addSubview(bubbleView)
    }

    private func updateBubbleLayout() {
        let screenWidth = bounds.width
        let padding: CGFloat = 12
        let avatarFrame = avatarButton.frame

        let maxSize = CGSize(width: 200, height: 100)
        let textRect = bubbleLabel.textRect(forBounds: CGRect(origin: .zero, size: maxSize), limitedToNumberOfLines: 0)
        let bubbleWidth = textRect.width + 24
        let bubbleHeight = textRect.height + 16

        var bubbleX: CGFloat = 0
        let bubbleY = avatarFrame.minY + (avatarFrame.height - bubbleHeight) / 2

        if avatarFrame.midX < screenWidth / 2 {
            bubbleX = avatarFrame.maxX + padding
        } else {
            bubbleX = avatarFrame.minX - bubbleWidth - padding
        }
        bubbleView.frame = CGRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight)
        bubbleLabel.frame = bubbleView.bounds.insetBy(dx: 12, dy: 8)
    }

    private enum BubbleType { case confused, struggling, proficient }

    private func showBubble(text: String, type: BubbleType) {
        bubbleLabel.text = text
        switch type {
        case .confused, .struggling, .proficient:
            bubbleLabel.textColor = GeoTheme.Color.ink
        }

        updateBubbleLayout()

        if bubbleView.alpha == 0 {
            bubbleView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
                self.bubbleView.alpha = 1.0
                self.bubbleView.transform = .identity
            }
        }

        bubbleHideTimer?.invalidate()
        bubbleHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.hideBubble()
        }
    }

    private func hideBubble() {
        bubbleHideTimer?.invalidate()
        UIView.animate(withDuration: 0.3) {
            self.bubbleView.alpha = 0
        }
    }

    private func setupAvatarButton() {
        avatarButton.setImage(UIImage(named: "AIavatar"), for: .normal)
        avatarButton.imageView?.contentMode = .scaleAspectFit
        avatarButton.accessibilityLabel = "岩小探"
        avatarButton.accessibilityHint = "打开地质问答"

        let size: CGFloat = 65
        avatarButton.frame = CGRect(x: 20, y: 60, width: size, height: size)
        addSubview(avatarButton)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        avatarButton.addGestureRecognizer(panGesture)
        avatarButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        startBreathingAnimation()
    }

    private func startBreathingAnimation() {
        avatarButton.layer.removeAllAnimations()
        avatarButton.transform = .identity

        guard !UIAccessibility.isReduceMotionEnabled else { return }

        UIView.animate(withDuration: 1.2,
                       delay: 0,
                       options: [.autoreverse, .repeat, .allowUserInteraction, .curveEaseInOut]) {
            self.avatarButton.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }
    }

    private func startThinkingAnimation() {
        avatarButton.layer.removeAllAnimations()
        avatarButton.transform = .identity

        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [0, -0.15, 0, 0.15, 0]
        animation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        avatarButton.layer.add(animation, forKey: "thinking")
    }

    private func startCelebratingAnimation() {
        avatarButton.layer.removeAllAnimations()
        avatarButton.transform = .identity

        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.values = [0, -15, 0, -8, 0]
        animation.keyTimes = [0, 0.3, 0.6, 0.8, 1.0]
        animation.duration = 1.0
        animation.repeatCount = 3
        avatarButton.layer.add(animation, forKey: "celebrating")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self, !self.isDragging else { return }
            self.startBreathingAnimation()
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let btn = gesture.view as? UIButton else { return }
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .began:
            isDragging = true
            hideBubble()
            btn.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.1) {
                btn.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                btn.alpha = 0.8
            }
        case .changed:
            btn.center = CGPoint(x: btn.center.x + translation.x, y: btn.center.y + translation.y)
            updateBubbleLayout()
            gesture.setTranslation(.zero, in: self)
        case .ended, .cancelled:
            isDragging = false
            let screenWidth = bounds.width
            let screenHeight = bounds.height
            let edgePadding: CGFloat = 10
            let safe = windowSafeAreaInsets

            var finalX = btn.center.x
            var finalY = btn.center.y
            if finalX < screenWidth / 2 {
                finalX = btn.bounds.width / 2 + edgePadding
            } else {
                finalX = screenWidth - btn.bounds.width / 2 - edgePadding
            }

            let minY = btn.bounds.height / 2 + edgePadding + safe.top
            let maxY = screenHeight - btn.bounds.height / 2 - edgePadding - safe.bottom
            finalY = min(max(finalY, minY), maxY)

            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                btn.center = CGPoint(x: finalX, y: finalY)
                btn.transform = .identity
                btn.alpha = 1.0
            } completion: { _ in
                self.startBreathingAnimation()
            }
        default:
            break
        }
    }

    @objc private func handleTap() {
        if isDragging { return }

        if UIAccessibility.isReduceMotionEnabled {
            openChatViewController()
            return
        }

        avatarButton.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.avatarButton.transform = CGAffineTransform(scaleX: 5.0, y: 5.0)
            self.avatarButton.alpha = 0
        } completion: { _ in
            self.openChatViewController()
            self.avatarButton.transform = .identity
            self.avatarButton.alpha = 1.0
            self.startBreathingAnimation()
        }
    }

    private func openChatViewController() {
        let chatVC = ChatViewController()
        chatVC.modalPresentationStyle = .fullScreen
        chatVC.modalTransitionStyle = .crossDissolve

        if let topVC = getTopViewController() {
            if topVC is ChatViewController { return }
            topVC.present(chatVC, animated: true)
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return nil }
        guard let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else { return nil }

        var topController = keyWindow.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        if let nav = topController as? UINavigationController {
            topController = nav.visibleViewController
        } else if let tab = topController as? UITabBarController {
            topController = tab.selectedViewController
        }
        return topController
    }
}
