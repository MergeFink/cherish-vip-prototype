import SwiftUI

struct ContentView: View {
    @StateObject private var model = VIPModel()
    @State private var screen: AppScreen = .yearPicker

    var body: some View {
        ZStack {
            switch screen {
            case .yearPicker:
                YearPickerView(model: model, screen: $screen)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .vipSetup:
                VIPSetupView(model: model, screen: $screen)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .candidateReview:
                CandidateReviewView(model: model, screen: $screen)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .results:
                ResultsView(model: model, screen: $screen)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
    }
}
