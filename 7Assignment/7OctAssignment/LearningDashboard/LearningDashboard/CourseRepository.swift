import Foundation

protocol CourseCache {
    func loadCourses() -> [Course]?
    func saveCourses(_ courses: [Course])
}

struct UserDefaultsCourseCache: CourseCache {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "learning_dashboard_courses_v2") {
        self.defaults = defaults
        self.key = key
    }

    func loadCourses() -> [Course]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([Course].self, from: data)
    }

    func saveCourses(_ courses: [Course]) {
        guard let data = try? JSONEncoder().encode(courses) else { return }
        defaults.set(data, forKey: key)
    }
}

enum CourseLoadResult {
    case fresh([Course])
    case cached([Course])
}

@MainActor
final class CourseRepository {
    private let service: CourseService
    private let cache: CourseCache

    init(service: CourseService = LocalJSONCourseService(), cache: CourseCache = UserDefaultsCourseCache()) {
        self.service = service
        self.cache = cache
    }

    func loadCourses() async throws -> CourseLoadResult {
        do {
            let fetchedCourses = try await service.fetchCourses()
            let courses = preservingLocalCompletions(in: fetchedCourses, from: cache.loadCourses() ?? [])
            cache.saveCourses(courses)
            return .fresh(courses)
        } catch {
            if let cached = cache.loadCourses() {
                return .cached(cached)
            }
            throw error
        }
    }

    private func preservingLocalCompletions(in fetchedCourses: [Course], from cachedCourses: [Course]) -> [Course] {
        let cachedByID = Dictionary(uniqueKeysWithValues: cachedCourses.map { ($0.id, $0) })
        return fetchedCourses.map { fetchedCourse in
            guard let cachedCourse = cachedByID[fetchedCourse.id] else { return fetchedCourse }
            let cachedLessons = Dictionary(uniqueKeysWithValues: cachedCourse.lessons.map { ($0.id, $0) })
            var merged = fetchedCourse
            for index in merged.lessons.indices {
                if let cachedLesson = cachedLessons[merged.lessons[index].id] {
                    merged.lessons[index].isCompleted = cachedLesson.isCompleted
                }
            }
            return merged
        }
    }

    func toggleLesson(courseID: UUID, lessonID: UUID, in courses: [Course]) -> [Course] {
        var updated = courses
        guard let courseIndex = updated.firstIndex(where: { $0.id == courseID }),
              let lessonIndex = updated[courseIndex].lessons.firstIndex(where: { $0.id == lessonID }) else {
            return updated
        }
        updated[courseIndex].lessons[lessonIndex].isCompleted.toggle()
        cache.saveCourses(updated)
        return updated
    }
}
