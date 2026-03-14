import SwiftUI

struct CandidateReviewView: View {
    @ObservedObject var model: VIPModel
    @Binding var screen: AppScreen
    @State private var faceNames: [UUID: String] = [:]
    @State private var showFutureVIPFor: String? = nil

    var activeList: [CandidatePhoto] { model.activeCandidates }
    var current: CandidatePhoto? { model.activeCandidate }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()

            if let photo = current {
                HStack(spacing: 0) {
                    // Main photo area
                    photoArea(photo: photo)
                    Divider()
                    // Side panel
                    sidePanel(photo: photo)
                        .frame(width: 280)
                }
            } else {
                // All done
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("All candidates reviewed!")
                        .font(.title2.bold())
                    Button("See Results →") { withAnimation { screen = .results } }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()
            bottomBar
        }
        .overlay(alignment: .bottom) { undoToast }
    }

    // MARK: - Top Bar
    var topBar: some View {
        HStack {
            Button("← Back") { withAnimation { screen = .vipSetup } }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

            Spacer()

            VStack(spacing: 2) {
                Text("Finding \(model.vipName)'s photos in \(model.selectedYear)")
                    .font(.headline)
                Text("\(model.remainingCount) candidates remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                withAnimation { screen = .results }
            } label: {
                Text("See Results")
                    .font(.subheadline.bold())
                    .foregroundColor(model.confidence >= 70 ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(model.confidence < 30)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Photo Area
    func photoArea(photo: CandidatePhoto) -> some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)

            AsyncImageView(url: photo.url)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Side Panel
    func sidePanel(photo: CandidatePhoto) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Who's in this photo?")
                    .font(.headline)
                    .padding(.top, 16)

                // Face slots
                ForEach(photo.faces) { face in
                    faceSlot(face: face)
                }

                Divider()

                // Remove button
                Button {
                    model.removeCurrentPhoto()
                } label: {
                    Label("Remove from list", systemImage: "minus.circle")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Text("Removes this photo and any others where the same non-VIP face appears alone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    func faceSlot(face: MockFace) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(face.confidence != nil ? .accentColor : .secondary)
                if let conf = face.confidence {
                    Text("\(model.vipName) — \(Int(conf * 100))% match")
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                } else {
                    Text(face.name.isEmpty ? "Unknown person" : face.name)
                        .font(.subheadline)
                        .foregroundColor(face.name.isEmpty ? .secondary : .primary)
                }
            }

            if face.confidence == nil {
                HStack(spacing: 8) {
                    TextField("Type a name...", text: Binding(
                        get: { faceNames[face.id] ?? face.name },
                        set: { faceNames[face.id] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)

                    // Future VIP button if name entered
                    let name = faceNames[face.id] ?? face.name
                    if !name.isEmpty && name != model.vipName && !model.futureVIPs.contains(name) {
                        Button {
                            model.addFutureVIP(name)
                        } label: {
                            Text("+ VIP")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    } else if model.futureVIPs.contains(faceNames[face.id] ?? face.name) {
                        Label("Future VIP", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(12)
        .background(face.confidence != nil ? Color.accentColor.opacity(0.07) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(face.confidence != nil ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Bottom Bar
    var bottomBar: some View {
        HStack(spacing: 20) {
            Button("← Previous") { model.goToPrevious() }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .disabled(model.currentIndex == 0)

            Spacer()

            // Confidence meter
            VStack(spacing: 4) {
                HStack {
                    Text("\(model.vipName.isEmpty ? "VIP" : model.vipName) confidence:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(model.confidence))%")
                        .font(.caption.bold())
                        .foregroundColor(model.confidence >= 70 ? .green : .primary)
                }
                ProgressView(value: model.confidence, total: 100)
                    .frame(width: 200)
                    .tint(model.confidence >= 70 ? .green : .accentColor)

                if model.confidence >= 70 {
                    Text("✓ Confidence is good — you can see results now")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Skip") { model.advanceToNext() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                Button("Confirm & Next →") {
                    model.confirmCurrentPhoto()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Undo Toast
    var undoToast: some View {
        Group {
            if let msg = model.undoMessage {
                HStack(spacing: 12) {
                    Text(msg)
                        .font(.subheadline)
                    Button("Undo") { /* TODO: implement undo stack */ }
                        .buttonStyle(.plain)
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 8)
                .padding(.bottom, 70)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: model.undoMessage)
    }
}

// MARK: - Async Image View (loads local files including HEIC)
struct AsyncImageView: View {
    let url: URL
    @State private var image: NSImage? = nil

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay(ProgressView())
            }
        }
        .onAppear { loadImage() }
    }

    func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let img = NSImage(contentsOf: url)
            DispatchQueue.main.async { self.image = img }
        }
    }
}
