import SwiftUI

struct SlideUpHistoryPanel: View {
    var engine: CalcEngine
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(red: 0, green: 0.8, blue: 0)).frame(height: 2)
            HistoryHeader(engine: engine)
            HistoryList(engine: engine)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(Color.black)
        .gesture(
            DragGesture().onEnded { val in
                if val.translation.height > 60 {
                    withAnimation(.spring(response: 0.3)) { isShowing = false }
                }
            }
        )
    }
}

struct SidebarHistoryPanel: View {
    var engine: CalcEngine
    var body: some View {
        VStack(spacing: 0) {
            HistoryHeader(engine: engine)
                .padding(.top, 16)
            HistoryList(engine: engine)
            Spacer(minLength: 0)
        }
    }
}

struct HistoryHeader: View {
    var engine: CalcEngine

    var body: some View {
        HStack {
            Text("TAPE LOG")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0, green: 0.8, blue: 0))
            Spacer()
            if !engine.history.isEmpty {
                Button("RESET") { engine.clearHistory() }
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0, green: 0.6, blue: 0))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 44) 
        .border(width: 1, edges: [.bottom], color: Color(red: 0, green: 0.4, blue: 0))
    }
}

struct HistoryList: View {
    var engine: CalcEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if engine.history.isEmpty {
                Text("* NO DATA *")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0, green: 0.3, blue: 0))
                    .padding(20)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(engine.history.indices, id: \.self) { i in
                            Text("> " + engine.history[i].formatted.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0, green: 0.7, blue: 0))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .border(width: 0.5, edges: [.bottom], color: Color(red: 0, green: 0.2, blue: 0))
                        }
                    }
                }
            }
        }
    }
}
