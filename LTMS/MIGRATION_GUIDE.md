# Firebase to Supabase Migration - Setup Guide

## Migration Completed ✅

Your LTMS project has been successfully migrated from Firebase to Supabase. All code has been updated to use Supabase APIs.

## Quick Start

### 1. Configure Supabase Credentials

Open `LTMS/Utilities/SupabaseConfig.swift` and replace the placeholder values with your actual Supabase project credentials:

```swift
struct SupabaseConfig {
    static let url = "https://your-project-ref.supabase.co"
    static let anonKey = "your-anon-key-here"
    // ...
}
```

Get these values from: https://app.supabase.com/project/_/settings/api

### 2. Create Supabase Storage Buckets

In your Supabase project dashboard, create these storage buckets:
- `profile-pictures`
- `course-thumbnails`
- `course-videos`
- `course-pdfs`

### 3. Set Up Database Tables

Run these SQL commands in your Supabase SQL Editor to create the required tables:

```sql
-- Organizations table
CREATE TABLE organizations (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name TEXT NOT NULL,
  "organizationDescription" TEXT,
  "logoURL" TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT now(),
  "updatedAt" TIMESTAMPTZ DEFAULT now(),
  "isActive" BOOLEAN DEFAULT true
);

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  "organizationId" TEXT REFERENCES organizations(id),
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'educator', 'learner')),
  "firstName" TEXT NOT NULL,
  "lastName" TEXT NOT NULL,
  "profilePictureURL" TEXT,
  "isActive" BOOLEAN DEFAULT true,
  "createdAt" TIMESTAMPTZ DEFAULT now(),
  "updatedAt" TIMESTAMPTZ DEFAULT now(),
  "lastLogin" TIMESTAMPTZ
);

-- Courses table
CREATE TABLE courses (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "organizationId" TEXT REFERENCES organizations(id),
  title TEXT NOT NULL,
  "courseDescription" TEXT,
  level TEXT CHECK (level IN ('beginner', 'intermediate', 'advanced')),
  "durationHours" INTEGER,
  "thumbnailURL" TEXT,
  "isPublished" BOOLEAN DEFAULT false,
  "createdById" TEXT REFERENCES users(id),
  "assignedEducatorId" TEXT REFERENCES users(id),
  "createdAt" TIMESTAMPTZ DEFAULT now(),
  "updatedAt" TIMESTAMPTZ DEFAULT now()
);

-- Modules table
CREATE TABLE modules (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "courseId" TEXT REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  "moduleDescription" TEXT,
  "orderIndex" INTEGER NOT NULL,
  "createdAt" TIMESTAMPTZ DEFAULT now(),
  "updatedAt" TIMESTAMPTZ DEFAULT now()
);

-- Lessons table
CREATE TABLE lessons (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "moduleId" TEXT REFERENCES modules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  "lessonDescription" TEXT,
  "orderIndex" INTEGER NOT NULL,
  "learningObjectives" TEXT,
  prerequisites TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT now(),
  "updatedAt" TIMESTAMPTZ DEFAULT now()
);

-- Contents table
CREATE TABLE contents (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "lessonId" TEXT REFERENCES lessons(id) ON DELETE CASCADE,
  "contentType" TEXT CHECK ("contentType" IN ('video', 'pdf', 'slide', 'text')),
  title TEXT NOT NULL,
  "fileURL" TEXT,
  "textContent" TEXT,
  metadata TEXT,
  version INTEGER DEFAULT 1,
  "createdAt" TIMESTAMPTZ DEFAULT now(),
  "updatedAt" TIMESTAMPTZ DEFAULT now()
);

-- Enrollments table
CREATE TABLE enrollments (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "learnerId" TEXT REFERENCES users(id),
  "courseId" TEXT REFERENCES courses(id),
  "enrollmentDate" TIMESTAMPTZ DEFAULT now(),
  "completionPercentage" DOUBLE PRECISION DEFAULT 0,
  status TEXT CHECK (status IN ('active', 'completed', 'dropped')),
  "lastAccessed" TIMESTAMPTZ
);

-- Progress table
CREATE TABLE progress (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "enrollmentId" TEXT REFERENCES enrollments(id) ON DELETE CASCADE,
  "lessonId" TEXT REFERENCES lessons(id),
  "isCompleted" BOOLEAN DEFAULT false,
  "timeSpentSeconds" INTEGER DEFAULT 0,
  "lastPosition" TEXT,
  "completedAt" TIMESTAMPTZ,
  "updatedAt" TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for common queries
CREATE INDEX idx_users_organization ON users("organizationId");
CREATE INDEX idx_courses_organization ON courses("organizationId");
CREATE INDEX idx_courses_educator ON courses("assignedEducatorId");
CREATE INDEX idx_modules_course ON modules("courseId");
CREATE INDEX idx_lessons_module ON lessons("moduleId");
CREATE INDEX idx_contents_lesson ON contents("lessonId");
CREATE INDEX idx_enrollments_learner ON enrollments("learnerId");
CREATE INDEX idx_enrollments_course ON enrollments("courseId");
CREATE INDEX idx_progress_enrollment ON progress("enrollmentId");
```

