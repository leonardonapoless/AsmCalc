import SwiftUI

struct HeaderBar: View {
    var engine: CalcEngine
    @Binding var showHistory: Bool

    var body: some View {
        HStack {
            Text("AsmCalc")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0, green: 0.8, blue: 0))
            Spacer()
        }
        .padding(.horizontal, 20)
        #if os(macOS)
        .padding(.top, 42)
        #else
        .padding(.top, 16)
        #endif
        .padding(.bottom, 8)
    }
}
