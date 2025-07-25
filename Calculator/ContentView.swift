import SwiftUI

struct ContentView: View {
    @State private var display = "0"
    @State private var displayExpression = ""
    @State private var currentOperation: Operation?
    @State private var firstOperand: Double = 0
    @State private var isNewNumber = true

    enum Operation {
        case addition, subtraction, multiplication, division
    }

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            
            // Display the current expression
            Text(displayExpression)
                .font(.headline)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Display area for current value or result
            Text(display)
                .font(.largeTitle)
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 10)

            Spacer()

            // Buttons layout
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    CalculatorButton(label: "C", action: clear)
                    CalculatorButton(label: "+/-", action: toggleSign)
                    CalculatorButton(label: "%", action: percent)
                    CalculatorButton(label: "÷", action: { selectOperation(.division) })
                }

                HStack(spacing: 10) {
                    CalculatorButton(label: "7", action: { appendDigit("7") })
                    CalculatorButton(label: "8", action: { appendDigit("8") })
                    CalculatorButton(label: "9", action: { appendDigit("9") })
                    CalculatorButton(label: "×", action: { selectOperation(.multiplication) })
                }

                HStack(spacing: 10) {
                    CalculatorButton(label: "4", action: { appendDigit("4") })
                    CalculatorButton(label: "5", action: { appendDigit("5") })
                    CalculatorButton(label: "6", action: { appendDigit("6") })
                    CalculatorButton(label: "-", action: { selectOperation(.subtraction) })
                }

                HStack(spacing: 10) {
                    CalculatorButton(label: "1", action: { appendDigit("1") })
                    CalculatorButton(label: "2", action: { appendDigit("2") })
                    CalculatorButton(label: "3", action: { appendDigit("3") })
                    CalculatorButton(label: "+", action: { selectOperation(.addition) })
                }

                HStack(spacing: 10) {
                    CalculatorButton(label: "⌫", action: backspace)
                    CalculatorButton(label: "0", action: { appendDigit("0") })
                        .frame(maxWidth: .infinity)
                    CalculatorButton(label: ".", action: appendDecimal)
                    CalculatorButton(label: "=", action: calculateResult)
                }
            }
            .padding(10)
        }
    }

    // MARK: - Actions
    
    private func backspace() {
        guard !displayExpression.isEmpty else { return }

        // Safely remove last character
        displayExpression.removeLast()

        // Remove any trailing whitespace
        while displayExpression.last == " " {
            displayExpression.removeLast()
        }

        // If empty after removing, reset everything
        guard !displayExpression.isEmpty else {
            display = "0"
            isNewNumber = true
            return
        }

        // Get the last number token (if available)
        let tokens = displayExpression.components(separatedBy: .whitespaces)
        if let last = tokens.last, Double(last) != nil {
            display = last
            isNewNumber = false
        } else {
            display = "0"
            isNewNumber = true
        }

        // Only evaluate if the expression is safe
        if let lastChar = displayExpression.last, !"+-×÷*/".contains(lastChar) {
            evaluateExpression()
        }
    }
    
    private func appendDigit(_ digit: String) {
        if isNewNumber {
            display = digit
            isNewNumber = false
        } else {
            display += digit
        }
        displayExpression += digit
        evaluateExpression()
    }


    private func appendDecimal() {
        if isNewNumber {
            display = "0."
            isNewNumber = false
            displayExpression += "0."
        } else if !display.contains(".") {
            display += "."
            displayExpression += "."
        }
        evaluateExpression()
    }


    private func clear() {
        display = "0"
        displayExpression = ""
        currentOperation = nil
        firstOperand = 0
        isNewNumber = true
    }

    private func toggleSign() {
        if let value = Double(display) {
            display = String(-value)
            displayExpression = display
        }
    }

    private func percent() {
        if let value = Double(display) {
            display = String(value / 100)
            displayExpression = display
            isNewNumber = true
        }
    }

    private func selectOperation(_ operation: Operation) {
        if isNewNumber {
            if displayExpression.last.map({ "+-×÷".contains($0) }) == true {
                displayExpression.removeLast()
            }
        } else {
            displayExpression += operationSymbol(for: operation)
            isNewNumber = true
        }
        evaluateExpression()
    }

    
    private func evaluateExpression() {
        let trimmed = displayExpression.trimmingCharacters(in: .whitespaces)
        
        // Avoid evaluation if expression ends with an operator
        if let last = trimmed.last, "+-×÷*/".contains(last) {
            return
        }

        // Force decimal numbers (e.g., 5 → 5.0)
        let tokens = trimmed.components(separatedBy: .whitespaces)
        let floatTokens = tokens.map { token -> String in
            if let _ = Double(token) {
                return token.contains(".") ? token : "\(token).0"
            } else {
                return token
            }
        }

        let mathExpression = floatTokens.joined(separator: " ")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")

        let expression = NSExpression(format: mathExpression)
        if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
            display = String(format: "%.6f", result.doubleValue).trimmedTrailingZeros()
        } else {
            display = "Error"
        }
    }



    private func calculateResult() {
        evaluateExpression()
        displayExpression = display
        isNewNumber = true
    }

    private func operationSymbol(for operation: Operation) -> String {
        switch operation {
        case .addition: return " + "
        case .subtraction: return " - "
        case .multiplication: return " × "
        case .division: return " ÷ "
        }
    }
}

// MARK: - CalculatorButton View
struct CalculatorButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: 70)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }
}

#Preview {
    ContentView()
}

extension String {
    func trimmedTrailingZeros() -> String {
        self.replacingOccurrences(of: #"(\.\d*?[1-9])0+$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\.0+$"#, with: "", options: .regularExpression)
    }
}
