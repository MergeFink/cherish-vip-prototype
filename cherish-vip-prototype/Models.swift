import SwiftUI
import Foundation

// MARK: - App State

enum AppScreen {
    case yearPicker
    case vipSetup
    case candidateReview
    case results
}

// MARK: - Mock Face

struct MockFace: Identifiable {
    let id = UUID()
    var name: String
    var confidence: Double? // nil = unknown, non-nil = VIP match confidence
    var isFutureVIP: Bool = false
    // Normalized position in image (0-1)
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - Candidate Photo

struct CandidatePhoto: Identifiable {
    let id = UUID()
    let url: URL
    var faces: [MockFace]
    var isRemoved: Bool = false
    var isConfirmed: Bool = false // confirmed to contain VIP
}

// MARK: - VIP Model

class VIPModel: ObservableObject {
    @Published var selectedYear: Int = 2024
    @Published var vipName: String = ""
    @Published var seedPhotoURL: URL? = nil
    @Published var candidates: [CandidatePhoto] = []
    @Published var confirmedPhotos: [CandidatePhoto] = []
    @Published var currentIndex: Int = 0
    @Published var confidence: Double = 0.0
    @Published var futureVIPs: [String] = []
    @Published var undoMessage: String? = nil
    @Published var storageSent: Bool = false

    private var undoTimer: Timer?

    var activeCandidate: CandidatePhoto? {
        let active = candidates.filter { !$0.isRemoved }
        guard currentIndex < active.count else { return nil }
        return active[currentIndex]
    }

    var activeCandidates: [CandidatePhoto] {
        candidates.filter { !$0.isRemoved }
    }

    var remainingCount: Int {
        candidates.filter { !$0.isRemoved }.count
    }

    func loadCandidates(from directory: URL) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }

        let imageFiles = files.filter { url in
            ["jpg", "jpeg", "heic", "png"].contains(url.pathExtension.lowercased())
        }.prefix(20)

        candidates = imageFiles.enumerated().map { index, url in
            CandidatePhoto(url: url, faces: mockFaces(for: index, vipName: vipName))
        }
        currentIndex = 0
        confidence = 0.0
    }

    private func mockFaces(for index: Int, vipName: String) -> [MockFace] {
        let otherNames = ["Karen", "Bob", "Sarah", "Mike", "Jennifer", "Tom", ""]
        let faceCount = [1, 2, 2, 3, 1, 2, 1, 2, 3, 2][index % 10]

        var faces: [MockFace] = []
        let vipConfidence = Double.random(in: 0.72...0.97)
        let hasVIP = index % 3 != 2 // roughly 2/3 of photos have the VIP

        for i in 0..<faceCount {
            let xPos = 0.1 + Double(i) * (0.7 / Double(max(faceCount, 1)))
            if i == 0 && hasVIP {
                faces.append(MockFace(
                    name: vipName.isEmpty ? "" : vipName,
                    confidence: vipConfidence,
                    x: xPos, y: 0.15, width: 0.22, height: 0.35
                ))
            } else {
                faces.append(MockFace(
                    name: otherNames[(index + i) % otherNames.count],
                    confidence: nil,
                    x: xPos, y: 0.15, width: 0.22, height: 0.35
                ))
            }
        }
        return faces
    }

    func confirmCurrentPhoto() {
        guard let photo = activeCandidate,
              let idx = candidates.firstIndex(where: { $0.id == photo.id }) else { return }
        candidates[idx].isConfirmed = true
        confirmedPhotos.append(candidates[idx])
        // Boost confidence
        confidence = min(100, confidence + Double.random(in: 3...7))
        advanceToNext()
    }

    func removeCurrentPhoto() {
        guard let photo = activeCandidate,
              let idx = candidates.firstIndex(where: { $0.id == photo.id }) else { return }

        // Check how many non-VIP faces will trigger elimination
        let nonVIPFaces = candidates[idx].faces.filter {
            !$0.name.isEmpty && $0.name != vipName && $0.confidence == nil
        }

        var eliminatedCount = 1
        if !nonVIPFaces.isEmpty {
            // Simulate elimination flywheel — remove other photos with same non-VIP faces
            let bonus = Int.random(in: 2...8)
            eliminatedCount += bonus
            // Mark a few random others as removed too
            var removed = 0
            for i in 0..<candidates.count where removed < bonus {
                if !candidates[i].isRemoved && candidates[i].id != photo.id {
                    candidates[i].isRemoved = true
                    removed += 1
                }
            }
        }

        candidates[idx].isRemoved = true

        let msg = eliminatedCount > 1
            ? "Removed \(eliminatedCount) photos from list — Undo"
            : "Removed from list — Undo"
        showUndo(msg)

        // Don't advance index — next photo slides in
        let active = candidates.filter { !$0.isRemoved }
        if currentIndex >= active.count && currentIndex > 0 {
            currentIndex = max(0, active.count - 1)
        }
    }

    func advanceToNext() {
        let active = candidates.filter { !$0.isRemoved }
        if currentIndex < active.count - 1 {
            currentIndex += 1
        }
    }

    func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    func addFutureVIP(_ name: String) {
        guard !name.isEmpty && !futureVIPs.contains(name) else { return }
        futureVIPs.append(name)
    }

    func sendToStorage() {
        storageSent = true
        showUndo("\(confirmedPhotos.count) photos of \(vipName) saved to storage ✓")
    }

    func removeConfirmedPhoto(_ photo: CandidatePhoto) {
        confirmedPhotos.removeAll { $0.id == photo.id }
        showUndo("Removed from list — Undo")
    }

    private func showUndo(_ message: String) {
        undoMessage = message
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.undoMessage = nil
            }
        }
    }
}
