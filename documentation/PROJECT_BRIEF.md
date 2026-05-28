# OROmark Project Brief

**Project Name:** OROmark - Signal-Based Attendance Management System  
**Developer:** yaan kbg (IUEA, Uganda)  
**Timeline:** 15 weeks to MVP  
**Status:** Ready for development  

---

## Project Overview

OROmark is a cross-platform mobile attendance system for African universities that uses UDP broadcast for session detection and HTTP for attendance submission. The system eliminates manual roll calls while ensuring security through multiple verification layers.

### Name Origin
**OROmark** = ORO(dha) + mark
- "Orodha" (Swahili) = list/register
- "mark" = marking attendance
- Tagline: "Mark your presence"

---

## Tech Stack (FINALIZED)

### Mobile Apps
```
Framework: Flutter 3.24+
Language: Dart 3.11+
State Management: Riverpod
Local Database: drift (SQLite)
HTTP Server: shelf package (Dart)
Biometric: local_auth package
```

### Networking
```
Android: UDP Broadcast (255.255.255.255:5501)
iOS: mDNS/Bonjour (multicast_dns package)
Communication: HTTP REST (lecturer's phone server)
Data Format: JSON
```

### Backend
```
Platform: Supabase
Database: PostgreSQL
Auth: Supabase Auth
Realtime: Supabase Realtime
Storage: Supabase Storage
```

### Admin Dashboard
```
Framework: Next.js 14 (App Router)
UI: React 18 + Tailwind CSS + shadcn/ui
Charts: recharts
Tables: @tanstack/react-table
Hosting: Vercel
```

---

## Core Architecture

### Session Detection Flow

```
LECTURER SIDE:
1. Tap "Start Session" button
2. App generates random room code (e.g., "ALPHA5")
3. App starts shelf HTTP server on port 5500
4. App broadcasts UDP packet every 2 seconds:
   {
     "sessionId": "uuid-123",
     "courseCode": "CS301",
     "courseName": "Software Engineering",
     "lecturerIP": "192.168.1.45",
     "lecturerPort": 5500,
     "roomCode": "ALPHA5",
     "startTime": "2026-01-20T10:15:00Z",
     "endTime": "2026-01-20T10:45:00Z"
   }
5. Display room code on screen for verbal announcement
6. Show live dashboard with attendance count

STUDENT SIDE:
1. App continuously listens for UDP broadcasts
2. On receive, parse JSON payload
3. Check: sessionId not in local "already confirmed" list
4. Display session card with course info and countdown
5. Student enters room code
6. Student confirms with biometric/PIN
7. App sends HTTP POST to lecturer's IP:
   POST http://192.168.1.45:5500/attendance
   {
     "sessionId": "uuid-123",
     "studentId": "2023/CS/001",
     "roomCode": "ALPHA5",
     "deviceFingerprint": "sha256-hash",
     "timestamp": "2026-01-20T10:17:00Z"
   }
8. Lecturer's server validates and stores
9. Student sees "Attendance recorded!" confirmation
```

### Why UDP (Not GPS/WebSocket)

**Decision:** Stick with UDP broadcast + room code approach

**Reasons:**
1. GPS is unreliable in African infrastructure
2. No battery drain from location services
3. No internet required during sessions
4. Network isolation via subnet boundaries (router-enforced)
5. Room code handles edge cases (flat networks, adjacent rooms)
6. More privacy-friendly (no location tracking)

**Isolation Strategy:**
- Layer 1: UDP broadcasts stop at subnet boundaries (router level)
- Layer 2: Room code verification (human announcement)
- Layer 3: Device binding (one registered device per student)
- Layer 4: Biometric/PIN authentication (proof of presence)
- Layer 5: Session expiry (30-minute window)

---

## Security Model

### 5 Layers of Defense

**Layer 1: Network Isolation**
- UDP broadcasts confined to subnet by router
- Only devices in same room/floor receive signal
- Physics-based isolation

**Layer 2: Room Code Verification**
- 4-6 character alphanumeric code
- Verbally announced by lecturer
- Changes every session
- Must match to submit

**Layer 3: Device Binding**
- SHA256 hash of (device_id + student_id)
- One registered device per student
- Admin-controlled registration

