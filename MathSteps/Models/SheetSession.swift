import Foundation

final class SheetSession: ObservableObject {
    private(set) var problem: ArithmeticProblem
    private(set) var method: any ArithmeticMethod

    @Published private(set) var layout: SheetLayout
    @Published private(set) var steps: [SheetStep]
    @Published private(set) var marks: [SheetMark] = []
    @Published private(set) var currentStepIndex = 0
    @Published var supportLevel: SupportLevel = .guided
    @Published var selectedCellID: SheetCellID?
    @Published var feedback: String

    init(problem: ArithmeticProblem, method: any ArithmeticMethod) {
        self.problem = problem
        self.method = method
        let layout = method.makeLayout(for: problem)
        let steps = method.makeSteps(for: problem, layout: layout)
        self.layout = layout
        self.steps = steps
        self.feedback = steps.first?.prompt ?? "Start by placing a mark on the sheet."
        self.selectedCellID = steps.first?.highlightedCells.first
    }

    func reset(problem: ArithmeticProblem, method: (any ArithmeticMethod)? = nil) {
        self.problem = problem
        if let method {
            self.method = method
        }
        let layout = self.method.makeLayout(for: problem)
        let steps = self.method.makeSteps(for: problem, layout: layout)
        self.layout = layout
        self.steps = steps
        self.marks = []
        self.currentStepIndex = 0
        self.feedback = steps.first?.prompt ?? "Start by placing a mark on the sheet."
        self.selectedCellID = steps.first?.highlightedCells.first
    }

    var currentStep: SheetStep? {
        guard steps.indices.contains(currentStepIndex) else {
            return nil
        }
        return steps[currentStepIndex]
    }

    var isComplete: Bool {
        currentStepIndex >= steps.count
    }

    var activeHighlightedCells: Set<SheetCellID> {
        guard supportLevel != .independent else {
            return []
        }
        return currentStep?.highlightedCells ?? []
    }

    func state() -> SheetState {
        SheetState(
            problem: problem,
            layout: layout,
            steps: steps,
            currentStepIndex: currentStepIndex,
            marks: marks
        )
    }

    func mark(for cellID: SheetCellID) -> SheetMark? {
        marks.last { $0.cellID == cellID }
    }

    func select(_ cellID: SheetCellID) {
        guard layout.cell(id: cellID)?.isEditable == true else {
            return
        }
        selectedCellID = cellID
    }

    func enterDigit(_ digit: Int) {
        guard let selectedCellID else {
            feedback = currentStep?.prompt ?? "Choose a place on the sheet."
            return
        }

        let mark = SheetMark(cellID: selectedCellID, kind: .digit, value: String(digit))
        switch method.validate(mark: mark, in: state()) {
        case .accepted(let message):
            replaceMark(mark)
            feedback = message
            advanceIfStepComplete()
        case .rejected(let message):
            feedback = message
        case .ignored(let message):
            replaceMark(mark)
            feedback = message
        }
    }

    func clearSelectedCell() {
        guard let selectedCellID else {
            return
        }
        marks.removeAll { $0.cellID == selectedCellID }
        feedback = currentStep?.prompt ?? "Choose a place on the sheet."
    }

    func showCurrentStepMark() {
        guard let currentStep else {
            feedback = "The written work is complete."
            return
        }

        guard let expectation = currentStep.expectedMarks.first(where: { expected in
            !marks.contains {
                $0.cellID == expected.cellID &&
                $0.kind == expected.kind &&
                $0.value == expected.value
            }
        }) else {
            advanceIfStepComplete()
            return
        }

        let mark = SheetMark(
            cellID: expectation.cellID,
            kind: expectation.kind,
            value: expectation.value
        )
        replaceMark(mark)
        selectedCellID = expectation.cellID
        feedback = expectation.successMessage
        advanceIfStepComplete()
    }

    private func replaceMark(_ mark: SheetMark) {
        marks.removeAll { $0.cellID == mark.cellID }
        marks.append(mark)
    }

    private func advanceIfStepComplete() {
        guard let currentStep else {
            return
        }

        let expected = currentStep.expectedMarks
        let isComplete = expected.allSatisfy { expectation in
            marks.contains {
                $0.cellID == expectation.cellID &&
                $0.kind == expectation.kind &&
                $0.value == expectation.value
            }
        }

        guard isComplete else {
            return
        }

        currentStepIndex += 1
        if let nextStep = self.currentStep {
            selectedCellID = nextStep.highlightedCells.first
            feedback = nextStep.prompt
        } else {
            selectedCellID = nil
            feedback = "Complete. The written work shows the answer."
        }
    }
}
