export interface Course {
  id: number;
  course_code: string;
  course_name: string;
  course_group: string | null;
  enrolled: number;
  avg_attendance: number;
  lecturer_id: string | null;
}

export interface CourseWithLecturer extends Course {
  lecturer_name: string | null;
}

export interface Lecturer {
  id: number;
  lecturer_id: string;
  lecturer_name: string;
  lecturer_email: string;
  department: string;
}

export interface Student {
  id: number;
  student_id: string;
  student_name: string;
  student_email: string;
  phone_number: string;
  programme: string;
  year_of_study: string;
  avatar_url: string | null;
}

export interface EnrolledStudent {
  id: number;
  student_id: string;
  course_code: string;
  full_name: string;
}

export interface Session {
  session_id: string;
  course_code: string;
  course_name: string;
  lecturer_name: string | null;
  room_code: string;
  start_time: string;
  end_time: string;
  present_cutoff: string | null;
  late_cutoff: string | null;
  status: string;
  created_at: string;
  synced_at: string;
}

export interface AttendanceRecord {
  id: number;
  session_id: string;
  student_id: string;
  status: string;
  timestamp: string;
  synced_at: string;
}
