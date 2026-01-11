-- ============================================
-- LTMS Row Level Security (RLS) Policies
-- ============================================
-- This script sets up security policies to ensure users can only access authorized data
-- Run this AFTER running supabase_schema.sql

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTION: Get Current User's Role
-- ============================================
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT role 
        FROM users 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ORGANIZATIONS POLICIES
-- ============================================
-- Admins can view their organization
CREATE POLICY "Admins can view their organization"
    ON organizations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.organization_id = organizations.id
            AND users.role = 'admin'
        )
    );

-- Admins can update their organization
CREATE POLICY "Admins can update their organization"
    ON organizations FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.organization_id = organizations.id
            AND users.role = 'admin'
        )
    );

-- ============================================
-- USERS POLICIES
-- ============================================
-- Users can view their own profile
CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    USING (id = auth.uid());

-- Admins can view all users in their organization
CREATE POLICY "Admins can view all users in organization"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = auth.uid()
            AND u.role = 'admin'
            AND u.organization_id = users.organization_id
        )
    );

-- Educators can view learners in their courses
CREATE POLICY "Educators can view learners in their courses"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = auth.uid()
            AND u.role = 'educator'
        )
        AND
        EXISTS (
            SELECT 1 FROM enrollments e
            JOIN course_assignments ca ON ca.course_id = e.course_id
            WHERE ca.educator_id = auth.uid()
            AND e.user_id = users.id
        )
    );

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

-- Admins can update users in their organization
CREATE POLICY "Admins can update users in organization"
    ON users FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = auth.uid()
            AND u.role = 'admin'
            AND u.organization_id = users.organization_id
        )
    );

-- Admins can insert users in their organization
CREATE POLICY "Admins can insert users"
    ON users FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = auth.uid()
            AND u.role = 'admin'
            AND u.organization_id = users.organization_id
        )
    );

-- Allow user creation during signup (handled by auth.users trigger)
CREATE POLICY "Allow user creation during signup"
    ON users FOR INSERT
    WITH CHECK (id = auth.uid());

-- ============================================
-- COURSES POLICIES
-- ============================================
-- Everyone can view published courses in their organization
CREATE POLICY "Users can view published courses"
    ON courses FOR SELECT
    USING (
        is_published = true
        AND EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.organization_id = courses.organization_id
        )
    );

-- Admins can view all courses in their organization
CREATE POLICY "Admins can view all courses"
    ON courses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
            AND users.organization_id = courses.organization_id
        )
    );

-- Educators can view courses assigned to them
CREATE POLICY "Educators can view assigned courses"
    ON courses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM course_assignments
            WHERE course_assignments.course_id = courses.id
            AND course_assignments.educator_id = auth.uid()
        )
    );

-- Admins can create courses
CREATE POLICY "Admins can create courses"
    ON courses FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
            AND users.organization_id = courses.organization_id
        )
    );

-- Admins can update courses in their organization
CREATE POLICY "Admins can update courses"
    ON courses FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
            AND users.organization_id = courses.organization_id
        )
    );

-- Educators can update courses assigned to them
CREATE POLICY "Educators can update assigned courses"
    ON courses FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM course_assignments
            WHERE course_assignments.course_id = courses.id
            AND course_assignments.educator_id = auth.uid()
        )
    );

-- Admins can delete courses
CREATE POLICY "Admins can delete courses"
    ON courses FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
            AND users.organization_id = courses.organization_id
        )
    );

-- ============================================
-- COURSE MODULES POLICIES
-- ============================================
-- Users can view modules of courses they can access
CREATE POLICY "Users can view course modules"
    ON course_modules FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_modules.course_id
            AND (
                courses.is_published = true
                OR EXISTS (
                    SELECT 1 FROM users
                    WHERE users.id = auth.uid()
                    AND (users.role = 'admin' OR users.role = 'educator')
                )
            )
        )
    );

-- Admins and educators can create/update/delete modules
CREATE POLICY "Admins and educators can manage modules"
    ON course_modules FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (users.role = 'admin' OR users.role = 'educator')
        )
    );

-- ============================================
-- LESSONS POLICIES
-- ============================================
-- Users can view lessons of accessible courses
CREATE POLICY "Users can view lessons"
    ON lessons FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM course_modules cm
            JOIN courses c ON c.id = cm.course_id
            WHERE cm.id = lessons.module_id
            AND (
                c.is_published = true
                OR EXISTS (
                    SELECT 1 FROM users
                    WHERE users.id = auth.uid()
                    AND (users.role = 'admin' OR users.role = 'educator')
                )
            )
        )
    );

-- Admins and educators can manage lessons
CREATE POLICY "Admins and educators can manage lessons"
    ON lessons FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (users.role = 'admin' OR users.role = 'educator')
        )
    );

-- ============================================
-- ENROLLMENTS POLICIES
-- ============================================
-- Users can view their own enrollments
CREATE POLICY "Users can view their enrollments"
    ON enrollments FOR SELECT
    USING (user_id = auth.uid());

-- Admins can view all enrollments in their organization
CREATE POLICY "Admins can view all enrollments"
    ON enrollments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users u
            JOIN courses c ON c.id = enrollments.course_id
            WHERE u.id = auth.uid()
            AND u.role = 'admin'
            AND u.organization_id = c.organization_id
        )
    );

