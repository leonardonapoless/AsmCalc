import SwiftUI

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat { edge == .trailing ? rect.maxX - width : rect.minX }
            var y: CGFloat { edge == .bottom ? rect.maxY - width : rect.minY }
            var w: CGFloat { edge == .top || edge == .bottom ? rect.width : width }
            var h: CGFloat { edge == .leading || edge == .trailing ? rect.height : width }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}
