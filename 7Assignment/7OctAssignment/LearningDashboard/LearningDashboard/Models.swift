import Foundation

struct Lesson: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct Course: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var instructor: String
    var lessons: [Lesson]

    var completedCount: Int { lessons.filter(\.isCompleted).count }
    var progress: Double { lessons.isEmpty ? 0 : Double(completedCount) / Double(lessons.count) }

    init(id: UUID = UUID(), title: String, instructor: String, lessons: [Lesson]) {
        self.id = id
        self.title = title
        self.instructor = instructor
        self.lessons = lessons
    }
}
