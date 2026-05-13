import SwiftUI

struct ContentView: View {
    @State private var engine = CalcEngine()
    @State private var showHistory = false
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @FocusState private var isFocused: Bool

    var isCompact: Bool { hSizeClass == .compact }

    var body: some View {
        Group {
            if isCompact {
                CompactLayout(engine: engine, showHistory: $showHistory)
            } else {
                WideLayout(engine: engine)
            }
        }
        .background(Color.black.ignoresSafeArea())
        #if os(macOS)
        .frame(minWidth: 700, maxWidth: 1000)
        .frame(height: 550)
        #endif
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .overlay(
            // scanlines effect
            GeometryReader { geo in
                Path { path in
                    for y in stride(from: 0, to: geo.size.height, by: 3) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
            }
            .allowsHitTesting(false)
        )
        .onKeyPress(.return)      { engine.equals();      return .handled }
        .onKeyPress("=")          { engine.equals();      return .handled }
        .onKeyPress(.space)       { engine.equals();      return .handled }
        .onKeyPress(.escape)      { engine.clear();       return .handled }
        .onKeyPress("c")          { engine.clear();       return .handled }
        .onKeyPress("C")          { engine.clear();       return .handled }
        .onKeyPress(.delete)      { engine.inputDelete(); return .handled }
        .onKeyPress("+")          { engine.setOp(.add);   return .handled }
        .onKeyPress("-")          { engine.setOp(.sub);   return .handled }
        .onKeyPress("*")          { engine.setOp(.mul);   return .handled }
        .onKeyPress("x")          { engine.setOp(.mul);   return .handled }
        .onKeyPress("/")          { engine.setOp(.div);   return .handled }
        .onKeyPress("%")          { engine.unaryOp("%");  return .handled }
        .onKeyPress(".")          { engine.inputDot();    return .handled }
        .onKeyPress(",")          { engine.inputDot();    return .handled }
        .onKeyPress(characters: .decimalDigits) { key in
            if let d = key.characters.first.flatMap({ Int(String($0)) }) {
                engine.inputDigit(d)
                return .handled
            }
            return .ignored
        }
    }
}
