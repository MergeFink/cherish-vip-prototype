import SwiftUI

struct YearPickerView: View {
    @ObservedObject var model: VIPModel
    @Binding var screen: AppScreen

    let years: [(Int, Int)] = [
        (2026, 312), (2025, 2847), (2024, 3201), (2023, 2654),
        (2022, 1983), (2021, 2105), (2020, 1432), (2019, 1876),
        (2018, 2341), (2017, 1654)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("❤️")
                    .font(.system(size: 48))
                Text("Cherish")
                    .font(.system(size: 36, weight: .bold))
                Text("Which year would you like to organize?")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 48)
            .padding(.bottom, 32)

            // Year grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                    ForEach(years, id: \.0) { year, count in
                        YearCard(year: year, photoCount: count, isSelected: model.selectedYear == year) {
                            model.selectedYear = year
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }

            // Continue button
            Button {
                withAnimation { screen = .vipSetup }
            } label: {
                Text("Continue with \(model.selectedYear)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 260, height: 48)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
    }
}

struct YearCard: View {
    let year: Int
    let photoCount: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(year))
                    .font(.system(size: 28, weight: .bold))
                Text("\(photoCount.formatted()) photos")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                if isSelected {
                    Text("Selected ✓")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
