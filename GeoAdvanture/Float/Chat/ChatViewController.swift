//
//  AIChatViewController.swift
//  musicApp
//
//  Created by 陈爽 on 2025/6/19.
//

import UIKit
import Alamofire
import Speech
import AVFoundation
import SnapKit

class ChatViewController: UIViewController {

    private let chatCellId = "ChatCell"
    private let manager = AIChatManager()

    var onShrinkWindow: (() -> Void)?

    private var bottomInputConstraint: Constraint?
    private var hasTriggeredInitialAutoRequest = false

    private var isRecording = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupManager()
        configUI()
        configNoti()
        requestSpeechAuthorization()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        manager.stopSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasTriggeredInitialAutoRequest else { return }
        hasTriggeredInitialAutoRequest = true
        manager.addGreetingMessage()
    }

    // MARK: - config
    private func setupManager() {
        manager.delegate = self
    }

    private func configUI() {
        view.addSubview(backView)
        view.addSubview(chatBackView)
        chatBackView.addSubview(titleLabel)
        chatBackView.addSubview(avatarButton)
        chatBackView.addSubview(chatTableView)
        chatBackView.addSubview(bottomStackView)

        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        chatBackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(AIChatLayout.chatViewTop)
            make.leading.equalToSuperview().offset(AIChatLayout.chatViewLeading)
            make.trailing.equalToSuperview().inset(AIChatLayout.chatViewTrailing)
        }

        avatarButton.snp.makeConstraints { make in
            make.top.equalTo(chatBackView.snp.top).offset(-AIChatLayout.topAvatarTop)
            make.leading.equalTo(chatBackView.snp.leading).offset(-AIChatLayout.topAvatarLeading)
            make.size.equalTo(AIChatLayout.topAvatarSize)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(chatBackView.snp.top).offset(-AIChatLayout.titleLabelHieght/2)
            make.leading.equalTo(avatarButton.snp.trailing).offset(5)
        }

        chatTableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(AIChatLayout.tableInset)
            make.bottom.equalToSuperview().inset(AIChatLayout.tableBottom)
        }
        
        bottomStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AIChatLayout.inputBarTop)
            make.height.equalTo(AIChatLayout.inputBarHeight)
            make.leading.trailing.equalToSuperview().inset(AIChatLayout.inputBarHorizontalInset)
        }

        voiceButton.snp.makeConstraints { make in
            make.size.equalTo(AIChatLayout.voiceIconSize)
            make.centerY.equalToSuperview()
        }
        sendBtn.snp.makeConstraints { make in
            make.size.equalTo(AIChatLayout.sendIconSize)
            make.centerY.equalToSuperview()
        }
        textField.snp.makeConstraints { make in
            make.height.equalTo(AIChatLayout.textFieldHeight)
            make.centerY.equalToSuperview()
        }
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        voiceButton.setContentHuggingPriority(.required, for: .horizontal)
        sendBtn.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func configNoti() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.voiceButton.isEnabled = true
                case .denied, .restricted, .notDetermined:
                    self.voiceButton.isEnabled = false
                @unknown default:
                    self.voiceButton.isEnabled = false
                }
            }
        }
    }
    
    // MARK: - UI
    private lazy var backView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "normalBackground"))
        view.backgroundColor = .clear
        return view
    }()

    private lazy var chatBackView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "chatBackground"))
        view.isUserInteractionEnabled = true
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        return view
    }()

    private lazy var avatarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "AIavatar"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(clickAvatarButton), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "FZCKJW--GB1-0", size: 20)
        label.text = "地理学习助手"
        label.textColor = AIChatTextColors.textField
        label.textAlignment = .center
        return label
    }()

    private lazy var bottomStackView: UIStackView = {
        let s = UIStackView(arrangedSubviews: [voiceButton, textField, sendBtn])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = AIChatLayout.textFieldToVoice
        s.distribution = .fill
        s.isLayoutMarginsRelativeArrangement = true
        return s
    }()

    private lazy var voiceButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "voiceButton"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(clickVoicedButton), for: .touchUpInside)
        return button
    }()

    private lazy var textField: UITextField = {
        let textfield = UITextField()
        textfield.background = UIImage(named: "textLabelBackground")
        textfield.attributedPlaceholder = NSAttributedString(
            string: "请输入......",
            attributes: [
                .foregroundColor: AIChatTextColors.textFieldPlaceholder,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )
        textfield.textColor = AIChatTextColors.textField
        textfield.font = .systemFont(ofSize: 15)
        textfield.returnKeyType = .send
        textfield.delegate = self
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: AIChatLayout.textFieldLeftPadding, height: 40))
        textfield.leftView = leftPadding
        textfield.leftViewMode = .always
        return textfield
    }()

    private lazy var sendBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "sendButton"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(clickSendButton), for: .touchUpInside)
        return button
    }()

    private lazy var chatTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: chatCellId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        return tableView
    }()

    // MARK: - Action
    @objc
    private func clickSendButton() {
        guard let text = textField.text, !text.isEmpty else { return }
        textField.text = nil
        view.endEditing(true)
        manager.sendUserMessage(text)
    }

    @objc
    private func clickVoicedButton() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    @objc
    private func clickAvatarButton() {
        dismiss(animated: true) { [weak self] in
            self?.onShrinkWindow?()
        }
    }

    @objc
    private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }

        let keyboardFrameInView = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.minY)
        let inset = max(overlap + 8, AIChatLayout.inputBarBottom)
        bottomInputConstraint?.update(inset: inset)

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc
    private func keyboardWillHide(notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }

        bottomInputConstraint?.update(inset: AIChatLayout.inputBarBottom)

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    private func scrollToBottom() {
        guard !manager.messages.isEmpty else { return }
        let lastSection = manager.messages.count - 1
        let lastIndexPath = IndexPath(row: 0, section: lastSection)
        
        // 优化滚动的流畅度：如果在流式生成中，只允许少量滚动，避免整个列表随字狂跳。
        chatTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
    }
    
    private func startRecording() {
        // 清理之前的任务
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
            var isFinal = false
            
            if let result = result {
                self?.textField.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                
                self?.isRecording = false
                self?.voiceButton.setImage(UIImage(named: "voiceButton"), for: .normal)
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            // 录音时可以改变图标颜色或样式表示正在录音
            voiceButton.setImage(UIImage(named: "voiceButton_recording") ?? UIImage(named: "voiceButton"), for: .normal)
            voiceButton.alpha = 0.5
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        voiceButton.setImage(UIImage(named: "voiceButton"), for: .normal)
        voiceButton.alpha = 1.0
    }
}