### 4. Build the Project in Xcode

1. **Open the project:**
   ```bash
   open LTMS.xcodeproj
   ```

2. **Wait for packages to resolve:**
   - Xcode will automatically download and resolve the `supabase-swift` package
   - Watch the status bar for "Resolving Package Graph" to complete

3. **If prompted "Update to recommended settings":**
   - Click "Perform Changes" to accept

4. **Clean and build:**
   - Press `⌘ + Shift + K` (Product → Clean Build Folder)
   - Press `⌘ + B` (Product → Build)

### 5. If "No such module 'Supabase'" persists:

Try these steps in order:

**Option A: In Xcode**
1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions
3. Clean Build Folder (⌘ + Shift + K)
4. Build (⌘ + B)

**Option B: Manual package resolution**
1. Close Xcode
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/LTMS-*
   ```
3. Reopen Xcode and build

**Option C: Re-add the package**
1. In Xcode, select the LTMS project in the navigator
2. Select the LTMS target → General tab
3. Scroll to "Frameworks, Libraries, and Embedded Content"
4. Click the "+" button
5. Click "Add Other" → "Add Package Dependency"
6. Enter: `https://github.com/supabase-community/supabase-swift`
7. Select version: "Up to Next Major Version" with minimum 1.0.0
8. Click "Add Package"

## What Changed

### Removed:
- ✅ Firebase SDK dependencies (FirebaseAuth, FirebaseFirestore, FirebaseStorage)
- ✅ `GoogleService-Info.plist`
- ✅ `FirebaseService.swift` (replaced with deprecation stub)
- ✅ All `import Firebase*` statements
- ✅ `@DocumentID` property wrappers from models

### Added:
- ✅ `supabase-swift` package dependency
- ✅ `SupabaseService.swift` - Generic CRUD service
- ✅ `SupabaseConfig.swift` - Configuration constants
- ✅ ISO8601 date extension for API compatibility

### Updated:
- ✅ All model files (removed `@DocumentID`, using standard `id: String`)
- ✅ `AuthService.swift` - Using Supabase Auth
- ✅ `ContentService.swift` - Using Supabase Storage
- ✅ `CourseService.swift` - Using Supabase queries
- ✅ `UserManagementView.swift` - Updated to SupabaseService
- ✅ `CreateUserView.swift` - Using Supabase auth signup
- ✅ `CourseManagementView.swift` - Updated database calls
- ✅ `LTMSApp.swift` - Initialize Supabase instead of Firebase

## Testing

The mock data system (`MockDataService`) is still in place for testing with `@test.com` or `@ltms.test` email addresses. This allows development without a live Supabase instance.

## Row Level Security (RLS)

Remember to set up Row Level Security policies in Supabase for multi-tenancy:

```sql
-- Example: Users can only see users in their organization
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view same org users"
  ON users FOR SELECT
  USING (auth.uid() IN (
    SELECT id FROM users WHERE "organizationId" = users."organizationId"
  ));
```

## Need Help?

- Supabase Docs: https://supabase.com/docs
- Supabase Swift Client: https://github.com/supabase-community/supabase-swift
- LTMS SupabaseConfig: `LTMS/Utilities/SupabaseConfig.swift`
