import SwiftUI

struct ButtonGrid: View {
    var engine: CalcEngine
    let compact: Bool

    let rows: [[CalcBtn]] = [
        [.fn("AC"),  .fn("±"),   .fn("%"),   .op("÷", .div)],
        [.digit(7),  .digit(8),  .digit(9),  .op("×", .mul)],
        [.digit(4),  .digit(5),  .digit(6),  .op("−", .sub)],
        [.digit(1),  .digit(2),  .digit(3),  .op("+", .add)],
        [.fn("√"),   .digit(0),  .fn("1/x"), .fn("=")      ],
        [.fn("⌫"),   .fn(".")],
    ]

    var body: some View {
        VStack(spacing: compact ? 10 : 8) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: compact ? 10 : 8) {
                    ForEach(rows[r].indices, id: \.self) { c in
                        if rows[r][c] == .pad {
                            Spacer()
                        } else {
                            ButtonView(btn: rows[r][c], compact: compact) {
                                handleTap(rows[r][c])
                            }
                        }
                    }
                }
            }
        }
    }

    func handleTap(_ btn: CalcBtn) {
        switch btn {
        case .digit(let d):  engine.inputDigit(d)
        case .op(_, let op): engine.setOp(op)
        case .fn(let s):
            switch s {
            case "AC":  engine.clear()
            case "±":   engine.unaryOp("n")
            case "%":   engine.unaryOp("%")
            case "√":   engine.unaryOp("q")
            case "1/x": engine.unaryOp("r")
            case "=":   engine.equals()
            case "⌫":   engine.inputDelete()
            case ".":   engine.inputDot()
            default:    break
            }
        default: break
        }
    }
}

struct ButtonView: View {
    let btn: CalcBtn
    let compact: Bool
    let action: () -> Void

    @State private var pressed = false
    @State private var hovered = false

    var label: String {
        switch btn {
        case .digit(let d): return "\(d)"
        case .op(let s, _): return s
        case .fn(let s):    return s
        case .pad:          return ""
        }
    }

    var baseBg: Color {
        switch btn {
        case .op:                        return .orange
        case .fn(let s) where s == "=": return .orange
        case .fn:                        return Color(white: 0.35)
        case .digit:                     return Color(white: 0.22)
        case .pad:                       return .clear
        }
    }

    var fontSize: CGFloat {
        let base: CGFloat = compact ? 24 : 20
        switch btn {
        case .fn(let s) where ["AC", "1/x", "⌫"].contains(s): return base * 0.72
        default: return base
        }
    }

    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            Group {
                if label == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: fontSize * 1.1, weight: .bold))
                } else if label == "." {
                    Circle()
                        .fill(pressed ? Color.black : Color(red: 0, green: 0.9, blue: 0))
                        .frame(width: 8, height: 8)
                } else {
                    Text(label.uppercased())
                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                }
            }
            .foregroundColor(pressed ? .black : Color(red: 0, green: 0.9, blue: 0))
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(
                Rectangle()
                    .fill(pressed ? Color(red: 0, green: 0.9, blue: 0) : Color.black)
                    .border(Color(red: 0, green: 0.9, blue: 0), width: 2)
            )
        }
        .buttonStyle(.plain)
        .onHover { over in
            withAnimation(.easeOut(duration: 0.12)) { hovered = over }
        }
        ._onButtonGesture(pressing: { p in
            withAnimation(.easeOut(duration: 0.08)) { pressed = p }
        }, perform: {})
    }

    private var effectiveBg: Color { .clear }

    private var buttonHeight: CGFloat { compact ? 68 : 54 }

    private func triggerHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }
}
