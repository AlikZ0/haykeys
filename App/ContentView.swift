import SwiftUI
import UIKit

struct ContentView: View {
    @State private var practice = ""
    @StateObject private var historyStore = ClipboardStore()
    @State private var savedCopy = false
    @FocusState private var practicing: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Հայերեն").font(.system(size: 38, weight: .semibold))
                        Text("Армянская клавиатура с раскладкой по образцу. Работает без интернета и полного доступа.")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

                    NavigationLink {
                        ClipboardHistoryView(store: historyStore)
                    } label: {
                        Label("История буфера · до 100 текстов", systemImage: "doc.on.clipboard")
                            .font(.headline)
                    }
                    .padding(18).background(Color(.secondarySystemGroupedBackground)).cornerRadius(18)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Подключить клавиатуру").font(.headline)
                        step(1, "Откройте настройки iPhone", "Основные → Клавиатура → Клавиатуры → Новые клавиатуры.")
                        step(2, "Добавьте HayKeys", "В разделе сторонних клавиатур выберите HayKeys Armenian. Полный доступ не требуется.")
                        step(3, "Выберите её при вводе", "Нажмите поле ниже. Удерживайте 🌐 и выберите HayKeys Armenian.")
                        Button("Открыть настройки приложения") {
                            practicing = false
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        Text("Кнопка открывает настройки приложения. Если пункта «Клавиатуры» там нет, пройдите по пути из шага 1.")
                            .font(.footnote).foregroundColor(.secondary)
                    }
                    .padding(18).background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(18)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Попробуйте написать").font(.headline)
                        Text("Например: Բարև, շնորհակալություն։")
                            .font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $practice)
                            .font(.system(size: 24))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .focused($practicing)
                            .frame(height: 170)
                            .padding(6)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .accessibilityLabel("Поле для проверки армянской клавиатуры")
                        HStack {
                            Button("Очистить") { practice = "" }
                            Spacer()
                            Button("Скрыть клавиатуру") { practicing = false }
                        }
                        .font(.subheadline)
                        Button("Копировать и сохранить весь текст") {
                            historyStore.add([practice])
                            if historyStore.error == nil {
                                UIPasteboard.general.string = practice
                                savedCopy = true
                            }
                        }
                        .disabled(practice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if let error = historyStore.error { Text(error).font(.footnote).foregroundColor(.red) }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Управление").font(.headline)
                        Text("⇧ — одна заглавная буква; два быстрых нажатия — Caps Lock. Удерживайте ⌫ для удаления. Удерживайте пробел и двигайте палец, чтобы перемещать курсор.")
                        Text("«և» находится в верхнем ряду на месте дефиса. Кнопка 123 расширена и открывает цифры; #+= — символы; ԱԲԳ возвращает буквы. Верхняя панель слов удалена.")
                        Text("Удержание «ե» вводит «և», а удержание «ւ» вводит «ու». Дефис доступен на странице цифр.")
                        Text("Чтобы скрыть клавиатуру, удерживайте клавишу ввода. Надпись «Հայերեն» перенесена на пробел, дополнительной нижней полосы нет.")
                        Text("В полях паролей и некоторых приложениях iOS показывает системную клавиатуру. Для диктовки переключитесь на системную клавиатуру через 🌐.")
                    }
                    .font(.subheadline)

                    Text("Клавиатура не сохраняет набранный текст. В приложении сохраняются только тексты, которые вы сами вставили в историю буфера. Нет отправки в сеть и аналитики. Полный доступ не требуется.")
                        .font(.footnote).foregroundColor(.secondary)
                    Text("Версия \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                        .font(.footnote).foregroundColor(.secondary)
                    Text("Бесплатная подпись действует 7 дней. При установке через SideStore продлевайте HayKeys и SideStore до её истечения. При установке через Xcode снова запустите проект на этом iPhone.")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("HayKeys")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Текст скопирован и сохранён в историю", isPresented: $savedCopy) {
            Button("ОК", role: .cancel) {}
        }
        .navigationViewStyle(.stack)
        .tint(Color(red: 0.35, green: 0.29, blue: 0.78))
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.weight(.semibold))
                .frame(width: 26, height: 26)
                .background(Color.accentColor.opacity(0.12)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.subheadline).foregroundColor(.secondary)
            }
        }
    }
}

