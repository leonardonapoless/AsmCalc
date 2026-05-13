// wraps all the asm_ calls and handles display formatting
// keeping this separate from the UI makes things a lot cleaner

import Foundation
import Observation

// which op is pending
enum Op: Int32 {
    case add  = 43  // +
    case sub  = 45  // -
    case mul  = 42  // *
    case div  = 47  // /
    case none = 0
}

// one history entry, mirroring the C struct in the asm buffer
struct HistEntry {
    let a:      Double
    let b:      Double
    let result: Double
    let op:     Character

    var formatted: String {
        let fa = CalcEngine.format(a)
        let fb = CalcEngine.format(b)
        let fr = CalcEngine.format(result)

        switch op {
        case "q": return "√\(fa) = \(fr)"
        case "n": return "±\(fa) = \(fr)"
        case "%": return "\(fa)% = \(fr)"
        case "r": return "1/\(fa) = \(fr)"
        default:  return "\(fa) \(op) \(fb) = \(fr)"
        }
    }
}

@Observable
class CalcEngine {

    var displayString: String = "0"
    var expressionString: String = ""
    var history: [HistEntry] = []

    private var accumulator: Double = 0
    private var pendingOp: Op = .none
    private var pendingOperand: Double = 0
    private var justEvaluated: Bool = false
    private var lastB: Double = 0             // needed for repeat =
    private var freshInput: Bool = true

    // MARK: - input
    func inputDigit(_ d: Int) {
        if justEvaluated || freshInput {
            displayString = "\(d)"
            freshInput = false
            justEvaluated = false
        } else {
            // don't let it grow past 15 chars
            guard displayString.count < 15 else { return }
            displayString = (displayString == "0") ? "\(d)" : displayString + "\(d)"
        }
    }

    func inputDot() {
        if justEvaluated || freshInput {
            displayString = "0."
            freshInput = false
            justEvaluated = false
            return
        }
        guard !displayString.contains(".") else { return }
        displayString += "."
    }

    func inputDelete() {
        guard !freshInput && !justEvaluated else { return }
        if displayString.count <= 1 || (displayString.count == 2 && displayString.hasPrefix("-")) {
            displayString = "0"
            freshInput = true
        } else {
            displayString = String(displayString.dropLast())
        }
    }

    // MARK: - operations
    func setOp(_ op: Op) {
        // if there's already a pending op, evaluate first
        if pendingOp != .none && !freshInput {
            evaluate(storeHistory: true)
        } else {
            pendingOperand = currentValue
        }
        pendingOp = op
        expressionString = "\(Self.format(pendingOperand)) \(opSymbol(op))"
        freshInput = true
        justEvaluated = false
    }

    func equals() {
        if justEvaluated {
            // repeat last operation with same b
            let a = currentValue
            let result = applyOp(pendingOp, a: a, b: lastB)
            pushHistory(a: a, b: lastB, result: result, opChar: opChar(pendingOp))
            displayString = Self.format(result)
            expressionString = ""
            return
        }

        guard pendingOp != .none else { return }
        evaluate(storeHistory: true)
        expressionString = ""
        justEvaluated = true
    }

    func unaryOp(_ op: Character) {
        let a = currentValue
        let result: Double

        switch op {
        case "q": result = asm_fsqrt(a)
        case "n": result = asm_fneg(a)
        case "%": result = asm_fpct(a)
        case "r": result = asm_neon_reciprocal(a)
        default:  return
        }

        pushHistory(a: a, b: 0, result: result, opChar: op)
        displayString = Self.format(result)
        freshInput = true
        justEvaluated = false
        expressionString = ""
    }

    func clear() {
        displayString = "0"
        expressionString = ""
        accumulator = 0
        pendingOp = .none
        pendingOperand = 0
        freshInput = true
        justEvaluated = false
    }

    func clearHistory() {
        asm_hist_clear()
        history = []
    }

    // MARK: - private
    private func evaluate(storeHistory: Bool) {
        let b = currentValue
        let result = applyOp(pendingOp, a: pendingOperand, b: b)

        if storeHistory {
            pushHistory(a: pendingOperand, b: b, result: result, opChar: opChar(pendingOp))
        }

        lastB = b
        displayString = Self.format(result)
        pendingOperand = result
        freshInput = true
    }

    private func applyOp(_ op: Op, a: Double, b: Double) -> Double {
        switch op {
        case .add:  return asm_fadd(a, b)
        case .sub:  return asm_fsub(a, b)
        case .mul:  return asm_fmul(a, b)
        case .div:  return asm_fdiv(a, b)
        case .none: return a
        }
    }

    private func pushHistory(a: Double, b: Double, result: Double, opChar: Character) {
        let opCode = Int32(opChar.asciiValue ?? 0)
        asm_hist_push(a, b, result, opCode)
        reloadHistory()
    }

    func reloadHistory() {
        let count = Int(asm_hist_count())
        var entries: [HistEntry] = []

        for i in 0..<count {
            var outA:   Double  = 0
            var outB:   Double  = 0
            var outRes: Double  = 0
            var outOp:  Int32   = 0

            asm_hist_get(Int64(i), &outA, &outB, &outRes, &outOp)

            let opChar = Character(UnicodeScalar(UInt32(outOp))!)
            entries.append(HistEntry(a: outA, b: outB, result: outRes, op: opChar))
        }

        // reverse so newest is at top
        history = entries.reversed()
    }

    // MARK: - formatting
    static func format(_ v: Double) -> String {
        if v.isNaN    { return "Error" }
        if v.isInfinite { return v > 0 ? "∞" : "-∞" }

        // show integer form when there's no fractional part, up to a reasonable size
        if v == v.rounded() && abs(v) < 1e12 {
            return String(format: "%.0f", v)
        }

        // otherwise up to 10 significant digits, stripping trailing zeros
        let s = String(format: "%.10g", v)
        return s
    }

    private var currentValue: Double {
        Double(displayString) ?? 0
    }

    private func opSymbol(_ op: Op) -> String {
        switch op {
        case .add:  return "+"
        case .sub:  return "−"
        case .mul:  return "×"
        case .div:  return "÷"
        case .none: return ""
        }
    }

    private func opChar(_ op: Op) -> Character {
        switch op {
        case .add:  return "+"
        case .sub:  return "-"
        case .mul:  return "*"
        case .div:  return "/"
        case .none: return "?"
        }
    }
}


