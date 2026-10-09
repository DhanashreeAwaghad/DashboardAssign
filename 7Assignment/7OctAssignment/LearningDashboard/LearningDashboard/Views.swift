import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Spacer()
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 44)).foregroundStyle(.blue)
                Text("Welcome back").font(.largeTitle.bold())
                Text("Sign in to continue learning.").foregroundStyle(.secondary)
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    .autocorrectionDisabled().textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("login.email")
                SecureField("Password (6+ characters)", text: $password)
                    .textFieldStyle(.roundedBorder).accessibilityIdentifier("login.password")
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red).font(.footnote).accessibilityIdentifier("login.error")
                }
                Button(action: signIn) {
                    HStack {
                        if isLoading { ProgressView().tint(.white) }
                        Text(isLoading ? "Signing In…" : "Sign In")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).disabled(isLoading)
                Text("Demo sign-in: use a valid email and a password with at least 6 characters.")
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(24)
            .navigationDestination(isPresented: $isLoggedIn) { DashboardView() }
        }
    }

    private func signIn() {
        guard email.contains("@"), email.split(separator: "@").last?.contains(".") == true else {
            errorMessage = "Enter a valid email address."; return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."; return
        }
        errorMessage = nil
        isLoading = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            isLoading = false
            isLoggedIn = true
        }
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = CourseDashboardViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading courses…").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't Load Courses", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await viewModel.load() } }.buttonStyle(.borderedProminent)
                }
            case .empty:
                ContentUnavailableView("No Courses Yet", systemImage: "books.vertical",
                                       description: Text("Your courses will appear here when they are available."))
            case .loaded(let courses, let isOffline):
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your learning journey").font(.title2.bold())
                            Text("Keep building your skills, one lesson at a time.").foregroundStyle(.secondary)
                        }.padding(.vertical, 8)
                    }
                    if isOffline {
                        Section { Label("Showing saved courses offline", systemImage: "wifi.slash").font(.footnote) }
                    }
                    Section("My Courses") {
                        ForEach(courses) { course in
                            NavigationLink {
                                CourseDetailView(course: course, viewModel: viewModel)
                            } label: {
                                CourseRow(course: course)
                            }
                            .accessibilityIdentifier("course.\(course.id)")
                        }
                    }
                }
                .refreshable { await viewModel.load() }
            }
        }
        .navigationTitle("Learning Dashboard")
        .task { await viewModel.load() }
    }
}

private struct CourseRow: View {
    let course: Course
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title).font(.headline)
            Text("Instructor: \(course.instructor)").font(.subheadline).foregroundStyle(.secondary)
            ProgressView(value: course.progress)
            HStack {
                Text("\(course.lessons.count) lessons")
                Spacer()
                Text("\(Int((course.progress * 100).rounded()))%")
                Spacer()
                Label("Continue", systemImage: "arrow.right.circle.fill").labelStyle(.titleAndIcon)
                    .foregroundStyle(.blue)
            }.font(.caption)
        }.padding(.vertical, 5)
    }
}

private struct CourseDetailView: View {
    let course: Course
    @ObservedObject var viewModel: CourseDashboardViewModel

    var body: some View {
        List {
            if let current = viewModel.course(id: course.id) {
                Section {
                    ProgressView(value: current.progress)
                    HStack {
                        Text("\(current.completedCount) of \(current.lessons.count) lessons completed")
                        Spacer()
                        Text("\(Int((current.progress * 100).rounded()))%")
                    }.font(.subheadline).foregroundStyle(.secondary)
                }
                Section("Lessons") {
                    ForEach(current.lessons) { lesson in
                        Button {
                            viewModel.toggleLesson(courseID: current.id, lessonID: lesson.id)
                        } label: {
                            HStack {
                                Image(systemName: lesson.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(lesson.isCompleted ? .green : .secondary)
                                Text(lesson.title).foregroundStyle(.primary)
                                Spacer()
                                Text(lesson.isCompleted ? "Completed" : "Pending")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("lesson.\(lesson.id)")
                    }
                }
            }
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
