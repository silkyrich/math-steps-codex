import Foundation

enum ArithmeticOperation: String, CaseIterable {
    case addition
    case subtraction
    case multiplication
    case division

    var symbol: String {
        switch self {
        case .addition:
            return "+"
        case .subtraction:
            return "-"
        case .multiplication:
            return "x"
        case .division:
            return "÷"
        }
    }

    var label: String {
        switch self {
        case .addition:
            return "Addition"
        case .subtraction:
            return "Subtraction"
        case .multiplication:
            return "Multiplication"
        case .division:
            return "Division"
        }
    }
}

struct ArithmeticProblem: Equatable {
    var operands: [Int]
    var operation: ArithmeticOperation
}

enum SheetMarkKind: Equatable {
    case digit
    case operatorSymbol
    case ruleLine
    case crossOut
    case decimalPoint
}

enum SheetCellRole: Equatable {
    case operandDigit(operandIndex: Int)
    case operatorSymbol
    case answerDigit
    case carryDigit
    case borrowMark
    case regroupedDigit
    case partialProductDigit(row: Int)
    case quotientDigit
    case remainderDigit
    case workingDigit
    case ruleLine
}

struct SheetCellID: Hashable {
    var row: Int
    var column: Int
}

struct SheetRow: Identifiable, Equatable {
    var id: Int
    var label: String?
    var role: SheetRowRole
}

enum SheetRowRole: Equatable {
    case carry
    case operand(index: Int)
    case answer
    case working(index: Int)
    case quotient
    case divider
}

struct SheetColumn: Identifiable, Equatable {
    var id: Int
    var place: Int
    var label: String
}

struct SheetCell: Identifiable, Equatable {
    var id: SheetCellID
    var role: SheetCellRole
    var fixedText: String?
    var isEditable: Bool
}

struct SheetLayout: Equatable {
    var rows: [SheetRow]
    var columns: [SheetColumn]
    var cells: [SheetCell]

    func cell(id: SheetCellID) -> SheetCell? {
        cells.first { $0.id == id }
    }
}

struct SheetMark: Identifiable, Equatable {
    var id = UUID()
    var cellID: SheetCellID
    var kind: SheetMarkKind
    var value: String
}

struct ExpectedMark: Equatable {
    var cellID: SheetCellID
    var kind: SheetMarkKind
    var value: String
    var successMessage: String
    var mistakeMessage: String
}

enum SupportLevel: String, CaseIterable, Identifiable {
    case independent
    case guided
    case worked

    var id: String { rawValue }
}

enum SheetActionKind: Equatable {
    case writeDigit
    case regroup
    case crossOut
    case writeWorking
}

struct SheetAction: Identifiable, Equatable {
    var id = UUID()
    var kind: SheetActionKind
    var title: String
    var prompt: String
    var highlightedCells: Set<SheetCellID>
    var expectedMarks: [ExpectedMark]
}

struct SheetStep: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var prompt: String
    var highlightedCells: Set<SheetCellID>
    var actions: [SheetAction]

    var expectedMarks: [ExpectedMark] {
        actions.flatMap(\.expectedMarks)
    }

    init(
        title: String,
        prompt: String,
        highlightedCells: Set<SheetCellID>,
        actions: [SheetAction]
    ) {
        self.title = title
        self.prompt = prompt
        self.highlightedCells = highlightedCells
        self.actions = actions
    }

    init(
        title: String,
        prompt: String,
        highlightedCells: Set<SheetCellID>,
        expectedMarks: [ExpectedMark]
    ) {
        self.title = title
        self.prompt = prompt
        self.highlightedCells = highlightedCells
        self.actions = [
            SheetAction(
                kind: .writeDigit,
                title: title,
                prompt: prompt,
                highlightedCells: highlightedCells,
                expectedMarks: expectedMarks
            )
        ]
    }
}

enum ValidationResult: Equatable {
    case accepted(message: String)
    case rejected(message: String)
    case ignored(message: String)
}

enum PlaceValue {
    static func digit(_ number: Int, atPlace place: Int) -> Int {
        abs(number) / Int(pow(10.0, Double(place))) % 10
    }

    static func digitText(_ number: Int, atPlace place: Int) -> String? {
        let text = String(abs(number))
        guard place < text.count else {
            return nil
        }
        return String(text[text.index(text.endIndex, offsetBy: -place - 1)])
    }

    static func digitsByPlace(_ number: Int) -> [Int: Int] {
        var value = abs(number)
        var place = 0
        var result: [Int: Int] = [:]

        repeat {
            result[place] = value % 10
            value /= 10
            place += 1
        } while value > 0

        return result
    }

    static func label(for place: Int) -> String {
        switch place {
        case 0:
            return "ones"
        case 1:
            return "tens"
        case 2:
            return "hundreds"
        case 3:
            return "thousands"
        default:
            return "10^\(place)"
        }
    }
}
