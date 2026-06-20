import SwiftUI

/// Pro: build a custom breathing rhythm. A live preview circle runs one cycle so the rhythm
/// can be felt before saving.
struct PatternBuilderView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = "My Pattern"
    @State private var inhale = 4.0
    @State private var holdIn = 4.0
    @State private var exhale = 4.0
    @State private var holdOut = 0.0
    @State private var previewScale: CGFloat = 0.45
    @State private var previewTask: Task<Void, Never>?

    private var draft: BreathPattern {
        CustomPatternDTO(id: "preview", name: name, inhale: inhale, holdIn: holdIn,
                         exhale: exhale, holdOut: holdOut).asPattern()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EaseBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        BreathingCircle(scale: previewScale, base: 180)
                            .padding(.top, 10)
                        Text(draft.detail).font(.headline).foregroundStyle(.secondary)

                        VStack(spacing: 16) {
                            slider("Breathe in", value: $inhale, range: 1...12)
                            slider("Hold", value: $holdIn, range: 0...12)
                            slider("Breathe out", value: $exhale, range: 1...12)
                            slider("Hold", value: $holdOut, range: 0...12)
                        }
                        .easeCard()
                        .padding(.horizontal)

                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        Button {
                            appModel.addCustomPattern(name: name, inhale: inhale, holdIn: holdIn,
                                                      exhale: exhale, holdOut: holdOut)
                            Haptics.success()
                            dismiss()
                        } label: {
                            Text("Save pattern").frame(maxWidth: .infinity).padding(.vertical, 4)
                        }
                        .prominentButton()
                        .accessibilityIdentifier("save-pattern")
                        .padding(.horizontal).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("New pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .tint(Color.easeAccent)
            .onAppear { runPreview() }
            .onDisappear { previewTask?.cancel() }
            .onChange(of: [inhale, holdIn, exhale, holdOut]) { _, _ in runPreview() }
        }
    }

    private func slider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(String(format: value.wrappedValue == value.wrappedValue.rounded() ? "%.0fs" : "%.1fs", value.wrappedValue))
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.5).tint(Color.easeAccent)
        }
    }

    /// Loop the preview circle through the current rhythm.
    private func runPreview() {
        previewTask?.cancel()
        previewTask = Task { @MainActor in
            while !Task.isCancelled {
                @MainActor func phase(_ dur: Double, _ target: CGFloat) async -> Bool {
                    guard dur > 0 else { return true }
                    withAnimation(.easeInOut(duration: dur)) { previewScale = target }
                    let ticks = max(1, Int((dur * 10).rounded()))
                    for _ in 0..<ticks {
                        if Task.isCancelled { return false }
                        try? await Task.sleep(for: .seconds(0.1))
                    }
                    return true
                }
                if !(await phase(inhale, 1.0)) { return }
                if !(await phase(holdIn, 1.0)) { return }
                if !(await phase(exhale, 0.45)) { return }
                if !(await phase(holdOut, 0.45)) { return }
            }
        }
    }
}