/// This store belongs to the containing app, not the keyboard extension.
final class ClipboardStore: ObservableObject {
    @Published private(set) var history = ClipboardHistory()
    @Published var error: String?
    private var fileURL: URL?
    private var readable = true

    init() {
        do {
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            ).appendingPathComponent("HayKeys", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("clipboard.json")
            fileURL = url
            if FileManager.default.fileExists(atPath: url.path) {
                let saved = try JSONDecoder().decode(ClipboardHistory.self, from: Data(contentsOf: url))
                // Normalize old or oversized files without changing their ordering.
                var normalized = ClipboardHistory()
                for item in saved.entries.reversed() { normalized.add(item.text, date: item.date) }
                history = normalized
            }
        } catch {
            readable = false
            self.error = "Не удалось открыть историю. Существующий файл не перезаписан: \(error.localizedDescription)"
        }
    }

    func add(_ values: [String]) {
        var updated = history
        for value in values { updated.add(value) }
        save(updated)
    }

    func remove(_ id: UUID) {
        var updated = history
        updated.remove(id: id)
        save(updated)
    }

    func clear() {
        save(ClipboardHistory(), replacingUnreadable: true)
    }

    private func save(_ updated: ClipboardHistory, replacingUnreadable: Bool = false) {
        guard readable || replacingUnreadable else {
            error = "История недоступна. Чтобы начать заново, используйте «Удалить всю историю»."
            return
        }
        guard let fileURL else {
            error = "Папка истории недоступна. Попробуйте перезапустить HayKeys."
            return
        }
        do {
            let data = try JSONEncoder().encode(updated)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: fileURL.deletingLastPathComponent().path)
            var resourceURL = fileURL
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try resourceURL.setResourceValues(values)
            history = updated
            readable = true
            error = nil
        } catch {
            self.error = "Не удалось сохранить историю: \(error.localizedDescription)"
        }
    }
}

struct ClipboardHistoryView: View {
    @ObservedObject var store: ClipboardStore
    @State private var confirmClear = false
    @State private var copied = false

    var body: some View {
        List {
            Section {
                PasteButton(payloadType: String.self) { strings in store.add(strings) }
                    .labelStyle(.titleAndIcon)
                Text("Вставить в историю: скопируйте текст в любом приложении, откройте этот экран и нажмите кнопку выше. Хранятся последние 100 разных текстов; повтор перемещается в начало.")
                    .font(.footnote).foregroundColor(.secondary)
                Text("Автоматического перехвата копирования в других приложениях нет. Здесь сохраняются только тексты, которые вы сами добавили. Изображения и файлы не сохраняются.")
                    .font(.footnote).foregroundColor(.secondary)
                Text("\(store.history.entries.count) / 100")
                    .font(.caption).foregroundColor(.secondary)
            }
            if let error = store.error {
                Section { Text(error).foregroundColor(.red) }
            }
            if store.history.entries.isEmpty {
                Section { Text("История пуста").foregroundColor(.secondary) }
            }
            ForEach(store.history.entries) { entry in
                Section {
                    Text(entry.text).textSelection(.enabled)
                    HStack {
                        Text(entry.date, style: .date).font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = entry.text
                            copied = true
                        } label: { Label("Копировать", systemImage: "doc.on.doc") }
                        .buttonStyle(.borderless)
                        Button(role: .destructive) { store.remove(entry.id) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Удалить запись")
                    }
                }
            }
            Section {
                Button("Удалить всю историю", role: .destructive) { confirmClear = true }
                    .disabled(store.history.entries.isEmpty && store.error == nil)
                Text("Записи хранятся в приложении на этом iPhone и не отправляются в сеть. История не включается в резервную копию; удаление приложения удалит её.")
                    .font(.footnote).foregroundColor(.secondary)
            }
        }
        .navigationTitle("История буфера")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Скопировано", isPresented: $copied) { Button("ОК", role: .cancel) {} }
        .confirmationDialog("Удалить всю историю?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) { store.clear() }
        }
    }
}
