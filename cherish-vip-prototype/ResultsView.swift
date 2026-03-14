import SwiftUI

struct ResultsView: View {
    @ObservedObject var model: VIPModel
    @Binding var screen: AppScreen
    @State private var selectedPhotos: Set<UUID> = []
    @State private var showStorageConfirm: Bool = false

    let columns = [GridItem(.adaptive(minimum: 160))]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()

            if model.confirmedPhotos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    // Send to Storage — prominent at top
                    sendToStorageButton
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // Stats
                    statsBar
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    // Selection toolbar
                    if !selectedPhotos.isEmpty {
                        selectionToolbar
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    // Photo grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(model.confirmedPhotos) { photo in
                            ResultPhotoCard(
                                photo: photo,
                                isSelected: selectedPhotos.contains(photo.id),
                                onTap: { toggleSelection(photo) },
                                onRemove: { model.removeConfirmedPhoto(photo) }
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
        .overlay(alignment: .bottom) { undoToast }
        .alert("Sent to Storage ✓", isPresented: $showStorageConfirm) {
            Button("Done") { }
        } message: {
            Text("\(model.confirmedPhotos.count) photos of \(model.vipName) have been saved to your storage folder.\n\nNext time new photos are added, we'll start from this list.")
        }
    }

    // MARK: - Top Bar
    var topBar: some View {
        HStack {
            Button("← Keep Reviewing") { withAnimation { screen = .candidateReview } }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

            Spacer()

            Text("\(model.vipName)'s Photos — \(model.selectedYear)")
                .font(.headline)

            Spacer()

            // Future VIPs badge
            if !model.futureVIPs.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(model.futureVIPs.count) Future VIPs queued")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Send to Storage
    var sendToStorageButton: some View {
        Button {
            model.sendToStorage()
            showStorageConfirm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "externaldrive.fill.badge.checkmark")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Send \(model.vipName)'s Photos to Storage")
                        .font(.headline)
                    Text("\(model.confirmedPhotos.count) photos ready to save")
                        .font(.caption)
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                LinearGradient(colors: [Color.teal, Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats
    var statsBar: some View {
        HStack(spacing: 24) {
            statPill(value: "\(model.confirmedPhotos.count)", label: "Photos found")
            statPill(value: "\(Int(model.confidence))%", label: "Confidence")
            statPill(value: "\(model.futureVIPs.count)", label: "Future VIPs")
            Spacer()
        }
    }

    func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Selection Toolbar
    var selectionToolbar: some View {
        HStack {
            Text("\(selectedPhotos.count) selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                removeSelected()
            } label: {
                Label("Remove Selected", systemImage: "minus.circle")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            Button("Deselect All") { selectedPhotos.removeAll() }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
        }
        .padding(12)
        .background(Color.yellow.opacity(0.08))
        .cornerRadius(10)
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.square.badge.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No confirmed photos yet")
                .font(.title2.bold())
            Text("Go back and confirm some photos to build \(model.vipName)'s list")
                .foregroundColor(.secondary)
            Button("← Keep Reviewing") { withAnimation { screen = .candidateReview } }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Undo Toast
    var undoToast: some View {
        Group {
            if let msg = model.undoMessage {
                HStack(spacing: 12) {
                    Text(msg)
                        .font(.subheadline)
                    Button("Undo") { }
                        .buttonStyle(.plain)
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 8)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: model.undoMessage)
    }

    func toggleSelection(_ photo: CandidatePhoto) {
        if selectedPhotos.contains(photo.id) {
            selectedPhotos.remove(photo.id)
        } else {
            selectedPhotos.insert(photo.id)
        }
    }

    func removeSelected() {
        for id in selectedPhotos {
            if let photo = model.confirmedPhotos.first(where: { $0.id == id }) {
                model.removeConfirmedPhoto(photo)
            }
        }
        selectedPhotos.removeAll()
    }
}

// MARK: - Result Photo Card
struct ResultPhotoCard: View {
    let photo: CandidatePhoto
    let isSelected: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                AsyncImageView(url: photo.url)
                    .scaledToFill()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        isSelected ?
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.15))
                        : nil
                    )
            }
            .buttonStyle(.plain)

            // Checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .background(Circle().fill(.white))
                    .padding(6)
            }

            // Remove button (top left)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .buttonStyle(.plain)
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