**Layer 4: Biometric/PIN**
- Fingerprint (Android/iOS)
- Face ID (iOS)
- PIN fallback
- Proves device owner present

**Layer 5: Session Expiry**
- PRESENT: 0-10 minutes (full credit)
- LATE: 10-30 minutes (late mark)
- After 30 min: session closed, auto-compute absent

### Attack Defense Examples

**Attack:** Friend brings my phone to class
**Defense:** Blocked at Layer 4 (can't unlock my fingerprint)

**Attack:** Student in library receives UDP broadcast
**Defense:** Blocked at Layer 1 (different subnet) or Layer 2 (no room code)

**Attack:** Replay packet later
**Defense:** Blocked at Layer 5 (session expired)

---

## Database Schema

### Local Database (drift/SQLite)

```sql
-- Sessions table
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT UNIQUE NOT NULL,
  course_code TEXT NOT NULL,
  course_name TEXT NOT NULL,
  lecturer_name TEXT,
  room_code TEXT NOT NULL,
  start_time INTEGER NOT NULL,
  end_time INTEGER NOT NULL,
  status TEXT NOT NULL, -- 'PRESENT', 'LATE', 'ABSENT'
  synced INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

-- Attendance table
CREATE TABLE attendance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  status TEXT NOT NULL, -- 'PRESENT', 'LATE'
  timestamp INTEGER NOT NULL,
  device_fingerprint TEXT NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES sessions(session_id)
);

-- Courses table
CREATE TABLE courses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_code TEXT UNIQUE NOT NULL,
  course_name TEXT NOT NULL,
  lecturer_id TEXT,
  enrolled INTEGER DEFAULT 0
);
```

### Backend Database (Supabase/PostgreSQL)

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL, -- 'student', 'lecturer', 'admin'
  full_name TEXT NOT NULL,
  student_id TEXT UNIQUE, -- for students
  device_fingerprint TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Courses table
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_code TEXT UNIQUE NOT NULL,
  course_name TEXT NOT NULL,
  lecturer_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enrollments table
CREATE TABLE enrollments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID REFERENCES courses(id),
  student_id UUID REFERENCES users(id),
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, student_id)
);

-- Sessions table
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id TEXT UNIQUE NOT NULL,
  course_id UUID REFERENCES courses(id),
  room_code TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'ACTIVE', -- 'ACTIVE', 'ENDED'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Attendance table
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id TEXT REFERENCES sessions(session_id),
  student_id UUID REFERENCES users(id),
  status TEXT NOT NULL, -- 'PRESENT', 'LATE', 'ABSENT'
  device_fingerprint TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, student_id)
);
```

---

## Design System

### Brand Colors

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // Primary colors
  static const primary = Color(0xFF0F6E56);      // Teal
  static const secondary = Color(0xFFBA7517);    // Amber
  static const accent = Color(0xFF378ADD);       // Blue
  
  // Status colors
  static const success = Color(0xFF639922);      // Green (Present)
  static const warning = Color(0xFFBA7517);      // Orange (Late)
  static const error = Color(0xFFE24B4A);        // Red (Absent)
  
  // Background colors
  static const bgPrimary = Color(0xFFFFFFFF);    // White
  static const bgSecondary = Color(0xFFF9FAFB);  // Light gray
  static const bgTertiary = Color(0xFFF1F3F4);   // Lighter gray
  
  // Text colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  
  // Status badge backgrounds
  static const presentBg = Color(0xFFEAF3DE);
  static const presentText = Color(0xFF639922);
  static const lateBg = Color(0xFFFAEEDA);
  static const lateText = Color(0xFF854F0B);
  static const absentBg = Color(0xFFFCEBEB);
  static const absentText = Color(0xFFA32D2D);
  static const liveBg = Color(0xFFE6F1FB);
  static const liveText = Color(0xFF185FA5);
}
```

### Typography

```dart
// Font sizes
static const double h1 = 22.0;
static const double h2 = 18.0;
static const double h3 = 16.0;
static const double body = 16.0;
static const double small = 14.0;
static const double tiny = 12.0;

// Font weights
static const FontWeight medium = FontWeight.w500;
static const FontWeight regular = FontWeight.w400;
```

