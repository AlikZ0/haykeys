import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum SuggestionMode: Equatable { case completion, currentWord, phrase, symbol }
    private var state = KeyboardState()
    private var appliedTheme: KeyboardTheme?
    private var geometry = KeyboardGeometry(width: 402, landscape: false)
    private let root = UIStackView()
    private var suggestionRow = UIStackView()
    private var suggestionButtons: [UIButton] = []
    private var suggestions: [String] = []
    private var suggestionMode: SuggestionMode = .phrase
    private let initialPhrases = ["Բարև", "Շնորհակալություն", "Այո"]
    private var keyRows: [UIStackView] = []
    private var keyButtons: [KeyButton] = []
    private var shiftButton: KeyButton?
    private var returnButton: KeyButton?
    private var globeButton: KeyButton?
    private var spaceLanguageLabel: UILabel?
    private var bottomRow: UIStackView?
    private var suggestionHeightConstraint: NSLayoutConstraint?
    private var bottomInsetConstraint: NSLayoutConstraint?
    private var showsGlobe = false
    private var heightConstraint: NSLayoutConstraint?
    private var deleteTimer: Timer?
    private var previousKeyboardType: UIKeyboardType?
    private var cursorX: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryLanguage = "hy"
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        buildKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyInputTraits()
        refresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
        refreshAfterProxyUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopDeleting()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.bounds.width > 0 else { return }
        if appliedTheme != resolvedTheme { refresh() }
        if showsGlobe != needsInputModeSwitchKey {
            buildKeyboard()
            return
        }
        // Face ID iPhones provide the globe/dictation area outside this extension.
        let compact = traitCollection.verticalSizeClass == .compact || view.bounds.width > 560
        let next = KeyboardGeometry(width: Double(view.bounds.width), landscape: compact)
        if geometry.width != next.width || geometry.landscape != next.landscape {
            geometry = next
            updateGeometry()
        }
        let height = CGFloat(geometry.preferredHeight) + view.safeAreaInsets.bottom
        if let heightConstraint, abs(heightConstraint.constant - height) > 0.5 {
            heightConstraint.constant = height
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        applyInputTraits()
        refresh()
        refreshAfterProxyUpdate()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refresh()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        refresh()
        refreshAfterProxyUpdate()
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
        spaceLanguageLabel = nil
        showsGlobe = needsInputModeSwitchKey

        root.axis = .vertical
        root.spacing = CGFloat(geometry.rowGap)
        root.translatesAutoresizingMaskIntoConstraints = false
        root.semanticContentAttribute = .forceLeftToRight
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            root.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        let bottomInset = root.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -CGFloat(geometry.bottomInset)
        )
        bottomInset.isActive = true
        bottomInsetConstraint = bottomInset
        if heightConstraint == nil {
            let constraint = view.heightAnchor.constraint(equalToConstant: CGFloat(geometry.preferredHeight))
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }

        suggestionRow.axis = .horizontal
        suggestionRow.distribution = .fillEqually
        suggestionRow.spacing = 1
        root.addArrangedSubview(suggestionRow)
        let suggestionHeight = suggestionRow.heightAnchor.constraint(equalToConstant: CGFloat(geometry.suggestionHeight))
        suggestionHeight.isActive = true
        suggestionHeightConstraint = suggestionHeight
        for index in 0..<3 {
            let button = UIButton(type: .system)
            button.tag = index
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.65
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
        bottomRow = bottom
        let mode = makeKey(action: .page(state.page == .letters ? .numbers : .letters), special: true)
        mode.setTitle(state.page == .letters ? "123" : "ԱԲԳ", for: .normal)
        mode.titleLabel?.font = .systemFont(ofSize: 20)
        mode.accessibilityLabel = state.page == .letters ? "Цифры и символы" : "Армянские буквы"
        let space = makeKey(action: .space)
        space.accessibilityLabel = "Пробел"
        space.accessibilityHint = "Удерживайте и двигайте палец для перемещения курсора"
        let cursorGesture = UILongPressGestureRecognizer(target: self, action: #selector(moveCursor(_:)))
        cursorGesture.minimumPressDuration = 0.35
        space.addGestureRecognizer(cursorGesture)
        let language = UILabel()
        language.text = "Հայերեն"
        language.font = .systemFont(ofSize: 9, weight: .regular)
        language.isUserInteractionEnabled = false
        language.isAccessibilityElement = false
        language.translatesAutoresizingMaskIntoConstraints = false
        space.addSubview(language)
        NSLayoutConstraint.activate([
            language.trailingAnchor.constraint(equalTo: space.trailingAnchor, constant: -7),
            language.bottomAnchor.constraint(equalTo: space.bottomAnchor, constant: -4)
        ])
        spaceLanguageLabel = language
        let lineBreak = makeKey(action: .lineBreak, special: true)
        lineBreak.titleLabel?.font = .systemFont(ofSize: 16)
        lineBreak.titleLabel?.minimumScaleFactor = 0.65
        lineBreak.accessibilityLabel = "Ввод"
        lineBreak.accessibilityHint = "Удерживайте, чтобы скрыть клавиатуру"
        lineBreak.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(hideKeyboard(_:))))
        returnButton = lineBreak
        bottom.addArrangedSubview(mode)
        if showsGlobe {
            let globe = KeyButton(special: true)
            globe.setImage(UIImage(systemName: "globe"), for: .normal)
            globe.accessibilityLabel = "Сменить клавиатуру"
            globe.accessibilityHint = "Удерживайте, чтобы открыть список клавиатур"
            globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
            bottom.addArrangedSubview(globe)
            globe.widthAnchor.constraint(equalTo: mode.widthAnchor).isActive = true
            globeButton = globe
            keyButtons.append(globe)
        }
        let ligature = makeKey(action: .insert(KeyboardLayout.ligature))
        ligature.accessibilityLabel = "և — армянская лигатура"
        [ligature, space, lineBreak].forEach { bottom.addArrangedSubview($0) }
        NSLayoutConstraint.activate([
            ligature.widthAnchor.constraint(equalTo: mode.widthAnchor),
            space.widthAnchor.constraint(equalTo: mode.widthAnchor, multiplier: 4.5),
            lineBreak.widthAnchor.constraint(equalTo: mode.widthAnchor, multiplier: 2.2)
        ])
        root.addArrangedSubview(bottom)
        if let first = keyRows.first {
            bottom.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true
        }

        updateGeometry()
        refresh()
    }

    private func updateGeometry() {
        root.spacing = CGFloat(geometry.rowGap)
        suggestionHeightConstraint?.constant = CGFloat(geometry.suggestionHeight)
        bottomInsetConstraint?.constant = -CGFloat(geometry.bottomInset)
        let rows = KeyboardLayout.rows(for: state.page)
        for (index, row) in keyRows.enumerated() {
            let count = rows[index].count + (index == 3 ? 2 : 0)
            let inset = CGFloat(geometry.inset(for: count))
            row.spacing = CGFloat(geometry.keyGap)
            row.isLayoutMarginsRelativeArrangement = true
            row.insetsLayoutMarginsFromSafeArea = false
            row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        }
        bottomRow?.spacing = CGFloat(geometry.keyGap)
        for key in keyButtons {
            if case .insert? = key.keyAction {
                key.titleLabel?.font = .systemFont(ofSize: CGFloat(geometry.fontSize), weight: .regular)
            }
        }
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = CGFloat(geometry.keyGap)
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
        switch suggestionMode {
        case .completion:
            guard let suffix = WordSuggestions.suffix(
                for: candidate, context: textDocumentProxy.documentContextBeforeInput
            ) else { return }
            insert(suffix)
        case .currentWord:
            guard WordSuggestions.currentPrefix(in: textDocumentProxy.documentContextBeforeInput) == candidate else { return }
            insert(" ")
        case .phrase:
            insert((state.shift == .locked ? candidate.uppercased() : candidate) + " ")
        case .symbol:
            insert(candidate)
        }
    }

    private var resolvedTheme: KeyboardTheme {
        let interfaceIsDark = traitCollection.userInterfaceStyle == .dark ||
            view.traitCollection.userInterfaceStyle == .dark ||
            view.window?.traitCollection.userInterfaceStyle == .dark
        return KeyboardTheme.resolve(
            interfaceIsDark: interfaceIsDark,
            fieldRequestsDark: textDocumentProxy.keyboardAppearance == .dark
        )
    }

    private func refresh() {
        guard isViewLoaded else { return }
        let theme = resolvedTheme
        appliedTheme = theme
        let dark = theme == .dark
        view.backgroundColor = dark ? UIColor(white: 0.12, alpha: 1)
            : UIColor(red: 0.885, green: 0.889, blue: 0.907, alpha: 1)
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
        spaceLanguageLabel?.textColor = (dark ? UIColor.white : UIColor.black).withAlphaComponent(0.28)
        updateReturnLabel()
        updateSuggestions(dark: dark)
    }

    private func updateReturnLabel() {
        let title: String?
        switch textDocumentProxy.returnKeyType ?? .default {
        case .go: title = "Գնալ"
        case .search, .google, .yahoo: title = "Որոնել"
        case .send: title = "Ուղարկել"
        case .done: title = "Պատրաստ"
        case .next: title = "Հաջորդ"
        default: title = nil
        }
        returnButton?.setTitle(title, for: .normal)
        returnButton?.setImage(title == nil ? UIImage(systemName: "return") : nil, for: .normal)
    }

    private func updateSuggestions(dark: Bool) {
        let context = textDocumentProxy.documentContextBeforeInput
        let prefix = WordSuggestions.currentPrefix(in: context)
        let matches = WordSuggestions.matches(in: context)
        if state.page != .letters {
            suggestionMode = .symbol
            suggestions = ["։", "՝", "՞"]
        } else if !matches.isEmpty {
            suggestionMode = .completion
            suggestions = matches
        } else if !prefix.isEmpty {
            suggestionMode = .currentWord
            suggestions = [prefix]
        } else {
            suggestionMode = .phrase
            suggestions = initialPhrases
        }
        for (index, button) in suggestionButtons.enumerated() {
            let exists = suggestions.indices.contains(index)
            let title = exists ? suggestions[index] : ""
            button.setTitle(title, for: .normal)
            button.setTitleColor(dark ? .white : .black, for: .normal)
            button.isEnabled = exists
            button.accessibilityLabel = suggestionMode == .completion ? "Дополнить: \(title)" : title
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

    @objc private func hideKeyboard(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { dismissKeyboard() }
    }

    @objc private func moveCursor(_ gesture: UILongPressGestureRecognizer) {
        let x = gesture.location(in: view).x
        switch gesture.state {
        case .began:
            cursorX = x
            spaceLanguageLabel?.text = "↔"
        case .changed:
            let steps = Int((x - cursorX) / 10)
            if steps != 0 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: steps)
                cursorX += CGFloat(steps) * 10
                refreshAfterProxyUpdate()
            }
        case .ended, .cancelled, .failed:
            spaceLanguageLabel?.text = "Հայերեն"
        default: break
        }
    }
}