-- Educators can view enrollments for their courses
CREATE POLICY "Educators can view course enrollments"
    ON enrollments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM course_assignments
            WHERE course_assignments.course_id = enrollments.course_id
            AND course_assignments.educator_id = auth.uid()
        )
    );

-- Users can enroll themselves
CREATE POLICY "Users can enroll in courses"
    ON enrollments FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Admins can create enrollments
CREATE POLICY "Admins can create enrollments"
    ON enrollments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users u
            JOIN courses c ON c.id = enrollments.course_id
            WHERE u.id = auth.uid()
            AND u.role = 'admin'
            AND u.organization_id = c.organization_id
        )
    );

-- Users can update their own enrollment progress
CREATE POLICY "Users can update their enrollment"
    ON enrollments FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================
-- LESSON PROGRESS POLICIES
-- ============================================
-- Users can view and update their own progress
CREATE POLICY "Users can manage their lesson progress"
    ON lesson_progress FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM enrollments
            WHERE enrollments.id = lesson_progress.enrollment_id
            AND enrollments.user_id = auth.uid()
        )
    );

-- Educators can view progress for their courses
CREATE POLICY "Educators can view lesson progress"
    ON lesson_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM enrollments e
            JOIN course_assignments ca ON ca.course_id = e.course_id
            WHERE e.id = lesson_progress.enrollment_id
            AND ca.educator_id = auth.uid()
        )
    );

-- ============================================
-- COURSE ASSIGNMENTS POLICIES
-- ============================================
-- Admins can manage course assignments
CREATE POLICY "Admins can manage course assignments"
    ON course_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Educators can view their assignments
CREATE POLICY "Educators can view their assignments"
    ON course_assignments FOR SELECT
    USING (educator_id = auth.uid());

-- ============================================
-- NOTIFICATIONS POLICIES
-- ============================================
-- Users can view their own notifications
CREATE POLICY "Users can view their notifications"
    ON notifications FOR SELECT
    USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their notifications"
    ON notifications FOR UPDATE
    USING (user_id = auth.uid());

-- Admins can create notifications for users in their organization
CREATE POLICY "Admins can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users u1
            JOIN users u2 ON u2.id = notifications.user_id
            WHERE u1.id = auth.uid()
            AND u1.role = 'admin'
            AND u1.organization_id = u2.organization_id
        )
    );

-- ============================================
-- ASSESSMENTS POLICIES (Similar to courses)
-- ============================================
CREATE POLICY "Users can view assessments for accessible courses"
    ON assessments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses c
            WHERE c.id = assessments.course_id
            AND (
                c.is_published = true
                OR EXISTS (
                    SELECT 1 FROM users
                    WHERE users.id = auth.uid()
                    AND (users.role = 'admin' OR users.role = 'educator')
                )
            )
        )
    );

CREATE POLICY "Admins and educators can manage assessments"
    ON assessments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (users.role = 'admin' OR users.role = 'educator')
        )
    );

-- ============================================
-- ASSESSMENT QUESTIONS POLICIES
-- ============================================
CREATE POLICY "Users can view assessment questions"
    ON assessment_questions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM assessments a
            JOIN courses c ON c.id = a.course_id
            WHERE a.id = assessment_questions.assessment_id
            AND (
                c.is_published = true
                OR EXISTS (
                    SELECT 1 FROM users
                    WHERE users.id = auth.uid()
                    AND (users.role = 'admin' OR users.role = 'educator')
                )
            )
        )
    );

CREATE POLICY "Admins and educators can manage questions"
    ON assessment_questions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (users.role = 'admin' OR users.role = 'educator')
        )
    );

-- ============================================
-- ASSESSMENT SUBMISSIONS POLICIES
-- ============================================
CREATE POLICY "Users can view their own submissions"
    ON assessment_submissions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Educators can view submissions for their courses"
    ON assessment_submissions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM assessments a
            JOIN course_assignments ca ON ca.course_id = a.course_id
            WHERE a.id = assessment_submissions.assessment_id
            AND ca.educator_id = auth.uid()
        )
    );

CREATE POLICY "Users can create their own submissions"
    ON assessment_submissions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Educators can grade submissions"
    ON assessment_submissions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM assessments a
            JOIN course_assignments ca ON ca.course_id = a.course_id
            WHERE a.id = assessment_submissions.assessment_id
            AND ca.educator_id = auth.uid()
        )
    );

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '🔒 RLS Policies Created Successfully!';
    RAISE NOTICE '✅ All tables now have Row Level Security enabled';
    RAISE NOTICE '✅ Role-based access policies configured';
    RAISE NOTICE '';
    RAISE NOTICE 'Security Summary:';
    RAISE NOTICE '- Admins: Full access to their organization';
    RAISE NOTICE '- Educators: Access to assigned courses and enrolled learners';
    RAISE NOTICE '- Learners: Access to enrolled courses and own progress';
    RAISE NOTICE '';
    RAISE NOTICE 'Next: Test authentication and create your first admin user!';
END $$;