### Spacing

```dart
// Spacing system
static const double xs = 4.0;
static const double sm = 8.0;
static const double md = 12.0;
static const double lg = 16.0;
static const double xl = 20.0;
static const double xxl = 24.0;
```

### Border Radius

```dart
// Border radius
static const double radiusSm = 6.0;
static const double radiusMd = 10.0;
static const double radiusLg = 12.0;
static const double radiusXl = 16.0;
```

---

## Feature Requirements

### Student App

**1. Session Detection**
- [ ] UDP listener (Android) / mDNS listener (iOS)
- [ ] Parse session broadcast JSON
- [ ] Display session card with:
  - Course code badge
  - Course name
  - Lecturer name
  - Live indicator (pulsing green dot)
  - Countdown timer (PRESENT window remaining)
  - Room code display
- [ ] Filter: Don't show already confirmed sessions

**2. Attendance Confirmation**
- [ ] Room code input field
- [ ] Validate room code against session
- [ ] Biometric/PIN authentication prompt
- [ ] HTTP POST to lecturer's server
- [ ] Success/error feedback
- [ ] Store in local database
- [ ] Background sync to Supabase

**3. Attendance History**
- [ ] List past sessions (date descending)
- [ ] Status badges (Present/Late/Absent)
- [ ] Overall stats (rate, total present, total late)
- [ ] Filter by course
- [ ] Filter by date range
- [ ] Pull-to-refresh

**4. Profile**
- [ ] Student information display
- [ ] Registered device info
- [ ] Logout option
- [ ] App version

### Lecturer App

**1. Course List**
- [ ] Display enrolled courses
- [ ] Stats per course:
  - Total students
  - Average attendance rate
  - Last session date
- [ ] "Start Session" button
- [ ] "View Details" button
- [ ] Filter/search courses

**2. Start Session**
- [ ] Select course
- [ ] Generate random room code
- [ ] Start HTTP server (shelf)
- [ ] Start UDP broadcast loop
- [ ] Display room code prominently
- [ ] Show QR code (optional, for manual join)
- [ ] Navigate to live dashboard

**3. Live Session Dashboard**
- [ ] Real-time attendance count (Present/Late/Pending)
- [ ] Progress bar (% coverage)
- [ ] Recent submissions list with timestamps
- [ ] Search students
- [ ] Filter by status
- [ ] Manual override (mark present/absent)
- [ ] "End Session" button

**4. End Session**
- [ ] Stop UDP broadcast
- [ ] Stop HTTP server
- [ ] Compute absent list (enrolled - present - late)
- [ ] Mark all pending as absent
- [ ] Sync to Supabase
- [ ] Show summary screen
- [ ] Export options (CSV/PDF)

**5. Session History**
- [ ] Past sessions list
- [ ] Attendance percentages
- [ ] View detailed records
- [ ] Charts/trends
- [ ] Export functionality

---

## Project Structure

```
oromark_mobile/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── network_constants.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_text_styles.dart
│   │   ├── utils/
│   │   │   ├── device_fingerprint.dart
│   │   │   ├── room_code_generator.dart
│   │   │   └── validators.dart
│   │   └── errors/
│   │       └── exceptions.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── session_model.dart
│   │   │   ├── attendance_model.dart
│   │   │   ├── course_model.dart
│   │   │   └── user_model.dart
│   │   ├── repositories/
│   │   │   ├── session_repository.dart
│   │   │   ├── attendance_repository.dart
│   │   │   └── course_repository.dart
│   │   ├── services/
│   │   │   ├── udp_service.dart
│   │   │   ├── http_server_service.dart
│   │   │   ├── mdns_service.dart
│   │   │   ├── biometric_service.dart
│   │   │   └── supabase_service.dart
│   │   └── database/
│   │       ├── app_database.dart
│   │       └── tables.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── session.dart
│   │   │   ├── attendance.dart
│   │   │   └── course.dart
│   │   └── usecases/
│   │       ├── detect_session_usecase.dart
│   │       ├── confirm_attendance_usecase.dart
│   │       └── start_session_usecase.dart
│   │
│   ├── presentation/
│   │   ├── student/
│   │   │   ├── home/
│   │   │   │   ├── student_home_screen.dart
│   │   │   │   ├── session_card.dart
│   │   │   │   └── student_home_controller.dart
│   │   │   ├── history/
│   │   │   │   ├── history_screen.dart
│   │   │   │   ├── history_item.dart
│   │   │   │   └── history_controller.dart
│   │   │   └── profile/
│   │   │       └── profile_screen.dart
│   │   │
│   │   └── lecturer/
│   │       ├── courses/
│   │       │   ├── course_list_screen.dart
│   │       │   ├── course_card.dart
│   │       │   └── course_controller.dart
│   │       ├── session/
│   │       │   ├── active_session_screen.dart
│   │       │   ├── session_stats.dart
│   │       │   └── session_controller.dart
│   │       └── reports/
│   │           └── reports_screen.dart
│   │
│   ├── providers/
│   │   ├── session_provider.dart
│   │   ├── attendance_provider.dart
│   │   └── auth_provider.dart
│   │
│   └── main.dart
│
├── android/
├── ios/
├── test/
├── pubspec.yaml
└── README.md
```

