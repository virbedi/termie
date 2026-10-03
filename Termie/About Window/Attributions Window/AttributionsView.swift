import SwiftUI

struct AttributionsView: View {
    var body: some View {
        ScrollView(.vertical) {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Attributions")
                        .font(.title)
                        .bold()
                    Text("Termie started from the swift-macos-template by Simon Weniger (MIT).")
                    Text("Terminal emulation is SwiftTerm by Miguel de Icaza and contributors (MIT).")
                    Text("Each tile runs your login shell, the same way VS Code and Cursor do, so your PATH, colors, and tools are the ones you already have.")
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    AttributionsView()
}
