import Foundation

struct Shift: Identifiable, Codable, Hashable {
    let id: UUID
    var seconds: Int
    var createdAt: Date

    init(id: UUID = UUID(), seconds: Int, createdAt: Date = .now) {
        self.id = id
        self.seconds = seconds
        self.createdAt = createdAt
    }
}
