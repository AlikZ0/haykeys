import SwiftUI
import UIKit

struct ContentView: View {
    @State private var practice = ""
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
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Управление").font(.headline)
                        Text("⇧ — одна заглавная буква; два быстрых нажатия — Caps Lock. Удерживайте ⌫ для удаления. Удерживайте пробел и двигайте палец, чтобы перемещать курсор.")
                        Text("123 открывает цифры; #+= — символы; ԱԲԳ возвращает буквы. Над клавишами есть «և», «ու», «։» или подсказки из небольшого словаря.")
                        Text("Удержание «ե» вводит «և», а удержание «ւ» вводит «ու». Эти варианты доступны и во время показа подсказок.")
                        Text("В полях паролей и некоторых приложениях iOS показывает системную клавиатуру. Для диктовки переключитесь на системную клавиатуру через 🌐.")
                    }
                    .font(.subheadline)

                    Text("HayKeys не сохраняет набранные тексты, не отправляет их в сеть и не содержит аналитики. Текст в поле проверки хранится только в памяти этого экрана.")
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