// MARK: - Manager Delegate
extension ChatViewController: AIChatManagerDelegate {

    func didUpdateMessages() {
        chatTableView.reloadData()
        
        // 当新建气泡时，我们需要确保新建的 Cell 已经被渲染然后再滚动
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom()
        }
    }

    func didUpdateStreamText(at index: Int, newText: String) {
        let indexPath = IndexPath(row: 0, section: index)
        
        // 方案 1：如果可见，直接获取 Cell 更新内容；并且使用 performBatchUpdates 强制触发布局更新。
        if let cell = chatTableView.cellForRow(at: indexPath) as? ChatCell {
            // 优化：只有当文本真正改变时，才去触发 tableView.beginUpdates() 重算高度
            // 避免每次抛出一个字，即使还没有换行，也导致整个列表重新计算布局（消耗极大）
            
            UIView.performWithoutAnimation {
                cell.updateContent(word: manager.messages[index])
                chatTableView.beginUpdates()
                chatTableView.endUpdates()
            }
        } else {
            // 如果滚动出了屏幕外，或者是第一次新建的气泡由于还没 ReloadData 完成导致取不到 cell，
            // 这里我们依然让数据源强制渲染，不过为了避免越界或影响动画，采用局部 reload。
            UIView.performWithoutAnimation {
                chatTableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        
        // 保证始终滚动到最底部
        scrollToBottom()
    }

    func didFinishChat(success: Bool, error: Error?) {
        if !success {
            print("报错了：\(error?.localizedDescription ?? "")")
        }
    }
}

// MARK: - TableViewDelegate
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        manager.messages.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        12
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let spacer = UIView()
        spacer.backgroundColor = .clear
        return spacer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: chatCellId, for: indexPath) as! ChatCell
        cell.configure(with: manager.messages[indexPath.section])
        return cell
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        clickSendButton()
        return true
    }
}
