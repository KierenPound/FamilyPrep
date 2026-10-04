import SwiftUI

@MainActor
struct PastelEditorialCanvas: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.93),    // top-left: warm ivory
                    Color(red: 0.92, green: 0.95, blue: 0.98),    // top-center: pale dawn wash
                    Color(red: 0.86, green: 0.92, blue: 0.98),    // top-right: soft dawn blue
                    Color(red: 0.94, green: 0.96, blue: 0.91),    // middle-left: creamy sage wash
                    Color(red: 0.89, green: 0.93, blue: 0.87),    // center: muted organic sage
                    Color(red: 0.88, green: 0.94, blue: 0.97),    // middle-right: sky-tinged blue
                    Color(red: 0.90, green: 0.93, blue: 0.88),    // bottom-left: cool moss sage
                    Color(red: 0.93, green: 0.95, blue: 0.94),    // bottom-center: warm neutral
                    Color(red: 0.90, green: 0.94, blue: 0.97)     // bottom-right: soft dawn mist
                ],
                smoothsColors: true
            )
            .opacity(0.15)
            .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Serene Editorial Canvas")
                    .font(.largeTitle.bold())

                Text("Behind every section card, the sage + ivory + dawn blue mesh is blended at 15% opacity over the system grouped background, producing an incredibly soft, high-end editorial depth without overwhelming any foreground text.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 24)
        }
    }
    .background(PastelEditorialCanvas())
}