---

## Development Timeline

### Week 1-2: Flutter Fundamentals
- [ ] Flutter setup & first app
- [ ] Widgets, layouts, navigation
- [ ] State management (setState basics)
- [ ] Forms & validation
- [ ] ListView & dynamic data
- **Milestone:** Task Manager app

### Week 3: Networking (CRITICAL)
- [ ] UDP socket theory
- [ ] UDP broadcast sender (lecturer)
- [ ] UDP listener (student)
- [ ] shelf HTTP server
- [ ] HTTP POST requests
- [ ] Test on campus WiFi ⚠️
- **Milestone:** UDP echo app

### Week 4: Local Database
- [ ] drift ORM setup
- [ ] Tables definition
- [ ] CRUD operations
- [ ] Migrations
- **Milestone:** Offline storage working

### Week 5: State Management
- [ ] Riverpod setup
- [ ] StateNotifier pattern
- [ ] FutureProvider
- [ ] Integrate with drift
- **Milestone:** Reactive state

### Week 6: Platform Features
- [ ] Android foreground service
- [ ] Biometric authentication
- [ ] Device fingerprinting
- [ ] Permissions
- **Milestone:** Background detection

### Week 7: iOS Support
- [ ] mDNS/Bonjour
- [ ] iOS background modes
- [ ] Info.plist config
- [ ] iOS device testing
- **Milestone:** Cross-platform

### Week 8-9: Core Features
- [ ] Student session detection
- [ ] Student attendance confirmation
- [ ] Lecturer start session
- [ ] Lecturer live dashboard
- [ ] Time window logic
- **Milestone:** MVP end-to-end

### Week 10: Backend Integration
- [ ] Supabase setup
- [ ] Authentication
- [ ] Data sync
- [ ] Conflict resolution
- **Milestone:** Cloud sync

### Week 11-12: Admin Dashboard
- [ ] Next.js setup
- [ ] Dashboard UI
- [ ] Reports & analytics
- [ ] Data tables & charts
- **Milestone:** Full system

### Week 13-14: Testing & Polish
- [ ] Classroom testing (30+ students)
- [ ] Bug fixes
- [ ] UI/UX polish
- [ ] Performance optimization
- **Milestone:** Production-ready

### Week 15: Documentation
- [ ] User manual
- [ ] Technical docs
- [ ] Defense slides
- [ ] Demo video
- **Milestone:** Ready for defense

---

## Key Implementation Notes

### UDP Broadcast (Android)

```dart
// lib/data/services/udp_service.dart
import 'dart:io';
import 'dart:convert';

class UdpService {
  RawDatagramSocket? _socket;
  bool _isListening = false;
  
  Future<void> startListening(Function(Map<String, dynamic>) onSessionReceived) async {
    if (_isListening) return;
    
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5501);
    _isListening = true;
    
    _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = _socket!.receive();
        if (dg != null) {
          try {
            String message = utf8.decode(dg.data);
            Map<String, dynamic> sessionData = jsonDecode(message);
            onSessionReceived(sessionData);
          } catch (e) {
            print('Error parsing UDP packet: $e');
          }
        }
      }
    });
  }
  
  Future<void> startBroadcasting(Map<String, dynamic> sessionData) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    
    String message = jsonEncode(sessionData);
    List<int> data = utf8.encode(message);
    
    // Broadcast every 2 seconds
    Timer.periodic(Duration(seconds: 2), (timer) {
      _socket!.send(data, InternetAddress('255.255.255.255'), 5501);
    });
  }
  
  void dispose() {
    _socket?.close();
    _isListening = false;
  }
}
```

