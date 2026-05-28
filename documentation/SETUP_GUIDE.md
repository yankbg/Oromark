# How to Start OROmark Development with Claude Code

## Step 1: Download the Project Brief

1. **Save PROJECT_BRIEF.md from this conversation:**
   - Right-click on the file link above
   - Save as: `PROJECT_BRIEF.md`
   - Or copy all text and save manually

## Step 2: Set Up Flutter Project

```bash
# Navigate to your projects folder
cd ~/projects  # or wherever you keep projects

# Create Flutter project
flutter create oromark_mobile
cd oromark_mobile

# Copy PROJECT_BRIEF.md into project root
# (Place the downloaded file here)

# Test run to ensure setup works
flutter run
```

## Step 3: Add Project Dependencies

Edit `pubspec.yaml` and add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Local Database
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.0
  
  # HTTP Server & Client
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  http: ^1.1.0
  
  # Networking
  # (UDP is built-in with dart:io)
  multicast_dns: ^0.3.2  # For iOS mDNS
  
  # Biometric Auth
  local_auth: ^2.1.7
  
  # Device Info
  device_info_plus: ^9.1.0
  
  # Crypto
  crypto: ^3.0.3
  
  # UUID Generation
  uuid: ^4.0.0
  
  # Backend
  supabase_flutter: ^2.0.0
  
  # Permissions
  permission_handler: ^11.0.1
  
  # Foreground Service (Android)
  flutter_foreground_task: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  
  # Code Generation for drift
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

Then run:
```bash
flutter pub get
```

## Step 4: Create Initial Project Structure

```bash
# Create folders
mkdir -p lib/core/{constants,theme,utils,errors}
mkdir -p lib/data/{models,repositories,services,database}
mkdir -p lib/domain/{entities,usecases}
mkdir -p lib/presentation/{student,lecturer}
mkdir -p lib/presentation/student/{home,history,profile}
mkdir -p lib/presentation/lecturer/{courses,session,reports}
mkdir -p lib/providers

# Create placeholder files
touch lib/core/theme/app_theme.dart
touch lib/core/theme/app_colors.dart
touch lib/data/services/udp_service.dart
touch lib/data/services/http_server_service.dart
```

## Step 5: Open in Claude Code

```bash
# Make sure you're in the project directory
cd ~/projects/oromark_mobile

# Start Claude Code
claude-code

# Claude Code will automatically:
# 1. Read PROJECT_BRIEF.md
# 2. Understand the full context
# 3. Be ready to help you code
```

## Step 6: First Prompt for Claude Code

Once Claude Code opens, start with:

```
I'm ready to start building OROmark. Let's begin with the core theme and color system. 

Please create:
1. lib/core/theme/app_colors.dart - with all brand colors from PROJECT_BRIEF.md
2. lib/core/theme/app_theme.dart - complete theme configuration
3. Update lib/main.dart - basic app structure with theme

Make sure to use the exact hex colors specified in the brief:
- Primary (Teal): #0F6E56
- Secondary (Amber): #BA7517
- etc.
```

## Step 7: Development Workflow

**For each feature, tell Claude Code:**

```
Now let's implement [feature name].

Requirements from PROJECT_BRIEF.md:
- [Requirement 1]
- [Requirement 2]

Please create:
1. [File 1]
2. [File 2]

Make sure it follows the architecture in PROJECT_BRIEF.md.
```

**Example for UDP Service:**

```
Let's implement the UDP broadcast service for session detection.

From PROJECT_BRIEF.md, the UDP service should:
- Listen on port 5501 for broadcasts
- Parse JSON session data
- Broadcast session data every 2 seconds (lecturer side)
- Handle errors gracefully

Please create lib/data/services/udp_service.dart with both listener and broadcaster functionality.
```

## Step 8: Design Integration

If you have designs from Stitch/Figma:

```
I have design mockups from [tool name]. Here are the key screens:
- [Upload or describe design]

Please create the UI matching this design using the color system from PROJECT_BRIEF.md.

Start with the Student Home Screen (lib/presentation/student/home/student_home_screen.dart).
```

## Step 9: Testing As You Go

```
Now let's test the UDP service we just created.

Please create a simple test app that:
1. Has two buttons: "Start Broadcasting" and "Start Listening"
2. Shows received messages
3. Helps me verify UDP works on my WiFi

This is critical - Week 3 milestone from PROJECT_BRIEF.md.
```

## Step 10: When You Get Stuck

Claude Code has full context from PROJECT_BRIEF.md, so you can ask:

```
I'm getting an error: [error message]

According to the architecture in PROJECT_BRIEF.md, how should I fix this?
```

Or:

```
Remind me: what are the 5 security layers from PROJECT_BRIEF.md?
How do I implement Layer 4 (biometric auth)?
```

---

## Alternative: If Claude Code Not Available

You can use this brief with:

### VS Code + GitHub Copilot
1. Open project in VS Code
2. Keep PROJECT_BRIEF.md open in a tab
3. Reference it in code comments
4. Copilot will use context

### Android Studio
1. Open project in Android Studio
2. Keep PROJECT_BRIEF.md visible
3. Use as reference while coding

### Plain Flutter Development
1. Follow PROJECT_BRIEF.md section by section
2. Use it as your specification document
3. Implement features in order (Weeks 1-15)

---

## Quick Reference Card

**Essential Commands:**

```bash
# Run app
flutter run

# Generate drift code
flutter pub run build_runner build

# Build release APK
flutter build apk --release

# Check for issues
flutter doctor

# View logs
flutter logs
```

**Project Structure:**
```
oromark_mobile/
├── PROJECT_BRIEF.md ← Your complete spec
├── lib/
│   ├── core/ ← Theme, constants, utils
│   ├── data/ ← Services, models, database
│   ├── domain/ ← Business logic
│   ├── presentation/ ← UI screens
│   └── main.dart
└── pubspec.yaml
```

**Key Files to Reference:**
- Colors: PROJECT_BRIEF.md → Design System → Brand Colors
- Architecture: PROJECT_BRIEF.md → Core Architecture
- Features: PROJECT_BRIEF.md → Feature Requirements
- Timeline: PROJECT_BRIEF.md → Development Timeline

---

## Success Checklist

Week 3 (CRITICAL):
- [ ] UDP broadcast works on campus WiFi
- [ ] Can send/receive messages between 2 phones
- [ ] Packet parsing works correctly

Week 6:
- [ ] Biometric auth implemented
- [ ] Foreground service keeps app alive
- [ ] Background detection works

Week 9:
- [ ] Student can detect and confirm session
- [ ] Lecturer can start session and see responses
- [ ] End-to-end flow complete

Week 15:
- [ ] Tested with 30+ students
- [ ] All features working
- [ ] Ready for defense

---

## Getting Help

If something is unclear:

1. **Check PROJECT_BRIEF.md first** - it has everything
2. **Search Flutter docs** - https://docs.flutter.dev
3. **Ask Claude Code** - it has full context
4. **Check package docs** - pub.dev

---

## Important Notes

⚠️ **Critical Milestone Week 3:**
Test UDP on campus WiFi ASAP! If it doesn't work, the architecture needs adjustment.

⚠️ **Save Progress:**
```bash
git init
git add .
git commit -m "Initial setup"
git remote add origin https://github.com/yankbg/oromark.git
git push -u origin main
```

⚠️ **Backup PROJECT_BRIEF.md:**
This file contains ALL decisions. Keep it safe!

---

Ready to build OROmark! 🚀
