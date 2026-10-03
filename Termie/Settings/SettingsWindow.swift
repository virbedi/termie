import SwiftUI

struct SettingsWindow: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralSettingsTab()
            }
        }
        .frame(width: 480, height: 420)
    }
}
