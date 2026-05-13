import SwiftUI

enum CalcBtn: Equatable {
    case digit(Int)
    case op(String, Op)
    case fn(String)
    case pad
}
