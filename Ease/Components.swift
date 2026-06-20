import SwiftUI

/// The breathing circle — a flat Apple-blue core with a soft halo and a hairline ring.
/// `scale` is driven by the SessionEngine (or a gentle idle animation on the home screen).
struct BreathingCircle: View {
    var scale: CGFloat
    var base: CGFloat = 280

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.easeAccent.opacity(0.10))
                .frame(width: base, height: base)
                .scaleEffect(scale)
            Circle()
                .strokeBorder(Color.easeAccent.opacity(0.30), lineWidth: 1.5)
                .frame(width: base, height: base)
                .scaleEffect(scale)
            Circle()
                .fill(Color.easeAccent)
                .frame(width: base * 0.42, height: base * 0.42)
                .scaleEffect(scale)
        }
        .frame(width: base, height: base)
    }
}

/// A selectable pattern chip; shows a small lock when the pattern is Pro and the user isn't.
struct PatternChip: View {
    let pattern: BreathPattern
    let selected: Bool
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                HStack(spacing: 5) {
                    Text(pattern.name).font(.subheadline.weight(.semibold))
                    if locked {
                        Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                    }
                }
                Text(pattern.detail).font(.caption2).foregroundStyle(selected ? .white.opacity(0.85) : .secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .frame(minWidth: 76)
            .background(
                selected ? Color.easeAccent : Color.easeCard,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pattern-\(pattern.id)")
    }
}

/// A selectable session-length chip.
struct LengthChip: View {
    let length: SessionLength
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(length.label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(
                    selected ? Color.easeAccent : Color.easeCard,
                    in: Capsule()
                )
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("len-\(length.seconds)")
    }
}

/// A small labelled metric tile used on Stats.
struct MetricTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.easeAccent)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.easeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Wraps UIActivityViewController so we can share a rendered Calm Card image.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

func mmss(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
