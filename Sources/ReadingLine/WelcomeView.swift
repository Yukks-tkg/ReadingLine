import SwiftUI
import AppKit

struct WelcomeView: View {

    var onDismiss: () -> Void
    @State private var dontShowAgain: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 80, height: 80)

                Text("Doksen へようこそ")
                    .font(.system(size: 22, weight: .bold))

                Text("読んでいる行を見失わない、\nシンプルな読書補助ツールです。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 36)
            .padding(.bottom, 32)

            Divider()

            // Feature rows
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "cursorarrow.rays",
                    color: .orange,
                    title: "カーソルに自動追従",
                    description: "マウスを動かすだけで、読んでいる行に\nラインが追従します。"
                )
                FeatureRow(
                    icon: "text.cursor",
                    color: .blue,
                    title: "メニューバーから操作",
                    description: "画面上部のアイコンをクリックして、\nワンタッチでON/OFFできます。"
                )
                .environment(\.locale, Locale(identifier: "en_US"))
                FeatureRow(
                    icon: "slider.horizontal.3",
                    color: .purple,
                    title: "自由にカスタマイズ",
                    description: "色・太さ・透明度など、自分好みに\n細かく設定できます。"
                )
                FeatureRow(
                    icon: "keyboard",
                    color: .green,
                    title: "ショートカットキーで切り替え",
                    description: "デフォルトは ⌘⇧L。\n設定から好きなキーに変更できます。"
                )
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)

            Divider()

            // Footer
            VStack(spacing: 8) {
                Button(action: {
                    if dontShowAgain {
                        AppSettings.shared.showWelcomeOnLaunch = false
                    }
                    onDismiss()
                }) {
                    Text("始める")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                Toggle("次回以降は表示しない", isOn: $dontShowAgain)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("設定はメニューバーアイコン → 設定を開く から変更できます")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.horizontal, 60)
                    .padding(.top, 4)

                HStack(spacing: 16) {
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Button("プライバシーポリシー") {
                        NSWorkspace.shared.open(URL(string: "https://immense-engineer-7f8.notion.site/Doksen-3130dee3bb09800c954df0ed7882247b?pvs=74")!)
                    }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 24)
        }
        .frame(width: 480)
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

final class WelcomeWindowController: NSWindowController {

    convenience init(onDismiss: @escaping () -> Void) {
        let view = WelcomeView(onDismiss: onDismiss)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = ""
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
