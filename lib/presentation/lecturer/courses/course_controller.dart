// lib/presentation/lecturer/courses/course_controller.dart
//
// Riverpod StateNotifier that owns the lecturer's course list.
// Uses mock data while Supabase is not yet connected.
// When your teammate adds the backend, replace _loadMock() with
// a real repository call.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/course_model.dart';

// ── State ────────────────────────────────────────────────────────────────────

class CourseListState {
  final List<CourseModel> courses;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const CourseListState({
    this.courses    = const [],
    this.isLoading  = false,
    this.error,
    this.searchQuery = '',
  });

  // Filtered view — applied in the UI
  List<CourseModel> get filtered {
    if (searchQuery.trim().isEmpty) return courses;
    final q = searchQuery.toLowerCase();
    return courses.where((c) =>
    c.courseName.toLowerCase().contains(q) ||
        c.courseCode.toLowerCase().contains(q),
    ).toList();
  }

  CourseListState copyWith({
    List<CourseModel>? courses,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return CourseListState(
      courses:     courses     ?? this.courses,
      isLoading:   isLoading   ?? this.isLoading,
      error:       error,                    // null clears the error
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ── Mock data ────────────────────────────────────────────────────────────────

const _kMockCourses = [
  CourseModel(
    courseCode:    'CS202',
    courseName:    'Data Structures',
    group:         'Group B',
    enrolled:      45,
    avgAttendance: 92,
    lastSessionAt: '4 hours ago',
  ),
  CourseModel(
    courseCode:    'CS405',
    courseName:    'Network Security',
    group:         'Final Year',
    enrolled:      32,
    avgAttendance: 85,
    lastSessionAt: null,
  ),
  CourseModel(
    courseCode:    'CS301',
    courseName:    'Software Engineering',
    group:         'Group A',
    enrolled:      60,
    avgAttendance: 87,
    lastSessionAt: '2 days ago',
  ),
];

// ── Notifier ─────────────────────────────────────────────────────────────────

class CourseController extends StateNotifier<CourseListState> {
  CourseController() : super(const CourseListState()) {
    loadCourses();
  }

  // Called on init and on pull-to-refresh
  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true);

    // Simulate network delay — remove when real API is connected
    await Future.delayed(const Duration(milliseconds: 600));

    // TODO: replace with repository call, e.g.:
    // final courses = await ref.read(courseRepositoryProvider).fetchForLecturer();
    state = state.copyWith(
      courses:   _kMockCourses,
      isLoading: false,
    );
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final courseControllerProvider =
StateNotifierProvider<CourseController, CourseListState>(
      (ref) => CourseController(),
);