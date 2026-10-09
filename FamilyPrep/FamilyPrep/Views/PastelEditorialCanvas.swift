import SwiftUI

@MainActor
struct PastelEditorialCanvas: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .light {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.91),
                        Color(red: 0.96, green: 0.97, blue: 0.93),
                        Color(red: 0.86, green: 0.92, blue: 0.97),
                        Color(red: 0.91, green: 0.96, blue: 0.89),
                        Color(red: 0.80, green: 0.90, blue: 0.82),
                        Color(red: 0.82, green: 0.92, blue: 0.97),
                        Color(red: 0.87, green: 0.92, blue: 0.86),
                        Color(red: 0.90, green: 0.94, blue: 0.94),
                        Color(red: 0.85, green: 0.91, blue: 0.97)
                    ],
                    smoothsColors: true
                )
                .opacity(1.0)
                .blendMode(.normal)
            } else {
                Color.black

                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color(red: 0.16, green: 0.20, blue: 0.18),
                        Color(red: 0.12, green: 0.13, blue: 0.20),
                        Color(red: 0.10, green: 0.16, blue: 0.24),
                        Color(red: 0.14, green: 0.18, blue: 0.16),
                        Color(red: 0.10, green: 0.16, blue: 0.14),
                        Color(red: 0.09, green: 0.14, blue: 0.22),
                        Color(red: 0.15, green: 0.19, blue: 0.15),
                        Color(red: 0.13, green: 0.15, blue: 0.18),
                        Color(red: 0.11, green: 0.16, blue: 0.20)
                    ],
                    smoothsColors: true
                )
                .opacity(1.0)
                .blendMode(.screen)
            }
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

                Text("Light mode: stronger sage / ivory / dawn-blue pastel matrix at full 100% opacity (no white system underlay eating it) → visible real depth, not a flat near-white page. Dark mode: 100% screen-blend deep jewel-tone sage/indigo mesh, so pure-black pages perceptually lift.")
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
