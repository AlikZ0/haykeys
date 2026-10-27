import UIKit

final class KeyboardViewController: UIInputViewController {
    private var state = KeyboardState()
    private let root = UIStackView()
    private var suggestionRow = UIStackView()
    private var suggestionButtons: [UIButton] = []
    private var suggestions: [String] = []
    private var showingCompletions = false
    private let shortcuts = ["և", "ու", "։"]
    private var keyRows: [UIStackView] = []
    private var keyButtons: [KeyButton] = []
    private var shiftButton: KeyButton?
    private var returnButton: KeyButton?
    private var globeButton: KeyButton?
    private var hintLabel: UILabel?
    private var heightConstraint: NSLayoutConstraint?
    private var deleteTimer: Timer?
    private var previousKeyboardType: UIKeyboardType?
    private var cursorX: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryLanguage = "hy"
        buildKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyInputTraits()
        refresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopDeleting()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The system owns keyboard width. Only its height is requested here.
        let compact = view.bounds.width > 560
        let height: CGFloat = (compact ? 234 : 332) + view.safeAreaInsets.bottom
        if let heightConstraint, abs(heightConstraint.constant - height) > 0.5 {
            heightConstraint.constant = height
        }
        let fontSize: CGFloat = compact ? 22 : (view.bounds.width < 350 ? 22 : 26)
        for key in keyButtons {
            if case .insert? = key.keyAction {
                key.titleLabel?.font = .systemFont(ofSize: fontSize)
            }
        }
        globeButton?.isHidden = !needsInputModeSwitchKey
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        applyInputTraits()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refresh()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refresh()
    }

    private func applyInputTraits() {
        let type = textDocumentProxy.keyboardType ?? .default
        guard previousKeyboardType != type else { return }
        previousKeyboardType = type
        switch type {
        case .numberPad, .decimalPad, .numbersAndPunctuation, .asciiCapableNumberPad:
            state.selectPage(.numbers)
        default:
            state.selectPage(.letters)
        }
        buildKeyboard()
    }

    private func buildKeyboard() {
        stopDeleting()
        root.removeFromSuperview()
        root.arrangedSubviews.forEach { $0.removeFromSuperview() }
        suggestionRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        suggestionRow = UIStackView()
        keyRows.removeAll()
        keyButtons.removeAll()
        suggestionButtons.removeAll()
        shiftButton = nil
        returnButton = nil
        globeButton = nil

        root.axis = .vertical
        root.spacing = 6
        root.translatesAutoresizingMaskIntoConstraints = false
        root.semanticContentAttribute = .forceLeftToRight
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            root.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4)
        ])
        if heightConstraint == nil {
            let constraint = view.heightAnchor.constraint(equalToConstant: 332)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }

        suggestionRow.axis = .horizontal
        suggestionRow.distribution = .fillEqually
        suggestionRow.spacing = 1
        root.addArrangedSubview(suggestionRow)
        suggestionRow.heightAnchor.constraint(equalToConstant: 30).isActive = true
        for index in 0..<3 {
            let button = UIButton(type: .system)
            button.tag = index
            button.titleLabel?.font = .systemFont(ofSize: 17)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.55
            button.accessibilityTraits = .keyboardKey
            button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            suggestionRow.addArrangedSubview(button)
            suggestionButtons.append(button)
        }

        for (index, values) in KeyboardLayout.rows(for: state.page).enumerated() {
            let row = makeRow()
            if index == 3 {
                if state.page == .letters {
                    let key = makeKey(action: .shift, special: true)
                    key.accessibilityLabel = "Заглавные буквы"
                    key.accessibilityHint = "Двойное нажатие включает Caps Lock"
                    shiftButton = key
                    row.addArrangedSubview(key)
                } else {
                    let next: KeyboardPage = state.page == .numbers ? .symbols : .numbers
                    let key = makeKey(action: .page(next), special: true)
                    key.setTitle(next == .symbols ? "#+=" : "123", for: .normal)
                    key.accessibilityLabel = next == .symbols ? "Символы" : "Цифры"
                    key.titleLabel?.font = .systemFont(ofSize: 16)
                    row.addArrangedSubview(key)
                }
            }
            for value in values {
                row.addArrangedSubview(makeKey(action: .insert(value)))
            }
            if index == 3 {
                let key = makeKey(action: .backspace, special: true)
                key.setImage(UIImage(systemName: "delete.left"), for: .normal)
                key.accessibilityLabel = "Удалить"
                key.accessibilityHint = "Удерживайте для непрерывного удаления"
                row.addArrangedSubview(key)
            }
            root.addArrangedSubview(row)
            if let first = keyRows.first {
                row.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true
            }
            keyRows.append(row)
        }

        let bottom = makeRow()
        bottom.distribution = .fill
        let mode = makeKey(action: .page(state.page == .letters ? .numbers : .letters), special: true)
        mode.setTitle(state.page == .letters ? "123" : "ԱԲԳ", for: .normal)
        mode.titleLabel?.font = .systemFont(ofSize: 21)
        mode.accessibilityLabel = state.page == .letters ? "Цифры и символы" : "Армянские буквы"
        let space = makeKey(action: .space)
        space.accessibilityLabel = "Пробел"
        space.accessibilityHint = "Удерживайте и двигайте палец для перемещения курсора"
        let cursorGesture = UILongPressGestureRecognizer(target: self, action: #selector(moveCursor(_:)))
        cursorGesture.minimumPressDuration = 0.35
        space.addGestureRecognizer(cursorGesture)
        let lineBreak = makeKey(action: .lineBreak, special: true)
        lineBreak.titleLabel?.font = .systemFont(ofSize: 19)
        lineBreak.accessibilityLabel = "Ввод"
        returnButton = lineBreak
        [mode, space, lineBreak].forEach { bottom.addArrangedSubview($0) }
        NSLayoutConstraint.activate([
            space.widthAnchor.constraint(equalTo: mode.widthAnchor, multiplier: 2),
            lineBreak.widthAnchor.constraint(equalTo: mode.widthAnchor)
        ])
        root.addArrangedSubview(bottom)
        if let first = keyRows.first {
            bottom.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true
        }

        let controls = UIStackView()
        controls.axis = .horizontal
        controls.spacing = 8
        let globe = KeyButton(special: true)
        globe.setImage(UIImage(systemName: "globe"), for: .normal)
        globe.accessibilityLabel = "Сменить клавиатуру"
        globe.accessibilityHint = "Удерживайте, чтобы открыть список клавиатур"
        // This public API supports both a tap and the system long-press keyboard list.
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        let globeWidth = globe.widthAnchor.constraint(equalToConstant: 42)
        globeWidth.priority = .defaultHigh
        globeWidth.isActive = true
        globeButton = globe
        keyButtons.append(globe)
        let hint = UILabel()
        hint.text = "Հայերեն"
        hint.font = .systemFont(ofSize: 12)
        hint.textAlignment = .center
        hint.isAccessibilityElement = false
        hintLabel = hint
        let dismiss = makeKey(action: .dismiss, special: true)
        dismiss.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        dismiss.widthAnchor.constraint(equalToConstant: 42).isActive = true
        dismiss.accessibilityLabel = "Скрыть клавиатуру"
        let controlViews: [UIView] = [globe, hint, dismiss]
        controlViews.forEach { controls.addArrangedSubview($0) }
        root.addArrangedSubview(controls)
        controls.heightAnchor.constraint(equalToConstant: 28).isActive = true
        refresh()
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillEqually
        row.semanticContentAttribute = .forceLeftToRight
        return row
    }

    private func makeKey(action: KeyAction, special: Bool = false) -> KeyButton {
        let key = KeyButton(action: action, special: special)
        if case .backspace = action {
            key.addTarget(self, action: #selector(startDeleting), for: .touchDown)
            key.addTarget(self, action: #selector(stopDeleting),
                          for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        } else {
            key.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        }
        if case .insert(let value) = action, value == "ե" || value == "ւ" {
            key.alternateText = value == "ե" ? "և" : "ու"
            key.accessibilityHint = "Удерживайте для \(key.alternateText ?? "")"
            let alternateGesture = UILongPressGestureRecognizer(
                target: self, action: #selector(insertAlternate(_:))
            )
            alternateGesture.minimumPressDuration = 0.4
            key.addGestureRecognizer(alternateGesture)
        }
        keyButtons.append(key)
        return key
    }

    @objc private func insertAlternate(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let key = gesture.view as? KeyButton,
              let text = key.alternateText else { return }
        insert(state.output(for: text))
    }

    @objc private func keyTapped(_ sender: KeyButton) {
        guard let action = sender.keyAction else { return }
        switch action {
        case .insert(let text): insert(state.output(for: text))
        case .space: insert(" ")
        case .lineBreak: insert("\n")
        case .shift:
            state.tapShift(at: Date.timeIntervalSinceReferenceDate)
            refresh()
        case .page(let page):
            state.selectPage(page)
            buildKeyboard()
        case .dismiss: dismissKeyboard()
        case .backspace: break // Handled on touchDown, including press-and-hold.
        }
    }

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        state.didInsert(text)
        refresh()
        refreshAfterProxyUpdate()
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        guard suggestions.indices.contains(sender.tag) else { return }
        let candidate = suggestions[sender.tag]
        if showingCompletions {
            guard let suffix = WordSuggestions.suffix(
                for: candidate, context: textDocumentProxy.documentContextBeforeInput
            ) else { return }
            insert(suffix)
        } else {
            insert(state.output(for: candidate))
        }
    }

    private func refresh() {
        guard isViewLoaded else { return }
        let dark = textDocumentProxy.keyboardAppearance == .dark ||
            (textDocumentProxy.keyboardAppearance != .light && traitCollection.userInterfaceStyle == .dark)
        view.backgroundColor = dark ? UIColor(white: 0.12, alpha: 1)
            : UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1)
        for key in keyButtons {
            key.isDark = dark
            if case .insert(let value)? = key.keyAction {
                let output = state.output(for: value)
                key.setTitle(output, for: .normal)
                key.accessibilityLabel = output
            }
            key.updateColors()
        }
        let shiftIcon = state.shift == .locked ? "capslock.fill" :
            (state.shift == .once ? "shift.fill" : "shift")
        shiftButton?.setImage(UIImage(systemName: shiftIcon), for: .normal)
        shiftButton?.isActive = state.shift != .off
        shiftButton?.accessibilityValue = state.shift == .locked ? "Caps Lock" :
            (state.shift == .once ? "Одна заглавная буква" : "Строчные буквы")
        shiftButton?.updateColors()
        hintLabel?.textColor = dark ? .lightGray : .darkGray
        globeButton?.isHidden = !needsInputModeSwitchKey
        updateReturnLabel()
        updateSuggestions(dark: dark)
    }

    private func updateReturnLabel() {
        let title: String
        switch textDocumentProxy.returnKeyType ?? .default {
        case .go: title = "Գնալ"
        case .search, .google, .yahoo: title = "Որոնել"
        case .send: title = "Ուղարկել"
        case .done: title = "Պատրաստ"
        case .next: title = "Հաջորդ"
        default: title = "տող"
        }
        returnButton?.setTitle(title, for: .normal)
    }

    private func updateSuggestions(dark: Bool) {
        let matches = WordSuggestions.matches(in: textDocumentProxy.documentContextBeforeInput)
        showingCompletions = state.page == .letters && !matches.isEmpty
        suggestions = showingCompletions ? matches : shortcuts
        for (index, button) in suggestionButtons.enumerated() {
            let exists = suggestions.indices.contains(index)
            let title = exists ? suggestions[index] : ""
            button.setTitle(title, for: .normal)
            button.setTitleColor(dark ? .white : .black, for: .normal)
            button.isEnabled = exists
            button.accessibilityLabel = showingCompletions ? "Дополнить: \(title)" : title
        }
    }

    private func refreshAfterProxyUpdate() {
        DispatchQueue.main.async { [weak self] in self?.refresh() }
    }

    @objc private func startDeleting() {
        stopDeleting()
        deleteOneCharacter()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.deleteOneCharacter()
            self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.075, repeats: true) { [weak self] _ in
                self?.deleteOneCharacter()
            }
        }
    }

    private func deleteOneCharacter() {
        textDocumentProxy.deleteBackward()
        refreshAfterProxyUpdate()
    }

    @objc private func stopDeleting() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    @objc private func moveCursor(_ gesture: UILongPressGestureRecognizer) {
        let x = gesture.location(in: view).x
        switch gesture.state {
        case .began: cursorX = x
        case .changed:
            let steps = Int((x - cursorX) / 10)
            if steps != 0 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: steps)
                cursorX += CGFloat(steps) * 10
                refreshAfterProxyUpdate()
            }
        default: break
        }
    }
}
