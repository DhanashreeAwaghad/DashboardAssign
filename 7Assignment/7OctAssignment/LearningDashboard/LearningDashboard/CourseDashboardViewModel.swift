import Foundation
import Combine

@MainActor
final class CourseDashboardViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([Course], isOffline: Bool)
        case empty
        case failed(String)
    }

    @Published private(set) var state: State = .loading
    private let repository: CourseRepository

    init(repository: CourseRepository? = nil) {
        self.repository = repository ?? CourseRepository()
    }

    func load() async {
        state = .loading
        do {
            switch try await repository.loadCourses() {
            case .fresh(let courses): state = courses.isEmpty ? .empty : .loaded(courses, isOffline: false)
            case .cached(let courses): state = courses.isEmpty ? .empty : .loaded(courses, isOffline: true)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func course(id: UUID) -> Course? {
        guard case .loaded(let courses, _) = state else { return nil }
        return courses.first { $0.id == id }
    }

    func toggleLesson(courseID: UUID, lessonID: UUID) {
        guard case .loaded(let courses, let isOffline) = state else { return }
        let updated = repository.toggleLesson(courseID: courseID, lessonID: lessonID, in: courses)
        state = .loaded(updated, isOffline: isOffline)
    }
}
