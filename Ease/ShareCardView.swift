import SwiftUI

/// The shareable "Calm Card". Fixed colors (not theme-dependent) so the exported image is
/// consistent, with a subtle "Ease" wordmark watermark + App Store CTA for organic growth.
struct CalmCard: View {
    let headline: String
    let sub: String
    let pattern: BreathPattern

    var body: some View {
        ZStack {
            Color.white
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.easeAccent.opacity(0.12)).frame(width: 132, height: 132)
                    Circle().strokeBorder(Color.easeAccent.opacity(0.30), lineWidth: 1.5).frame(width: 132, height: 132)
                    Circle().fill(Color.easeAccent).frame(width: 58, height: 58)
                }
                VStack(spacing: 6) {
                    Text(headline)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text(sub).font(.title3).foregroundStyle(Color(white: 0.45))
                    Text(pattern.name + " · " + pattern.detail)
                        .font(.footnote).foregroundStyle(Color(white: 0.6))
                }
                Spacer().frame(height: 6)
                Text("Ease")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.easeAccent)
                Text("Calm in one minute · on the App Store")
                    .font(.caption).foregroundStyle(Color(white: 0.55))
            }
            .padding(40)
        }
        .frame(width: 340, height: 340)
    }

    @MainActor func render() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 3
        return renderer.uiImage
    }
}
