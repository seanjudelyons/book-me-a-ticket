import SwiftUI
import ApplicationServices

// MARK: - Main App
@main
struct MouseControlApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 300, height: 400)
        }
        .defaultSize(width: 300, height: 400)
        .windowStyle(.hiddenTitleBar)
    }
}

// MARK: - Models
class MouseControlState: ObservableObject {
    @Published var credits: Int = 10
    @Published var currentX: String = "400"
    @Published var currentY: String = "400"
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var isMoving = false
    
    func moveMouse() {
        guard credits > 0 else {
            alertMessage = "You've run out of credits! Purchase more to continue."
            showingAlert = true
            return
        }
        
        guard let x = Double(currentX),
              let y = Double(currentY) else {
            alertMessage = "Please enter valid coordinates"
            showingAlert = true
            return
        }
        
        let point = CGPoint(x: x, y: y)
        
        // Animate the credit deduction
        withAnimation {
            isMoving = true
            credits -= 1
        }
        
        // Create and post mouse movement event
        if let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                            mouseCursorPosition: point, mouseButton: .left) {
            move.post(tap: .cghidEventTap)
        }
        
        // Reset the moving state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                self.isMoving = false
            }
        }
    }
}

// MARK: - Views
struct ContentView: View {
    @StateObject private var state = MouseControlState()
    
    var body: some View {
        ZStack {
            // Background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Credits Display
                CreditsView(credits: state.credits)
                    .scaleEffect(state.isMoving ? 0.95 : 1.0)
                
                // Coordinate Inputs
                CoordinateInputs(
                    currentX: $state.currentX,
                    currentY: $state.currentY
                )
                
                // Move Button
                Button(action: state.moveMouse) {
                    HStack {
                        Image(systemName: "cursorarrow.motionlines")
                        Text("Move Mouse")
                    }
                    .frame(minWidth: 150)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.credits <= 0)
                .scaleEffect(state.isMoving ? 0.95 : 1.0)
                
                // Current Position Display
                CurrentPositionView()
                
                Spacer()
                
                // Purchase Credits Button
                Button("Purchase Credits") {
                    // Implement purchase flow
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .frame(width: 300, height: 400)
        }
        .alert("Notice", isPresented: $state.showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(state.alertMessage)
        }
    }
}

struct CreditsView: View {
    let credits: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(credits)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
            
            Text("Credits Remaining")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 2)
        )
    }
}

struct CoordinateInputs: View {
    @Binding var currentX: String
    @Binding var currentY: String
    
    var body: some View {
        HStack(spacing: 16) {
            CoordinateField(label: "X", value: $currentX)
            CoordinateField(label: "Y", value: $currentY)
        }
    }
}

struct CoordinateField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("0", text: $value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
        }
    }
}

struct CurrentPositionView: View {
    @State private var currentPosition = CGPoint.zero
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Current Position")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("(\(Int(currentPosition.x)), \(Int(currentPosition.y)))")
                .font(.system(.body, design: .monospaced))
                .onReceive(timer) { _ in
                    if let event = CGEvent(source: nil) {
                        currentPosition = event.location
                    }
                }
        }
        .padding(.vertical)
    }
}
