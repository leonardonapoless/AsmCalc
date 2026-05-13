import SwiftUI

struct CompactLayout: View {
    var engine: CalcEngine
    @Binding var showHistory: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HeaderBar(engine: engine, showHistory: $showHistory)
                DisplayArea(engine: engine, compact: true)
                    .padding(.bottom, 16)
                Divider().background(Color(white: 0.15))
                ButtonGrid(engine: engine, compact: true)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }

            if showHistory {
                SlideUpHistoryPanel(engine: engine, isShowing: $showHistory)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

struct WideLayout: View {
    var engine: CalcEngine

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                HeaderBar(engine: engine, showHistory: .constant(false))
                    .padding(.bottom, 4)
                DisplayArea(engine: engine, compact: false)
                    .padding(.bottom, 16)
                Divider().background(Color(white: 0.15))
                ButtonGrid(engine: engine, compact: false)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
            .frame(maxWidth: 360)

            Rectangle()
                .fill(Color(white: 0.15))
                .frame(width: 0.5)
                .ignoresSafeArea()

            SidebarHistoryPanel(engine: engine)
                .frame(maxWidth: .infinity)
        }
    }
}
