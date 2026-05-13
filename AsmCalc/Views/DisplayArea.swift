import SwiftUI

struct DisplayArea: View {
    var engine: CalcEngine
    let compact: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(engine.expressionString.isEmpty ? "" : "EXPR: " + engine.expressionString)
                .font(.system(size: compact ? 15 : 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0, green: 0.6, blue: 0))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)

            HStack(alignment: .center, spacing: 8) {
                Text(">")
                    .font(.system(size: displayFontSize * 0.55, weight: .bold, design: .monospaced))
                    .offset(y: 2) 
                Text(engine.displayString)
                    .contentTransition(.numericText())
            }
            .font(.system(size: displayFontSize, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0, green: 1.0, blue: 0))
            .shadow(color: Color(red: 0, green: 1.0, blue: 0).opacity(0.5), radius: 5)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .animation(.none, value: engine.displayString)
        }
        .frame(minHeight: compact ? 100 : 80, alignment: .bottom)
        .padding(.horizontal, 20)
    }

    private var displayFontSize: CGFloat {
        let len = engine.displayString.count
        let base: CGFloat = compact ? 58 : 48
        if len <= 9  { return base }
        if len <= 12 { return base * 0.78 }
        return base * 0.60
    }
}
