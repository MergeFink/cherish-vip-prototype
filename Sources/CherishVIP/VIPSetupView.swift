import SwiftUI

struct VIPSetupView: View {
    @ObservedObject var model: VIPModel
    @Binding var screen: AppScreen
    @State private var seedImage: NSImage? = nil

    var canContinue: Bool {
        !model.vipName.trimmingCharacters(in: .whitespaces).isEmpty && seedImage != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Back
            HStack {
                Button("← Back") { withAnimation { screen = .yearPicker } }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Who are we looking for?")
                        .font(.system(size: 30, weight: .bold))
                    Text("We'll find every photo of this person in \(model.selectedYear)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    TextField("e.g. Mom, Lori, Jake...", text: $model.vipName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .frame(maxWidth: 400)
                }

                // Seed photo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reference Photo")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if let img = seedImage {
                        HStack(spacing: 16) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Label("Good reference photo", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                Text("Clear, front-facing photos work best")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button("Choose different photo") { pickPhoto() }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.accentColor)
                                    .font(.subheadline)
                            }
                        }
                        .padding(16)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(12)
                    } else {
                        Button(action: pickPhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                Text("Upload a reference photo")
                                    .font(.headline)
                            }
                            .foregroundColor(.accentColor)
                            .frame(width: 320, height: 80)
                            .background(Color.accentColor.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            )
                        }
                        .buttonStyle(.plain)
                        Text("A clear, front-facing photo of \(model.vipName.isEmpty ? "this person" : model.vipName) works best")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: 400, alignment: .leading)
            }

            Spacer()

            // Start button
            Button {
                startSearch()
            } label: {
                Text(canContinue ? "Find \(model.vipName)'s Photos →" : "Start Search")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 280, height: 48)
                    .background(canContinue ? Color.accentColor : Color.gray.opacity(0.4))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .padding(.bottom, 40)
        }
    }

    func pickPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .heic, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            model.seedPhotoURL = url
            seedImage = NSImage(contentsOf: url)
        }
    }

    func startSearch() {
        let photoDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/PhotoMemory/lori-batch-01")
        model.loadCandidates(from: photoDir)
        withAnimation { screen = .candidateReview }
    }
}
