import Foundation

protocol CourseService {
    func fetchCourses() async throws -> [Course]
}

struct LocalJSONCourseService: CourseService {
    let bundle: Bundle
    let artificialDelay: Duration

    init(bundle: Bundle = .main, artificialDelay: Duration = .milliseconds(350)) {
        self.bundle = bundle
        self.artificialDelay = artificialDelay
    }

    func fetchCourses() async throws -> [Course] {
        try await Task.sleep(for: artificialDelay)
        guard let url = bundle.url(forResource: "courses", withExtension: "json") else {
            throw CourseServiceError.dataUnavailable
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Course].self, from: data)
        } catch {
            throw CourseServiceError.invalidResponse
        }
    }
}

enum CourseServiceError: LocalizedError {
    case dataUnavailable
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .dataUnavailable: return "Course data could not be found. Please try again."
        case .invalidResponse: return "Course data could not be loaded. Please try again."
        }
    }
}