### HTTP Server (Lecturer)

```dart
// lib/data/services/http_server_service.dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'dart:convert';

class HttpServerService {
  HttpServer? _server;
  
  Future<void> startServer(Function(Map<String, dynamic>) onAttendanceReceived) async {
    var handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler((request) async {
          if (request.method == 'POST' && request.url.path == 'attendance') {
            String body = await request.readAsString();
            Map<String, dynamic> data = jsonDecode(body);
            
            // Validate room code
            // Validate session not expired
            // Store attendance
            onAttendanceReceived(data);
            
            return Response.ok(jsonEncode({'status': 'recorded'}));
          }
          return Response.notFound('Not found');
        });
    
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 5500);
    print('Server running on port 5500');
  }
  
  void stopServer() {
    _server?.close();
  }
}
```

### Device Fingerprint

```dart
// lib/core/utils/device_fingerprint.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

Future<String> getDeviceFingerprint(String studentId) async {
  final deviceInfo = DeviceInfoPlugin();
  String identifier;
  
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    identifier = '${androidInfo.id}-${androidInfo.device}';
  } else {
    final iosInfo = await deviceInfo.iosInfo;
    identifier = iosInfo.identifierForVendor ?? 'unknown';
  }
  
  // Combine with student ID and hash
  String combined = '$identifier-$studentId';
  return sha256.convert(utf8.encode(combined)).toString();
}
```

### Room Code Generator

```dart
// lib/core/utils/room_code_generator.dart
import 'dart:math';

String generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
}
```

---

## Testing Strategy

### Unit Tests
- [ ] Room code generation
- [ ] Device fingerprinting
- [ ] Session model parsing
- [ ] Time window logic
- [ ] Validators

### Integration Tests
- [ ] UDP broadcast/receive
- [ ] HTTP server/client
- [ ] Database operations
- [ ] Biometric flow

### Real Device Tests
- [ ] Test on campus WiFi
- [ ] Test with 2+ devices
- [ ] Test Android + iOS
- [ ] Battery profiling
- [ ] Network failure scenarios

### Classroom Pilot
- [ ] 30+ students
- [ ] Multiple sessions
- [ ] Edge cases
- [ ] Performance metrics

---

## Critical Success Factors

1. ✅ **UDP works on campus WiFi** - Test Week 3, Day 1
2. ✅ **Android foreground service survives 30 min**
3. ✅ **Biometric auth smooth UX**
4. ✅ **Real-time dashboard responsive (100+ students)**
5. ✅ **Offline-first reliable sync**

---

## Deployment

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
flutter build ios --release
# Then open in Xcode for signing and upload to TestFlight
```

### Backend (Supabase)
- Already hosted (cloud)
- No deployment needed
- Just configuration

### Admin Dashboard (Vercel)
```bash
cd admin
npm run build
vercel --prod
```

---

## Support & Resources

### Documentation
- Flutter: https://docs.flutter.dev
- Riverpod: https://riverpod.dev
- drift: https://drift.simonbinder.eu
- shelf: https://pub.dev/packages/shelf
- Supabase: https://supabase.com/docs

### Community
- Flutter Discord
- Stack Overflow (flutter tag)
- GitHub Issues

---

## Contact

**Developer:** yaan kbg  
**Institution:** International University of East Africa (IUEA)  
**Location:** Kyaliwajala, Kampala, Uganda  
**Email:** yankbg2@gmail.com  
**GitHub:** github.com/yankbg

---

## Version History

- v1.0 (Initial): NISAMS concept with BLE
- v2.0 (Pivot): UDP broadcast architecture
- v3.0 (Final): OROmark branding, UDP confirmed, ready for development

---

**Last Updated:** May 21, 2026  
**Status:** 🚀 Ready for Claude Code development
